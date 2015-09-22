//
//  PlayersViewController.swift
//  bluechipper
//
//  Created by Nicholas Clark on 11/22/14.
//  Copyright (c) 2014 Nicholas Clark. All rights reserved.
//

import UIKit
import CoreBluetooth
import MBProgressHUD

@available(iOS 8.0, *)
class PlayersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BeaconRangedMonitorDelegate {
    @IBOutlet var tableView : UITableView?
    @IBOutlet var addPlayerButton : UIBarButtonItem?
    @IBOutlet var settingsButton : UIBarButtonItem?
    @IBOutlet var startButton : UIButton!
    
    var eligbleUsers : Array<PFUser> = Array()
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Settings.beaconMonitor?.addRangeDelegate(self)
                
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameStateChanged", name: "gameStateChangedNotification", object: nil)
        
        self.startButton.enabled = false
        if (Settings.gameManager!.isOwner) {
            self.startButton.enabled = true
        } else if (Settings.gameManager!.game.isActive) {
            self.startButton.enabled = true
            self.startButton.titleLabel!.text = "Back to Game"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.startButton!.enabled = true
        
        if (Settings.gameManager!.game.owner == Settings.gameManager!.user.objectId!) {
            if (!Settings.gameManager!.game.isConfigured) {
                self.performSegueWithIdentifier("SettingsSegue", sender: nil)
            }
        } else {
            // We are not the owner
            // TODO - we need to transfer the owner when someone leaves, n'est pas?
            self.addPlayerButton?.enabled = false
        }
        
        self.rangedBeacons()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        // If we are editing an existing player, set the property
        // TODO - no clue if this is the right way to do this
        if (segue.identifier == "AddPlayerSegue" && nil != sender) {
            let navVC = segue.destinationViewController as! UINavigationController
            let playerVC = navVC.topViewController as! AddPlayerViewController
            playerVC.player = sender as? PFUser
        }
    }
    
    @IBAction func startClicked() {
        // TODO - if we are in a game, let it go
        // Otherwise, start
        Settings.gameManager!.hud.mode = MBProgressHUDMode.Indeterminate
        Settings.gameManager!.hud.show(true)
        
//        if let layer = self.navigationController?.view.layer {
//            var transition = CATransition()
//            transition.duration = 0.3
//            transition.type = kCATransitionFade
//            transition.subtype = kCATransitionFromTop
//            layer.addAnimation(transition, forKey: kCATransition)
//        }
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            Settings.gameManager!.startGame({ () -> Void in
                Settings.gameManager!.hud.hide(true)
            })
        })
    }
    
    func updatedPlayerList() {
        self.tableView?.reloadData()
    }
    
    func gameStateChanged() {
        self.rangedBeacons()
    }
    
    func rangedBeacons() {
        self.eligbleUsers = Array()
        let game = Settings.gameManager!.game
        
        let beaconUsers = Array<PFUser>(Settings.beaconMonitor!.rangedUsers.values)
        
        for user in beaconUsers {
            if (game.activeusers.indexOf( { (u) -> Bool in u.objectId == user.objectId }) == nil) {
                self.eligbleUsers.append(user)
            }
        }
        for user in game.users {
            if (game.activeusers.indexOf( { (u) -> Bool in u.objectId == user.objectId }) == nil) {
                self.eligbleUsers.append(user)
            }
        }
        
        self.tableView?.reloadData()
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
            let count = Settings.gameManager?.game.activeusers.count
            
            return count!
        } else {
            let count : Int? = self.eligbleUsers.count
            
            return count!
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        // New players are accept/reject
        // Active players are rebuy/pause/quit
        // Empty players are rebuy/remove
        let suspendAction = UITableViewRowAction(style: .Default, title: "Pause") { (action, indexPath) -> Void in
            tableView.editing = false
        }
        suspendAction.backgroundColor = UIColor.blueColor()
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "Reject") { (action, indexPath) -> Void in
            let game = Settings.gameManager!.game
            let user = game.activeusers[indexPath.row] as PFUser
            
            Settings.gameManager!.removePlayer(user, block: { (res, err) -> Void in
                self.updatedPlayerList()
            })
        }
        
        deleteAction.backgroundColor = UIColor.redColor()
        
        let acceptAction = UITableViewRowAction(style: .Default, title: "Accept") { (action, ip) -> Void in
            tableView.editing = false
            let user = self.eligbleUsers[ip.row]
            self.eligbleUsers.removeAtIndex(ip.row)
            
            Settings.gameManager!.addPlayer(user, block: { (res, err) -> Void in
                self.updatedPlayerList()
            })
        }
        acceptAction.backgroundColor = UIColor.greenColor()
        let game = Settings.gameManager!.game
        let objectId : NSString = Settings.gameManager!.user.objectId!
        let objectId2: NSString = game.activeusers[indexPath.row].objectId!
        let result = (objectId == objectId2);
        
        if ((indexPath.section == 0) && result) {
            return nil
        }
        
        // Only allow tweaking of players from the owner?
        // TODO - or should we allow everyone
        if (Settings.gameManager!.isOwner) {
            if (indexPath.section == 0) {
                return [ deleteAction, suspendAction ];
            } else {
                return [ acceptAction ];
            }
        } else {
            return [];
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {        
        if (indexPath.section == 0) {
            let game = Settings.gameManager!.game
            let user = game.activeusers[indexPath.row]
            self.performSegueWithIdentifier("SettingsSegue", sender: user)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! PlayerTableViewCell
        var user : PFUser!
        
        if (indexPath.section == 0) {
            let game = Settings.gameManager!.game
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