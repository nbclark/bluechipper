//
//  PotWinnerViewController.swift
//  bluechipper
//
//  Created by Nicholas Clark on 9/1/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import UIKit
import CoreBluetooth
import MBProgressHUD

class PotWinnerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView : UITableView!
    @IBOutlet var doneButton : UIBarButtonItem!
    
    var pots : [Pot] = []
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.pots.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var pot = self.pots[section]
        
        if (section == 0) {
            return String(format: "Main Pot (%.02f)", pot.size)
        } else {
            return String(format: "Side Pot (%.02f)", pot.size)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var pot = self.pots[section]
        return pot.players.count
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO
        // select the row
        // when each section has at least one row selected, move on
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! PlayerTableViewCell
        //cell.selected = true
        
        var pot = self.pots[indexPath.section]
        var user = pot.players[indexPath.row]
        
        if (pot.winners.indexOf({ (p) -> Bool in p.objectId == user.objectId }) == nil) {
            pot.winners.push(user)
        }
        
        self.checkComplete()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var pot = self.pots[indexPath.section]
        var user = pot.players[indexPath.row]
        
        pot.winners.remove(user)
        self.checkComplete()
    }
    
    func checkComplete() {
        var complete = true
        
        for pot in self.pots {
            if (pot.winners.count == 0) {
                complete = false
                break
            }
        }
        
        self.doneButton.enabled = complete
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! PlayerTableViewCell
        
        var pot = self.pots[indexPath.section]
        var user = pot.players[indexPath.row]
        
        cell.accessoryType = UITableViewCellAccessoryType.None
        cell.orderLabel.hidden = false
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