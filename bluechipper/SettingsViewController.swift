//
//  SettingsViewController.swift
//  bluechipper
//
//  Created by Nicholas Clark on 8/1/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation
import XLForm

class SettingsViewController : XLFormViewController {
    
    private enum Tags : String {
        case Stakes = "stakes"
        case SmallBlind = "smallblind"
        case BigBlind = "bigblind"
        case IsNoLimit = "nolimit"
        case IsOpen = "isopen"
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.initializeForm()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeForm()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        let values = self.formValues()
        Settings.gameManager!.game.stakes = values[Tags.Stakes.rawValue] as! NSNumber?
        Settings.gameManager!.game.smallBlind = values[Tags.SmallBlind.rawValue] as! NSNumber?
        Settings.gameManager!.game.bigBlind = values[Tags.BigBlind.rawValue] as! NSNumber?
        Settings.gameManager!.game.isNoLimit = values[Tags.IsNoLimit.rawValue] as! Bool?
        Settings.gameManager!.game.isOpen = values[Tags.IsOpen.rawValue] as! Bool?
        
        // TODO - need to communicate this out
        Settings.gameManager!.save()
        sleep(0)
    }
    
    func initializeForm() {
        let form : XLFormDescriptor
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        form = XLFormDescriptor(title: "Game Settings")
        
        section = XLFormSectionDescriptor.formSectionWithTitle("The Stakes")
        form.addFormSection(section)
        
        // Stakes
        row = XLFormRowDescriptor(tag: Tags.Stakes.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Buy-In")
        row.value = nil != Settings.gameManager!.game.stakes ? Settings.gameManager!.game.stakes : 20.00
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        // Stakes
        row = XLFormRowDescriptor(tag: Tags.SmallBlind.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Small Blind")
        row.value = nil != Settings.gameManager!.game.smallBlind ? Settings.gameManager!.game.smallBlind : 0.25
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        // Stakes
        row = XLFormRowDescriptor(tag: Tags.BigBlind.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Big Blind")
        row.value = nil != Settings.gameManager!.game.bigBlind ? Settings.gameManager!.game.bigBlind : 0.50
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        section = XLFormSectionDescriptor.formSectionWithTitle("The Logistics")
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: Tags.IsNoLimit.rawValue, rowType: XLFormRowDescriptorTypeBooleanSwitch, title:"No Limit")
        row.value = nil != Settings.gameManager!.game.isNoLimit ? Settings.gameManager!.game.isNoLimit : true
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: Tags.IsOpen.rawValue, rowType: XLFormRowDescriptorTypeBooleanSwitch, title:"Allow Join Requests")
        row.value = nil != Settings.gameManager!.game.isOpen ? Settings.gameManager!.game.isOpen : true
        section.addFormRow(row)
        
        self.form = form
    }
    
}
