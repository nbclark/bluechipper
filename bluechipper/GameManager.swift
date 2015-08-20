//
//  GameManager.swift
//  bluechipper
//
//  Created by Nicholas Clark on 2/8/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation
import MBProgressHUD

typealias BCLocalGamesResultBlock = (Array<Game>, NSError?) -> Void
typealias BCGameResultBlock = (Game?, NSError?) -> Void

@objc protocol GameManagerDelegate : NSObjectProtocol {
    optional func didEnableAdvertising()
    optional func didFindGames(games: Array<Game>)
    optional func didChangeState(state: Int, message: String)
    optional func foundExistingGame(game: Game)
    optional func joinedGame(game: Game)
}

enum GameNotificationActions : String {
    case GameMembersChanged = "gamemembers"
    case GameStateChanged = "gamestate"
}

class GameManager: NSObject, BeaconRangedMonitorDelegate, BeaconMonitorDelegate, UIWebViewDelegate {
    var beaconMonitor : BeaconMonitor
    var gameId : String?
    var webView : UIWebView?
    var game : Game!
    var isProcessing : Bool
    var joinGames : Array<Game>
    var delegates : NSMutableArray = NSMutableArray()
    var _hud : MBProgressHUD! = nil
    
    var isOwner : Bool {
        get {
            return nil != self.game ? self.game.owner == PFUser.currentUser()?.objectId : false
        }
    }
    
    var hud : MBProgressHUD {
        get {
            if (nil == self._hud) {
                let window = UIApplication.sharedApplication().keyWindow!
                self._hud = MBProgressHUD(window: window)
                self._hud.opacity = 0.25
                self._hud.animationType = MBProgressHUDAnimation.ZoomIn
                window.addSubview(self._hud)
            }
            return self._hud;
        }
    }
    
    // GAME STATE CHANGES
    // Stakes changes (before and during)
    // Player changes (before and durring) (add / delete / pause)
    // Player order changes (before and during) (randomization should happen somehwere)
    // Player rebuys?
    // Owner changed?
    //
    // HAND STATE CHANGES
    // Hand started
    // Player acted (followed by player to act)
    // Round started / ended
    // Stacks changed
    // Player busted
    
    override init() {
        self.beaconMonitor = BeaconMonitor()
        
        // TODO - remove this and let gamemanager centralize ranged users
        Settings.beaconMonitor = self.beaconMonitor
        self.isProcessing = false
        self.joinGames = Array<Game>()
        
        super.init()
        
        // Read some settings
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let gid : AnyObject? = userDefaults.valueForKey("gameid")
        
        if (nil != gid) {
            self.gameId = gid as! String?
        }
        
        self.beaconMonitor.delegate = self
        
        let user = PFUser.currentUser()!
        user.saveInBackgroundWithBlock { (result, error) -> Void in
            let userId = user.objectId!;
            let hashValue = userId.hash & 0x7FFF7FFF
            user.hashvalue = hashValue
            user.name = UIDevice.currentDevice().name
            user.saveInBackgroundWithBlock { (result, error) -> Void in
                self.start()
            }
        }
    }
    
    private func notifyState(state: Int, message: String) {
        for del in self.delegates {
            let gameDel = del as! GameManagerDelegate
            gameDel.didChangeState?(state, message: message)
        }
    }
    
    private func sendPlayerPush(user : PFUser, message: String) {
        var push = PFPush()
        push.setChannel("c" + user.objectId!)
        push.setMessage(message) // the game should be refetched...
        push.sendPushInBackgroundWithBlock(nil)
    }
    
    private func sendGamePush(action : GameNotificationActions) {
        var push = PFPush()
        push.setChannel("c" + self.game.objectId!)
        push.setData([ "action" : action.rawValue ])
        push.sendPushInBackgroundWithBlock(nil)
    }
    
    func addDelegate(delegate: GameManagerDelegate) {
        self.delegates.addObject(delegate)
    }
    
    func removeDelegate(delegate: GameManagerDelegate) {
        self.delegates.removeObject(delegate)
    }
    
    func monitoringAndAdvertisingEnabled() {
        self.notifyState(2, message: "intialized beacons...")
        // Give 2 seconds to range beacons
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
            self.notifyState(3, message: "searching for games...")
            dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
                self.rangedBeacons()
            }
        }
    }
    
    // Start game stracking
    func start() {
        self.notifyState(1, message: "intializing beacons...")
        
        if (nil != self.gameId) {
            // We have an existing game -- try to find it
            self.fetchGame(self.gameId!, block: { (game, error) -> Void in
                if (nil != error) {
                    self.beaconMonitor.addRangeDelegate(self)
                    self.beaconMonitor.start()
                } else {
                    // We found an existing game, let's notify
                    for del in self.delegates {
                        let gameDel = del as! GameManagerDelegate
                        gameDel.foundExistingGame?(game!)
                    }
                }
            })
        } else {
            self.beaconMonitor.addRangeDelegate(self)
            self.beaconMonitor.start()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMembersChanged", name: "gameMembersChangedNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMembersChanged", name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMemberChanged:", name: "gameMemberChangedNotification", object: nil)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.URL!.scheme! == "bc" {
            var id = webView.stringByEvaluatingJavaScriptFromString("table.players[table.actionIndex].id")!
            self.processCommand(request.URL!, id: id)
            return false
        } else {
            self.webView = webView
            return true
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        sleep(0)
    }
    
    func processCommand(url: NSURL, id: String) {
        
        if (url.host == "signalPlayerActionNeeded") {
            var obj : NSDictionary = NSJSONSerialization.JSONObjectWithData(url.lastPathComponent!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: nil, error: nil) as! NSDictionary
            
            var userId = url.pathComponents![1] as! String
            
            // List of menu options (check, fold, raise, call), with their corresponding values
            if (userId == PFUser.currentUser()?.objectId!) {
                var sheet = BTActionSheet(title: "Join Existing Game", cancelButtonTitle: nil, destructiveButtonTitle: nil)
                
                for (key, value) in obj {
                    sheet.addButtonWithTitle(key as! String, handler : { () -> Void in
                        self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.menu.menuOptionCallback('%@')", key as! String))
                        return
                    })
                }
                
                sheet.showInView(UIApplication.sharedApplication().keyWindow!)
            } else {
                // TODO - show some waiting UI
                // Wait for notification from Parse
                // self.webView?.stringByEvaluatingJavaScriptFromString("table.menu.menuOptionCallback('fold')")
                self.hud.mode = MBProgressHUDMode.DeterminateHorizontalBar
                self.hud.progress = 0.5
                self.hud.labelText = "Waiting on player"
                self.hud.show(true)
            }
        } else if (url.host == "signalHandStateChanged") {
            var state = url.pathComponents![1] as! String
            if (state == "end") {
                //
            } else if (state == "start") {
                self.hud.mode = MBProgressHUDMode.Text
                self.hud.labelText = "Starting hand..."
                self.hud.showAnimated(true, whileExecutingBlock: { () -> Void in
                    sleep(5)
                }, completionBlock: { () -> Void in
                    self.webView?.stringByEvaluatingJavaScriptFromString("bridge.handStateChangedCallback()")
                })
            } else {
                self.hud.mode = MBProgressHUDMode.Text
                self.hud.labelText = String(format: "Ready for the %@", state)
                self.hud.showAnimated(true, whileExecutingBlock: { () -> Void in
                    sleep(5)
                    }, completionBlock: { () -> Void in
                        self.webView?.stringByEvaluatingJavaScriptFromString("bridge.handStateChangedCallback()")
                })
            }
        } else if (url.host == "signalHandResultNeeded") {
            sleep(0)
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        webView.stringByEvaluatingJavaScriptFromString("bridge.signalPlayerActionNeeded = function(actionStates, playerid) { document.location = 'bc://signalPlayerActionNeeded/' + playerid + '/' + JSON.stringify(actionStates) }")
        
        webView.stringByEvaluatingJavaScriptFromString("bridge.signalHandStateChanged = function(state, winners) { document.location = 'bc://signalHandStateChanged/' + state + '/' + JSON.stringify(winners) }")
        
        webView.stringByEvaluatingJavaScriptFromString("bridge.signalHandResultNeeded = function(pots) { document.location = 'bc://signalHandResultNeeded/' + JSON.stringify(pots) }")
    }
    
    func addPlayer(player : PFUser, block : PFBooleanResultBlock?) {
        let user = player
        
        self.game.activeusers.append(user)
        self.game.users.remove(user)
        
        self.sendPlayerPush(user, message: "Welcome to the game")

        Settings.gameManager?.game?.saveInBackgroundWithBlock({ (res, err) -> Void in
            self.sendGamePush(GameNotificationActions.GameMembersChanged)
            block?(res, err)
        })
    }
    
    func removePlayer(player : PFUser, block : PFBooleanResultBlock?) {
        let user = player
        
        self.game.activeusers.remove(user)
        
        self.sendPlayerPush(user, message: "Sorry to see you go")
        
        Settings.gameManager?.game?.saveInBackgroundWithBlock({ (res, err) -> Void in
            self.sendGamePush(GameNotificationActions.GameMembersChanged)
            block?(res, err)
        })
    }
    
    func loadState() {
        if (!self.isOwner) {
            assert(!self.isOwner, "startGame should only be called by non-game owners")
            // TODO
            self.fetchGame(self.gameId!, block: { (game, error) -> Void in
                // TODO
                self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.loadState('%@')", game!.gameState!))
                return
            })
        }
    }
    
    func startGame() {
        assert(self.isOwner, "startGame should only be called by game owner")
        
        if (true || !self.game.isActive) {
            for user in self.game.activeusers {
                var name = user.name!.stringByReplacingOccurrencesOfString("'", withString: "_")
                self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.addPlayer('%@', '%@', %d)", user.objectId!, name, 100))
                self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.addPlayer('%@', '%@', %d)", user.objectId!, name, 100))
                self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.addPlayer('%@', '%@', %d)", user.objectId!, name, 100))
                self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.addPlayer('%@', '%@', %d)", user.objectId!, name, 100))
            }
            
            self.webView?.stringByEvaluatingJavaScriptFromString("table.randomizePlayers()")
            self.webView?.stringByEvaluatingJavaScriptFromString("table.layoutPlayers()")
            self.webView?.stringByEvaluatingJavaScriptFromString("table.startGame()")
            
            self.game.isActive = true
            
            // Fetch the serialized state
            let state = self.webView?.stringByEvaluatingJavaScriptFromString("table.getState()")
            
            // Save off the state and notify
            self.game.gameState = state
            self.game.saveInBackgroundWithBlock { (res, err) -> Void in
                // Communicate out that our game state has changed
                // The clients should take the notice and call loadState on their clients
                // TODO
                self.sendGamePush(GameNotificationActions.GameStateChanged)
            }
        } else {
            // TODO
            // We really need to figure out how to handle new player additions / removals
        }
    }
    
    func gameMembersChanged() {
        if (self.game != nil) {
            self.reload()
        }
    }
    
    func rangedBeacons() {
        // We have new users around us...
        if (nil == self.game) {
            self.processRange()
        }
    }
    
    func gameMemberChanged(notification: NSNotification) {
        let user = notification.object as! PFUser
        
        // we have an updated user here - replace the one in our dictionary
        var index = game.activeusers.indexOf({ (u) -> Bool in user.objectId == u.objectId })
        
        if (nil != index) {
            game.activeusers[index!] = user
        } else {
            index = game.users.indexOf({ (u) -> Bool in user.objectId == u.objectId })
            
            if (nil != index)
            {
                game.users[index!] = user
            }
        }
        
        if (nil != index) {
            NSNotificationCenter.defaultCenter().postNotificationName("gameStateChangedNotification", object: self.game)
        }
    }
    
    func fetchGame(gameId: String, block: BCGameResultBlock?) {
        var query = PFQuery(className: "game")
        query.whereKey("objectId", equalTo: self.gameId!)
        
        query.findObjectsInBackgroundWithBlock { (results, error) -> Void in
            if (nil != error) {
                block?(nil, error)
                return
            }
            
            var game = results!.first as! Game
            var existingUserList = game.users
            var activeUserList = game.activeusers
            
            PFObject.fetchAllIfNeededInBackground(existingUserList.union(activeUserList), block: { (results, error) -> Void in
                if (nil != error) {
                    block?(nil, error)
                    return
                }
                
                block?(game, nil)
            })
        }
    }
    
    func save() {
        self.game.saveInBackgroundWithBlock { (res, error) -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("gameStateChangedNotification", object: self.game)
        }
    }
    
    func reload() {
        self.fetchGame(self.gameId!, block: { (game, error) -> Void in
            if (nil == self.game) {
                // We just loaded our game for the first time - send a state change perhaps
                self.processGame(game!)
            } else {
                // We just reloaded
                self.game = game
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName("gameStateChangedNotification", object: self.game)
        })
    }
    
    func processRange() {
        if (self.isProcessing) {
            return
        }
        
        self.isProcessing = true
        
        // At this point, we know the games...
        // We should prompt to join, or to create a new game
        self.joinExistingGame()
    }
    
    func createGame() {
        var game = PFObject(className: "game", dictionary: ["name" : UIDevice.currentDevice().name, "users" : [], "activeusers" : [PFUser.currentUser()!], "owner" : PFUser.currentUser()!.objectId!])
        
        game.saveInBackgroundWithBlock({ (res, error) -> Void in
            self.processGame(game as! Game)
        })
    }
    
    func processGame(game : Game) {
        self.game = game
        self.gameId = self.game.objectId
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setValue(self.game.objectId!, forKey: "gameid")
        userDefaults.synchronize()
        
        // Send a push that people should update the game
        PFInstallation.currentInstallation().addUniqueObject("c" + game.objectId!, forKey: "channels")
        PFInstallation.currentInstallation().saveInBackgroundWithBlock({ (res, error) -> Void in
            self.sendGamePush(GameNotificationActions.GameMembersChanged)
        })
        
        for del in self.delegates {
            let gameDel = del as! GameManagerDelegate
            gameDel.joinedGame?(game)
        }
    }
    
    func joinExistingGame() {
        self.notifyState(3, message: String(format: "searching for games (%d)...", self.beaconMonitor.rangedUsers.count))
        
        self.joinGames.removeAll(keepCapacity: true)
        let dict = self.beaconMonitor.rangedUsers
        var existingGameId : String = ""
        var userList : Array<PFUser> = Array()
        var searchUserList : Array<PFUser> = Array()
        
        for (hashValue, user) in dict {
            userList.append(user)
            searchUserList.append(user)
        }
        
        searchUserList.append(PFUser.currentUser()!)
        
        var usersQuery = PFQuery(className: "game")
        var activeUsersQuery = PFQuery(className: "game")
        activeUsersQuery.whereKey("activeusers", containedIn: searchUserList)
        activeUsersQuery.whereKey("disabled", notEqualTo: true)
        usersQuery.whereKey("users", containedIn: searchUserList)
        usersQuery.whereKey("disabled", notEqualTo: true)
        
        var query = PFQuery.orQueryWithSubqueries([usersQuery, activeUsersQuery]);
        
        query.findObjectsInBackgroundWithBlock { (games, error) -> Void in
            var mgames = games
            mgames!.sort({ (a, b) -> Bool in
                let pa = a as! PFObject
                let pb = b as! PFObject
                
                return pa.createdAt!.compare(pb.createdAt!) == NSComparisonResult.OrderedDescending
            })

            // At this point, we know the games...
            // We should prompt to join, or to create a new game
            if (mgames!.count > 0) {
                let game = mgames?.first as! Game
                var activeUserList = game["activeusers"] as! [PFUser]
                var name = game["name"] as! String?
                
                if (nil == name && activeUserList.count > 0) {
                    let owner : PFUser = activeUserList[0]
                    let ava = owner.isDataAvailable()
                    owner.fetch()
                    if (nil != owner.name) {
                        name = String(owner.name!)
                    }
                }
                
                if (nil != name) {
                    self.joinGames.push(game)
                }
            }
            
            self.notifyState(4, message: String(format: "found existing games (%d)...", self.joinGames.count))
            self.isProcessing = false
        }
    }
    
    func joinGameId(gameId : String) {
        let game = self.joinGames.find({ (t) -> Bool in
            if (t.objectId == gameId) {
                return true
            }
            return false
        })
        if (nil != game) {
            self.joinGame(game!)
        }
    }
    
    func exitGame(game : Game) {
        self.gameId = nil
        self.game = nil
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey("gameid")
        userDefaults.synchronize()
        
        var existingUserList = game["users"] as! [PFUser]
        var activeUserList = game["activeusers"] as! [PFUser]
        
        var index = activeUserList.indexOf({ (u) -> Bool in u.objectId == PFUser.currentUser()!.objectId })
        if (index != nil) {
            activeUserList.removeAtIndex(index!)
        }
        
        index = existingUserList.indexOf({ (u) -> Bool in u.objectId == PFUser.currentUser()!.objectId })
        if (index != nil) {
            existingUserList.removeAtIndex(index!)
        }
        
        if (game["owner"] as! String? == PFUser.currentUser()?.objectId!) {
            game["disabled"] = true
        }
        
        game.saveInBackgroundWithBlock { (res, err) -> Void in
            self.sendGamePush(GameNotificationActions.GameMembersChanged)
            self.start()
        }
    }
    
    func joinGame(game : Game) {
        var existingUserList = game["users"] as! [PFUser]
        var activeUserList = game["activeusers"] as! [PFUser]
        
        if (activeUserList.indexOf({ (u) -> Bool in u.objectId == PFUser.currentUser()!.objectId }) == nil) {
            game["users"] = existingUserList.union([PFUser.currentUser()!]).uniqueBy { (u) -> NSString in
                u.objectId!
            }
        }

        PFObject.fetchAllIfNeededInBackground(existingUserList.union(activeUserList), block: { (res, error) -> Void in
            
            game.saveInBackgroundWithBlock({ (res, error) -> Void in
                // Show the players UI
                self.processGame(game)
            })
            
        })
    }
}