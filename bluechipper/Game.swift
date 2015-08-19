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
    
    var name : NSString? {
        get {
            return (self["name"] != nil) ? (self["name"] as! NSString) : nil
        }
        set(value) {
            self["name"] = value
        }
    }
    
    var owner : NSString? {
        get {
            return (self["owner"] != nil) ? (self["owner"] as! NSString) : nil
        }
        set(value) {
            self["owner"] = value
        }
    }
    
    var isActive : Bool {
        get {
            return (self["isactive"] != nil) ? (self["isactive"] as! Bool) : false
        }
        set(value) {
            self["isactive"] = value
        }
    }
    
    var isOpen : Bool {
        get {
            return (self["isopen"] != nil) ? (self["isopen"] as! Bool) : true
        }
        set(value) {
            self["isopen"] = value
        }
    }
    
    var isNoLimit : Bool {
        get {
            return (self["isnolimit"] != nil) ? (self["isnolimit"] as! Bool) : true
        }
        set(value) {
            self["isnolimit"] = value
        }
    }
    
    var smallBlind : NSNumber {
        get {
            return (self["smallblind"] != nil) ? (self["smallblind"] as! NSNumber) : 0.25
        }
        set(value) {
            self["smallblind"] = value
        }
    }
    
    var bigBlind : NSNumber {
        get {
            return (self["bigblind"] != nil) ? (self["bigblind"] as! NSNumber) : 0.5
        }
        set(value) {
            self["bigblind"] = value
        }
    }
    
    var stakes : NSNumber {
        get {
            return (self["stakes"] != nil) ? (self["stakes"] as! NSNumber) : 20.0
        }
        set(value) {
            self["stakes"] = value
        }
    }
    
    var dealerButton : NSString? {
        get {
            return (self["dealerbutton"] != nil) ? (self["dealerbutton"] as! NSString) : nil
        }
        set(value) {
            self["dealerbutton"] = value
        }
    }
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
    
    var paid : NSNumber? {
        get {
            return (self["paid"] != nil) ? (self["paid"] as! NSNumber) : nil
        }
        set(value) {
            self["paid"] = value
        }
    }
    
    var stack : NSNumber? {
        get {
            return (self["stack"] != nil) ? (self["stack"] as! NSNumber) : nil
        }
        set(value) {
            self["stack"] = value
        }
    }
    
}