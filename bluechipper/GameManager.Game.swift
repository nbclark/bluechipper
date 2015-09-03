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
            if ((userId == self.user.objectId)) {
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
                self.registerWaitForActionWithHUD({ (userId, action, data) -> Bool in
                    return userId != self.user.objectId && action.isEqualToString(GameNotificationActions.GameTurnTaken.rawValue)
                    }, callback: { (userId, action, data) -> Void in
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
            if (self.isOwner) {
                var pots : NSDictionary = NSJSONSerialization.JSONObjectWithData(url.lastPathComponent!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!, options: nil, error: nil) as! NSDictionary
                // Check for the winners
                // TODO - give a callback to be fired when we have our users
                self.chooseWinners(pots, block: { (pots) -> Void in
                    sleep(0)
                    // TODO - send the result back
                })
            } else {
                self.registerWaitForActionWithHUD({ (userId, action, data) -> Bool in
                    return action.isEqualToString(GameNotificationActions.GameHandWinnersChosen.rawValue)
                    }, callback: { (userId, action, data) -> Void in
                        self.webView?.stringByEvaluatingJavaScriptFromString("bridge.handResultNeededCallback()")
                    }, message: "Waiting for winners...")
            }
        } else if (url.host == "signalHandStartNeeded") {
            if (self.isOwner) {
                // Pause the game, and then when start is click again, start next hand
                // TODO - give callback for unpausing
                self.pauseGame({ () -> Void in
                    sleep(0)
                    // TODO - unpause the game?
                })
                /*
                var sheet = BCActionSheet(title: "Ready for next hand?", cancelButtonTitle: "Make changes...", destructiveButtonTitle: nil)
                sheet.addButtonWithTitle("Start next hand...", handler: { () -> Void in
                    self.webView?.stringByEvaluatingJavaScriptFromString("table.startHand()")
                    self.save(nil, block: nil)
                })
                sheet.cancelButtonHandler = { () -> Void in
                    // TODO - we need to dismiss here, and then show the players view or something
                    // When they come back after, we need to start the hand
                    // Set a bool that startGame will fire the start hand message?
                    self.pauseGame()
                }
                
                sheet.showInView(UIApplication.sharedApplication().keyWindow!)
                */
            } else {
                self.registerWaitForActionWithHUD({ (userId, action, data) -> Bool in
                    return action.isEqualToString(GameNotificationActions.GameHandStarted.rawValue)
                    }, callback: { (userId, action, data) -> Void in
                        self.webView?.stringByEvaluatingJavaScriptFromString("bridge.handStartNeededCallback()")
                    }, message: "Waiting for next hand...")
            }
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        webView.stringByEvaluatingJavaScriptFromString("bridge.signalPlayerActionNeeded = function(actionStates, playerid) { document.location = 'bc://signalPlayerActionNeeded/' + playerid + '/' + JSON.stringify(actionStates) }")
        
        webView.stringByEvaluatingJavaScriptFromString("bridge.signalHandStateChanged = function(state, winners) { document.location = 'bc://signalHandStateChanged/' + state + '/' + JSON.stringify(winners) }")
        
        webView.stringByEvaluatingJavaScriptFromString("bridge.signalHandResultNeeded = function(pots) { document.location = 'bc://signalHandResultNeeded/' + JSON.stringify(pots) }")
        
        webView.stringByEvaluatingJavaScriptFromString("bridge.signalHandStartNeeded = function() { document.location = 'bc://signalHandStartNeeded/' }")
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
                self.save(GameNotificationActions.GameHandStarted, block: nil)
                gameStartedCallback?()
            } else {
                // TODO
                // We really need to figure out how to handle new player additions / removals
                // If we are in a hand, we should just reload I guess - if not, we should start a hand
                self.sendGamePush(GameNotificationActions.GameHandStarted)
                self.webView?.stringByEvaluatingJavaScriptFromString("bridge.handStartNeededCallback()")
//                self.loadState()
//                gameStartedCallback?()
            }
        } else {
            // TODO - here we need to figure out
            self.fetchAndLoadState(gameStartedCallback)
        }
    }
    
    func chooseWinners(pots: NSDictionary, block: BCChooseWinnersBlock) {
        for del in self.delegates {
            let gameDel = del as! GameManagerDelegate
            gameDel.chooseWinners?(pots, block: block)
        }
    }
    
    func pauseGame(block: BCUnpauseGameBlock) {
        for del in self.delegates {
            let gameDel = del as! GameManagerDelegate
            gameDel.pauseGame?(block)
        }
    }
}