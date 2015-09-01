//
//  GameManager.swift
//  bluechipper
//
//  Created by Nicholas Clark on 2/8/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation
import MBProgressHUD

extension GameManager {
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.URL!.scheme! == "bc" {
            //var id = webView.stringByEvaluatingJavaScriptFromString("table.players[table.actionIndex].id")!
            self.processCommand(request.URL!)
            return false
        } else {
            self.webView = webView
            return true
        }
    }
    
    func gameTurnTaken(userId: String, actionName : AnyObject, value : AnyObject) {
        self.sendGamePush(GameNotificationActions.GameTurnTaken, data : ["userid" : userId, "actionname" : actionName, "actionvalue" : value ])
        self.save(nil, block: nil)
    }
    
    func processCommand(url: NSURL) {
        if (url.host == "signalPlayerActionNeeded") {
            var obj : NSDictionary = NSJSONSerialization.JSONObjectWithData(url.lastPathComponent!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: nil, error: nil) as! NSDictionary
            
            var userId = url.pathComponents![1] as! String
            
            // List of menu options (check, fold, raise, call), with their corresponding values
            if ((userId == PFUser.currentUser()?.objectId!)) {
                var sheet = BCActionSheet(title: "Join Existing Game", cancelButtonTitle: nil, destructiveButtonTitle: nil)
                
                // TODO - for the owner, give an option to pause the game
                // Perhaps tapping on players will pause it too...
                // We should also drop in new players after hands are over
                // Perhaps we pause the player settings while a hand is in progress
                // and bring it back after a hand is over
                for (key, value) in obj {
                    sheet.addButtonWithTitle(key as! String, handler : { () -> Void in
                        self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.menu.menuOptionCallback('%@')", key as! String))
                        self.gameTurnTaken(userId, actionName: key, value: value)
                        return
                    })
                }
                
                sheet.showInView(UIApplication.sharedApplication().keyWindow!)
            } else {
                // TODO - we need to block on a thread or something until we are notified
                // We also should only process the message from players we are waiting on
                self.registerWaitForActionWithHUD({ (action, data) -> Bool in
                    return action.isEqualToString(GameNotificationActions.GameTurnTaken.rawValue)
                    }, callback: { (action, data) -> Void in
                        self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.menu.menuOptionCallback('%@')", action))
                }, message: "Waiting on player")
            }
            
        } else if (url.host == "signalHandStateChanged") {
            var state = url.pathComponents![1] as! String
            if (state == "end") {
                // TODO - if owner, prompt for changes here or start next hand
                // For the others, wait for update from owner
                self.hud.mode = MBProgressHUDMode.Text
                self.hud.labelText = "Hand over..."
                self.hud.showAnimated(true, whileExecutingBlock: { () -> Void in
                    sleep(3)
                }, completionBlock: { () -> Void in
                    self.webView?.stringByEvaluatingJavaScriptFromString("bridge.handStateChangedCallback()")
                })
            } else if (state == "start") {
                self.hud.mode = MBProgressHUDMode.Text
                self.hud.labelText = "Starting hand..."
                self.hud.showAnimated(true, whileExecutingBlock: { () -> Void in
                    sleep(3)
                }, completionBlock: { () -> Void in
                    self.webView?.stringByEvaluatingJavaScriptFromString("bridge.handStateChangedCallback()")
                })
            } else {
                self.hud.mode = MBProgressHUDMode.Text
                self.hud.labelText = String(format: "Ready for the %@", state)
                self.hud.showAnimated(true, whileExecutingBlock: { () -> Void in
                    sleep(3)
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
    
    func fetchAndLoadState(gameStartedCallback : BCVoidBlock?) {
        self.fetchGame(self.gameId!, block: { (game, error) -> Void in
            self.game = game
            self.loadState()
            gameStartedCallback?()
        })
    }
    
    func loadState() {
        self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.loadState(%@)", game!.gameState!))
    }
    
    func startGame(gameStartedCallback : BCVoidBlock?) {
        if (self.isOwner) {
            assert(self.isOwner, "startGame should only be called by game owner")
            
            if (!self.game.isActive || nil == self.game.gameState || self.game.gameState?.length == 0) {
                for user in self.game.activeusers {
                    // JSON encoding - this will likely still break
                    var name = user.name!.stringByReplacingOccurrencesOfString("'", withString: "_")
                    self.webView?.stringByEvaluatingJavaScriptFromString(String(format: "table.addPlayer('%@', '%@', %d)", user.objectId!, name, 100))
                }
                
                self.webView?.stringByEvaluatingJavaScriptFromString("table.randomizePlayers()")
                self.webView?.stringByEvaluatingJavaScriptFromString("table.layoutPlayers()")
                self.webView?.stringByEvaluatingJavaScriptFromString("table.startGame()")
                
                self.game.isActive = true
                
                // Fetch the serialized state
                let state = self.webView?.stringByEvaluatingJavaScriptFromString("JSON.stringify(table.getState())")
                
                // Save off the state and notify
                self.game.gameState = state
                self.save(GameNotificationActions.GameStateChanged, block: nil)
                gameStartedCallback?()
            } else {
                // TODO
                // We really need to figure out how to handle new player additions / removals
                self.loadState()
                gameStartedCallback?()
            }
        } else {
            self.fetchAndLoadState(gameStartedCallback)
        }
    }
}