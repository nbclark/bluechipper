//
//  GameManager.swift
//  bluechipper
//
//  Created by Nicholas Clark on 2/8/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation
import MBProgressHUD

@available(iOS 8.0, *)
extension GameManager {
    
    func addPlayer(player : PFUser, block : PFBooleanResultBlock?) {
        let user = player
        
        self.game.activeusers.append(user)
        self.game.users.removeObject(user)
        
        self.sendPlayerPush(user, message: "Welcome to the game")
        self.save(GameNotificationActions.GameMembersChanged, block : block)
    }
    
    func removePlayer(player : PFUser, block : PFBooleanResultBlock?) {
        let user = player
        
        self.game.activeusers.removeObject(user)
        
        self.sendPlayerPush(user, message: "Sorry to see you go")
        self.save(GameNotificationActions.GameMembersChanged, block : block)
    }
    
    func gameMembersChanged() {
        if (self.game != nil) {
            self.reload()
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
            self.save(GameNotificationActions.GameMembersChanged, block : nil)
        }
    }
}