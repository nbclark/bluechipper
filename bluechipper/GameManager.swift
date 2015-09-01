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
typealias BCVoidBlock = () -> Void
typealias BCGameResultBlock = (Game?, NSError?) -> Void
typealias BCWaitEvaluationBlock = (NSString, NSDictionary)->Bool
typealias BCWaitCallbackBlock = (NSString, NSDictionary)->Void

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
    case GameTurnTaken = "turntaken"
}

class GameManager: NSObject, BeaconRangedMonitorDelegate, BeaconMonitorDelegate, UIWebViewDelegate {
    var user : PFUser
    var beaconMonitor : BeaconMonitor
    var gameId : String?
    var webView : UIWebView?
    var game : Game!
    var isProcessing : Bool
    var joinableGames : Array<Game> = Array<Game>()
    var delegates : NSMutableArray = NSMutableArray()
    var waitActionCallbacks : Array<(predicate: BCWaitEvaluationBlock, callback: BCWaitCallbackBlock, persist: Bool)> = []
    var _hud : MBProgressHUD! = nil
    
    var isOwner : Bool {
        get {
            return nil != self.game ? self.game.owner == self.user.objectId : false
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
    
    init(user: PFUser) {
        self.beaconMonitor = BeaconMonitor()
        
        // TODO - remove this and let gamemanager centralize ranged users
        Settings.beaconMonitor = self.beaconMonitor
        self.isProcessing = false
        self.user = user
        
        super.init()
        
        // Read some settings
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let gid : AnyObject? = userDefaults.valueForKey("gameid")
        
        if (nil != gid) {
            self.gameId = gid as! String?
        }
        
        self.beaconMonitor.delegate = self
        
        // Notify of game members changing
        self.registerWaitForAction({ (action, userInfo) -> Bool in
            return action == GameNotificationActions.GameMembersChanged.rawValue
            }, callback: { (action, userInfo) -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("gameMembersChangedNotification", object: nil)
            }, persist: true)
        
        // Notify of game state changing
        self.registerWaitForAction({ (action, userInfo) -> Bool in
            return action == GameNotificationActions.GameStateChanged.rawValue
            }, callback: { (action, userInfo) -> Void in
                self.fetchAndLoadState(nil)
            }, persist: true)
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
    
    // Start game tracking
    func start() {
        self.notifyState(1, message: "intializing beacons...")
        
        // Check for previously loading game
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
    
    internal func signalAction(action: NSString, userInfo : NSDictionary) {
        for (index, callback) in enumerate(waitActionCallbacks) {
            let res : Bool = callback.predicate(action, userInfo)
            if (res) {
                callback.callback(action, userInfo)
                
                if (!callback.persist) {
                    waitActionCallbacks.removeAtIndex(index)
                }
                break;
            }
        }
    }
    
    internal func registerWaitForActionWithHUD(predicate : BCWaitEvaluationBlock, callback : BCWaitCallbackBlock, message : String) {
        self.hud.mode = MBProgressHUDMode.DeterminateHorizontalBar
        self.hud.progress = 0.5
        self.hud.labelText = message
        
        self.registerWaitForAction(predicate, callback: callback, persist: false)
    }
    
    internal func registerWaitForAction(predicate : BCWaitEvaluationBlock, callback : BCWaitCallbackBlock, persist: Bool) {
        waitActionCallbacks.push((predicate: predicate, callback: callback, persist: persist))
    }
    
    internal func rangedBeacons() {
        // We have new users around us...
        if (nil == self.game) {
            self.processRange()
        }
    }
    
    func fetchGame(gameId: String, block: BCGameResultBlock?) {
        var query = PFQuery(className: "game")
        query.whereKey("objectId", equalTo: self.gameId!)
        
        query.findObjectsInBackgroundWithBlock { (results, error) -> Void in
            if (nil != error) {
                block?(nil, error)
                return
            } else if (results?.count != 1) {
                self.game = nil
                block?(nil, NSError(domain: "Not found", code: 0, userInfo: nil))
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
    
    func save(triggeringAction : GameNotificationActions?, block : PFBooleanResultBlock?) {
        // Some state has changed with the game, we should set that here...
        self.game.lastAction = NSUUID().UUIDString
        
        self.game.saveInBackgroundWithBlock { (res, error) -> Void in
            block?(res, error)
            
            if let action = triggeringAction {
                self.sendGamePush(action) 
            }
            
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
        self.searchForExistingGames()
    }
    
    // Create a new game
    func createGame() {
        var game = PFObject(className: "game", dictionary: ["name" : UIDevice.currentDevice().name, "users" : [], "activeusers" : [self.user], "owner" : self.user.objectId!])
        
        game.saveInBackgroundWithBlock({ (res, error) -> Void in
            self.processGame(game as! Game)
        })
    }
    
    // Process the joining of a game
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
    
    func searchForExistingGames() {
        self.notifyState(3, message: String(format: "searching for games (%d)...", self.beaconMonitor.rangedUsers.count))
        
        self.joinableGames.removeAll(keepCapacity: true)
        let dict = self.beaconMonitor.rangedUsers
        var existingGameId : String = ""
        var userList : Array<AnyObject> = Array()
        var searchUserList : Array<AnyObject> = Array()
        
        for (hashValue, user) in dict {
            userList.append(user)
            searchUserList.append(user)
        }
        
        searchUserList.append(self.user)
        
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
                var activeUserList = game.activeusers
                var name = game.name
                
                if (nil == name && activeUserList.count > 0) {
                    let owner : PFUser = activeUserList[0]
                    let ava = owner.isDataAvailable()
                    owner.fetch()
                    if (nil != owner.name) {
                        name = String(owner.name!)
                    }
                }
                
                if (nil != name) {
                    self.joinableGames.push(game)
                }
            }
            
            self.notifyState(4, message: String(format: "found existing games (%d)...", self.joinableGames.count))
            self.isProcessing = false
        }
    }
    
    func joinGameId(gameId : String) {
        let game = self.joinableGames.find({ (t) -> Bool in
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
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey("gameid")
        userDefaults.synchronize()
        
        var existingUserList = game["users"] as! [PFUser]
        var activeUserList = game["activeusers"] as! [PFUser]
        
        var index = activeUserList.indexOf({ (u) -> Bool in u.objectId == self.user.objectId })
        if (index != nil) {
            activeUserList.removeAtIndex(index!)
        }
        
        index = existingUserList.indexOf({ (u) -> Bool in u.objectId == self.user.objectId })
        if (index != nil) {
            existingUserList.removeAtIndex(index!)
        }
        
        if (game["owner"] as! String? == self.user.objectId!) {
            game["disabled"] = true
        }
        
        game.saveInBackgroundWithBlock { (res, err) -> Void in
            // TODO - send a message that the game was deleted
            self.sendGamePush(GameNotificationActions.GameMembersChanged)
            
            self.gameId = nil
            self.game = nil
            
            self.start()
        }
    }
    
    func joinGame(game : Game) {
        var existingUserList = game["users"] as! [PFUser]
        var activeUserList = game["activeusers"] as! [PFUser]
        
        if (activeUserList.indexOf({ (u) -> Bool in u.objectId == self.user.objectId }) == nil) {
            game["users"] = existingUserList.union([self.user]).uniqueBy { (u) -> String in
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