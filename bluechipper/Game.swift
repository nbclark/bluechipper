//
//  Game.swift
//  bluechipper
//
//  Created by Nicholas Clark on 11/22/14.
//  Copyright (c) 2014 Nicholas Clark. All rights reserved.
//

public class Game : PFObject, PFSubclassing {
  @NSManaged var activeusers : Array<PFUser>
  @NSManaged var users : Array<PFUser>
  
  public class func parseClassName() -> String {
    return "game"
  }
  
//  override public class func load() {
//    super.registerSubclass()
//  }
}

extension PFUser {
  var image : PFFile? {
    get {
      return (self["image"] != nil) ? (self["image"] as! PFFile) : nil
    }
    set(value) {
      self["image"] = value
    }
  }
  
  var name : NSString? {
    get {
      return (self["name"] != nil) ? (self["name"] as! NSString) : nil
    }
    set(value) {
      self["name"] = value
    }
  }
  
  var hashvalue : NSNumber? {
    get {
      return (self["hashvalue"] != nil) ? (self["hashvalue"] as! NSNumber) : nil
    }
    set(value) {
      self["hashvalue"] = value
    }
  }
  
  var paused : Bool {
    get {
      return (self["paused"] != nil) ? (self["paused"] as! Bool) : false
    }
    set(value) {
      self["paused"] = value
    }
  }
  
}