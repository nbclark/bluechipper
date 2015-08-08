//
//  GameManager.swift
//  bluechipper
//
//  Created by Nicholas Clark on 2/8/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation

class GameManager: NSObject, BeaconRangedMonitorProtocol, UIWebViewDelegate, UIActionSheetDelegate {
    var beaconMonitor : BeaconMonitor
    var gameId : String?
    var webView : UIWebView?
    var mainVC : UIViewController
    var game : Game!
    var isProcessing : Bool
    var joinGames : Array<Game>
    
    init(beaconMonitor:BeaconMonitor) {
        self.beaconMonitor = beaconMonitor
        self.isProcessing = false
        self.joinGames = Array<Game>()
        self.mainVC = Settings.current!.window!.rootViewController!
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMembersChanged", name: "gameMembersChangedNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMembersChanged", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMemberChanged:", name: "gameMemberChangedNotification", object: nil)
        
        self.beaconMonitor.addRangeDelegate(self)
        
        if (self.beaconMonitor.isUpdating == false) {
            self.processRange()
        }
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.URL!.scheme! == "bc" {
            var id = webView.stringByEvaluatingJavaScriptFromString("table.players[table.actionIndex].id")!
            self.processCommand(request.URL!, id: id)
            return false
        } else {
            self.webView = webView
            // webView.stringByEvaluatingJavaScriptFromString("alert(table)")
            return true
        }
    }
    
    func processCommand(url: NSURL, id: String) {
        var obj : NSDictionary = NSJSONSerialization.JSONObjectWithData(url.lastPathComponent!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: nil, error: nil) as! NSDictionary
        
        // List of menu options (check, fold, raise, call), with their corresponding values
        if (id == PFUser.currentUser()?.objectId!) {
            sleep(0);
            self.webView?.stringByEvaluatingJavaScriptFromString("table.menu.menuOptionCallback('fold')")
        } else {
            // Wait for notification from Parse
            self.webView?.stringByEvaluatingJavaScriptFromString("table.menu.menuOptionCallback('fold')")
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        webView.stringByEvaluatingJavaScriptFromString("table.menu.menuHandler = function(actions) { document.location = 'bc://proceed/' + JSON.stringify(actions) }")
    }
    
    func addPlayer(player : PFUser) {
        //
    }
    
    func removePlayer(player : PFUser) {
        //
    }
    
    func startGame() {
        for user in self.game.activeusers {
            var name = user.name!.stringByReplacingOccurrencesOfString("'", withString: "_")
            self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.addPlayer('%@', '%@', %d)", user.objectId!, name, 100))
        }
        
        self.webView?.stringByEvaluatingJavaScriptFromString("table.addPlayer('1', 'test', 100)")
        self.webView?.stringByEvaluatingJavaScriptFromString("table.randomizePlayers()")
        self.webView?.stringByEvaluatingJavaScriptFromString("table.layoutPlayers()")
        self.webView?.stringByEvaluatingJavaScriptFromString("table.startGame()")
    }
    
    func gameMembersChanged() {
        self.reload()
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
    
    func reload() {
        var query = PFQuery(className: "game")
        query.whereKey("objectId", equalTo: self.game!.objectId!)
        
        query.findObjectsInBackgroundWithBlock { (results, error) -> Void in
            if (nil != error) {
                return
                // TODO
            }
            
            var game = results!.first as! Game
            var existingUserList = game.users
            var activeUserList = game.activeusers
            
            PFObject.fetchAllIfNeededInBackground(existingUserList.union(activeUserList), block: { (res, error) -> Void in
                self.game = game as Game
                NSNotificationCenter.defaultCenter().postNotificationName("gameStateChangedNotification", object: self.game)
            })
        }
    }
    
    func processRange() {
        if (self.isProcessing) {
            return
        }
        
        self.isProcessing = true
        
        // At this point, we know the games...
        // We should prompt to join, or to create a new game
        var sheet = UIActionSheet(title: "Pick your game", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
        sheet.tag = 0
        
        sheet.addButtonWithTitle("Create New Game")
        sheet.addButtonWithTitle("Join Existing Game")
        sheet.cancelButtonIndex = 0
        
        sheet.showInView(self.mainVC.view)
    }
    
    func createGame() {
        var game = PFObject(className: "game", dictionary: ["name" : UIDevice.currentDevice().name, "users" : [], "activeusers" : [PFUser.currentUser()!], "owner" : PFUser.currentUser()!.objectId!])
        
        game.saveInBackgroundWithBlock({ (res, error) -> Void in
            self.processGame(game as! Game)
        })
    }
    
    func processGame(game : Game) {
        self.game = game
        self.mainVC.performSegueWithIdentifier("GameSettingsSegue", sender: self.mainVC)
        
        // Send a push that people should update the game
        PFInstallation.currentInstallation().addUniqueObject("c" + game.objectId!, forKey: "channels")
        PFInstallation.currentInstallation().saveInBackgroundWithBlock({ (res, error) -> Void in
            var push = PFPush()
            push.setChannel("c" + game.objectId!)
            push.setData([ "action" : "gamemembers" ]) // the game should be refetched...
            push.sendPushInBackgroundWithBlock(nil)
        })
    }
    
    func joinExistingGame() {
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
            
//            for (index, element) in enumerate(mgames!) {
//                if (index > 0) {
//                    let po = element as! PFObject
//                    po["disabled"] = true
//                    po.saveInBackgroundWithBlock(nil)
//                }
//            }
            
            // At this point, we know the games...
            // We should prompt to join, or to create a new game
            var sheet = UIActionSheet(title: "Pick your game", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)
            sheet.tag = 1
            
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
                    sheet.addButtonWithTitle(name!)
                    self.joinGames.push(game)
                }
            }
            
            sheet.showInView(self.mainVC.view)
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
    
    func actionSheet(actionSheet: UIActionSheet, willDismissWithButtonIndex buttonIndex: Int) {
        if (actionSheet.tag == 0) {
            // Create / vs join
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                // Hack, but this means create a new game
                self.createGame()
            } else {
                self.joinExistingGame()
            }
        } else if (actionSheet.tag == 1) {
            // Join existing
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                // We are cancelling now
                self.isProcessing = false
                self.processRange()
            } else {
                var game = self.joinGames[buttonIndex-1]
                self.joinGame(game)
                sleep(0)
            }
        }
    }
}