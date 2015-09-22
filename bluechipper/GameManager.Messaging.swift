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

    internal func notifyState(state: Int, message: String) {
        for del in self.delegates {
            let gameDel = del as! GameManagerDelegate
            gameDel.didChangeState?(state, message: message)
        }
    }
    
    internal func sendPlayerPush(user : PFUser, message: String) {
        let push = PFPush()
        push.setChannel("c" + user.objectId!)
        push.setMessage(message) // the game should be refetched...
        push.sendPushInBackgroundWithBlock(nil)
    }
    
    internal func sendGamePush(action : GameNotificationActions) {
        self.sendGamePush(action, data: [NSObject : AnyObject]())
    }
    
    internal func sendGamePush(action : GameNotificationActions, data : [NSObject : AnyObject]!) {
        var dict = Dictionary<NSObject, AnyObject>()
        dict["action"] = action.rawValue
        dict["userid"] = PFUser.currentUser()!.objectId!
        
        for (key, value) in data {
            dict[key] = value
        }
        
        if (nil != self.game) {
            let push = PFPush()
            push.setChannel("c" + self.game.objectId!)
            push.setData(dict)
            push.sendPushInBackgroundWithBlock(nil)
        }
    }
}