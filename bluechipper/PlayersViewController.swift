//
//  PlayersViewController.swift
//  bluechipper
//
//  Created by Nicholas Clark on 11/22/14.
//  Copyright (c) 2014 Nicholas Clark. All rights reserved.
//

import UIKit
import CoreBluetooth


class PlayersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BeaconRangedMonitorDelegate {
    @IBOutlet var tableView : UITableView?
    @IBOutlet var startButton : UIBarButtonItem?
    @IBOutlet var settingsButton : UIBarButtonItem?
    
    var eligbleUsers : Array<PFUser> = Array()
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Settings.beaconMonitor?.addRangeDelegate(self)
                
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameStateChanged", name: "gameStateChangedNotification", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView!.reloadData()
        self.startButton!.enabled = true
        
        if (Settings.gameManager!.game.owner == PFUser.currentUser()?.objectId!) {
            if (nil == Settings.gameManager!.game.bigBlind) {
                self.performSegueWithIdentifier("SettingsSegue", sender: nil)
            }
        } else {
            // We are not the owner
            // TODO - we need to transfer the owner when someone leaves, n'est pas?
            self.settingsButton?.enabled = false
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updatedPlayerList() {
        // TODO - this should be in the game manager
        var push = PFPush()
        push.setChannel("c" + Settings.gameManager!.game!.objectId!)
        push.setData([ "action" : "gamemembers" ]) // the game should be refetched...
        push.sendPushInBackgroundWithBlock(nil)
    }
    
    func gameStateChanged() {
        self.rangedBeacons()
    }
    
    func rangedBeacons() {
        self.eligbleUsers = Array()
        let game = Settings.gameManager!.game
        
        let beaconUsers = (Settings.beaconMonitor!.rangedUsers.values.array as Array<PFUser>?)!
        
        for user in game.users.union(beaconUsers).uniqueBy({ (u) -> NSString in u.objectId! }) {
            if (game.activeusers.indexOf( { (u) -> Bool in u.objectId == user.objectId }) == nil) {
                self.eligbleUsers.append(user)
            }
        }
        
        self.tableView?.reloadData()
    }
    
    @IBAction func startClicked() {
        // TODO - if we are in a game, let it go
        // Otherwise, start
        Settings.gameManager!.startGame()
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Active Players"
        } else {
            return "Eligible Players"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            let count : Int? = Settings.gameManager?.game?["activeusers"]!.count
            
            return count!
        } else {
            let count : Int? = self.eligbleUsers.count
            
            return count!
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        // New players are accept/reject
        // Active players are rebuy/pause/quit
        // Empty players are rebuy/remove
        var suspendAction = UITableViewRowAction(style: .Default, title: "Pause") { (action, indexPath) -> Void in
            tableView.editing = false
        }
        suspendAction.backgroundColor = UIColor.blueColor()
        
        var deleteAction = UITableViewRowAction(style: .Default, title: "Reject") { (action, indexPath) -> Void in
            var game = Settings.gameManager!.game
            var user = game.activeusers[indexPath.row] as PFUser
            
            game.activeusers.remove(user)
            tableView.editing = false
            
            var push = PFPush()
            push.setChannel("c" + user.objectId!)
            push.setMessage("Sorry to see you go") // the game should be refetched...
            push.sendPushInBackgroundWithBlock(nil)
            
            self.rangedBeacons()
            Settings.gameManager?.game?.saveInBackgroundWithBlock({ (res, err) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.updatedPlayerList()
                    return
                })
            })
        }
        deleteAction.backgroundColor = UIColor.redColor()
        
        var acceptAction = UITableViewRowAction(style: .Default, title: "Accept") { (action, ip) -> Void in
            tableView.editing = false
            var game = Settings.gameManager!.game
            let user = self.eligbleUsers[ip.row]
            
            game.activeusers.append(user)
            game.users.remove(user)
            
            var vc = self
            
            var push = PFPush()
            push.setChannel("c" + user.objectId!)
            push.setMessage("Welcome to the game") // the game should be refetched...
            push.sendPushInBackgroundWithBlock(nil)
            
            self.rangedBeacons()
            Settings.gameManager?.game?.saveInBackgroundWithBlock({ (res, err) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.updatedPlayerList()
                    return
                })
            })
        }
        acceptAction.backgroundColor = UIColor.greenColor()
        var game = Settings.gameManager!.game
        let objectId : NSString = PFUser.currentUser()!.objectId!
        let objectId2: NSString = game.activeusers[indexPath.row].objectId!
        let result = (objectId == objectId2);
        
        if ((indexPath.section == 0) && result) {
            return nil
        }
        
        if (indexPath.section == 0) {
            return [ deleteAction, suspendAction ];
        } else {
            return [ acceptAction ];
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! PlayerTableViewCell
        var user : PFUser!
        
        if (indexPath.section == 0) {
            var game = Settings.gameManager!.game
            user = game.activeusers[indexPath.row]
            cell.accessoryType = UITableViewCellAccessoryType.None
            cell.orderLabel.hidden = false
            cell.orderLabel.text = String(indexPath.row)
        } else {
            user = self.eligbleUsers[indexPath.row]
            cell.orderLabel.hidden = true
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        cell.nameLabel.text = String(user.name!)
        
        if (user.image != nil) {
            cell.pictureImage.file = user.image
            cell.pictureImage.loadInBackground(nil)
        } else {
            cell.pictureImage.image = UIImage(named: "no-face.png")
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 96;
    }
}