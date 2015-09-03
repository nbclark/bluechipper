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
    @IBOutlet var tableView : UITableView?
    var pots : NSDictionary?
    var potData : [Pot] = []
    
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
        return self.potData.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var pot = self.potData[section]
        
        if (section == 0) {
            return String(format: "Main Pot (%d)", pot.size)
        } else {
            return String(format: "Side Pot (%d)", pot.size)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var pot = self.potData[section]
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
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! PlayerTableViewCell
        
        var pot = self.potData[indexPath.section]
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