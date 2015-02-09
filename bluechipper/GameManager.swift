//
//  GameManager.swift
//  bluechipper
//
//  Created by Nicholas Clark on 2/8/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation

class GameManager: NSObject, BeaconRangedMonitorProtocol {
  var beaconMonitor : BeaconMonitor?
  var gameId : String?
  var mainVC : ViewController?
  var game : Game!
  
  convenience init(beaconMonitor:BeaconMonitor) {
    self.init()
    
    //NSNotificationCenter.defaultCenter().addObserver(self, selector: "batteryLevelChanged:", name: UIDeviceBatteryLevelDidChangeNotification, object: nil)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMembersChanged", name: "gameMembersChangedNotification", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMembersChanged", name: UIApplicationDidBecomeActiveNotification, object: nil)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameMemberChanged:", name: "gameMemberChangedNotification", object: nil)
    
    self.beaconMonitor = beaconMonitor
    self.beaconMonitor?.addRangeDelegate(self)
    let navVC = Settings.current?.window?.rootViewController?.presentedViewController as UINavigationController
    self.mainVC = navVC.topViewController as ViewController
    
    if (self.beaconMonitor?.isUpdating == false) {
      self.processRange()
    }
  }
  
  override init() {
    super.init()
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
    let user = notification.object as PFUser
    
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
    query.whereKey("objectId", equalTo: self.game?.objectId)
    
    query.findObjectsInBackgroundWithBlock { (results, error) -> Void in
      var game = results.first as Game
      var existingUserList = game.users
      var activeUserList = game.activeusers
      
      PFObject.fetchAllIfNeededInBackground(existingUserList.union(activeUserList), block: { (res, error) -> Void in
        self.game = game as Game
        NSNotificationCenter.defaultCenter().postNotificationName("gameStateChangedNotification", object: self.game)
      })
    }
  }
  
  func processRange() {
    
    let dict = self.beaconMonitor?.rangedUsers
    var existingGameId : String = ""
    var userList : Array<PFUser> = Array()
    var searchUserList : Array<PFUser> = Array()
    
    for (hashValue, user) in dict! {
      userList.append(user)
      searchUserList.append(user)
    }
    
    searchUserList.append(PFUser.currentUser())
    
    var usersQuery = PFQuery(className: "game")
    var activeUsersQuery = PFQuery(className: "game")
    activeUsersQuery.whereKey("activeusers", containedIn: searchUserList)
    activeUsersQuery.whereKey("disabled", notEqualTo: true)
    usersQuery.whereKey("users", containedIn: searchUserList)
    usersQuery.whereKey("disabled", notEqualTo: true)
    
    var query = PFQuery.orQueryWithSubqueries([usersQuery, activeUsersQuery]);
    
    query.findObjectsInBackgroundWithBlock { (games, error) -> Void in
      var mgames = games
      mgames.sort({ (a, b) -> Bool in
        let pa = a as PFObject
        let pb = b as PFObject
        
        return pa.createdAt.compare(pb.createdAt) == NSComparisonResult.OrderedDescending
      })
      
      for (index, element) in enumerate(mgames) {
        if (index > 0) {
          let po = element as PFObject
          po["disabled"] = true
          po.saveInBackground()
        }
      }
      
      var game : PFObject
      
      if (mgames.count > 0) {
        game = mgames.first! as PFObject
        
        var existingUserList = game["users"] as [PFUser]
        var activeUserList = game["activeusers"] as [PFUser]
        
        if (activeUserList.indexOf({ (u) -> Bool in u.objectId == PFUser.currentUser().objectId }) == nil) {
          game["users"] = existingUserList.union([PFUser.currentUser()]).uniqueBy { (u) -> NSString in
            u.objectId
          }
        }
        
        // Send a push to each user that game state was updated
      } else {
        game = PFObject(className: "game", dictionary: ["users" : userList, "activeusers" : [PFUser.currentUser()]])
      }
      
      var existingUserList = game["users"] as [PFUser]
      var activeUserList = game["activeusers"] as [PFUser]

      PFObject.fetchAllIfNeededInBackground(existingUserList.union(activeUserList), block: { (res, error) -> Void in
        
        game.saveInBackgroundWithBlock({ (res, error) -> Void in
          // Show the players UI
          self.game = game as Game
          self.mainVC?.performSegueWithIdentifier("ChoosePlayersSegue", sender: self.mainVC)
          
          // Send a push that people should update the game
          PFInstallation.currentInstallation().addUniqueObject("c" + game.objectId, forKey: "channels")
          PFInstallation.currentInstallation().saveInBackgroundWithBlock({ (res, error) -> Void in
            var push = PFPush()
            push.setChannel("c" + game.objectId)
            push.setData([ "action" : "gamemembers" ]) // the game should be refetched...
            push.sendPushInBackground()
          })
        })
        
      })
    }
  }
}