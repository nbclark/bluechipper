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
        
        if (!self.form.disabled) {
            let values = self.formValues()
            Settings.gameManager!.game.stakes = values[Tags.Stakes.rawValue] as! NSNumber
            Settings.gameManager!.game.smallBlind = values[Tags.SmallBlind.rawValue] as! NSNumber
            Settings.gameManager!.game.bigBlind = values[Tags.BigBlind.rawValue] as! NSNumber
            Settings.gameManager!.game.isNoLimit = values[Tags.IsNoLimit.rawValue] as! Bool
            Settings.gameManager!.game.isOpen = values[Tags.IsOpen.rawValue] as! Bool
            
            // TODO - need to communicate this out
            Settings.gameManager!.game.isConfigured = true
            Settings.gameManager!.save(nil, block:  nil)
        }
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
        row.value = Settings.gameManager!.game.stakes
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        // Stakes
        row = XLFormRowDescriptor(tag: Tags.SmallBlind.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Small Blind")
        row.value = Settings.gameManager!.game.smallBlind
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        // Stakes
        row = XLFormRowDescriptor(tag: Tags.BigBlind.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Big Blind")
        row.value = Settings.gameManager!.game.bigBlind
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        section = XLFormSectionDescriptor.formSectionWithTitle("The Logistics")
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: Tags.IsNoLimit.rawValue, rowType: XLFormRowDescriptorTypeBooleanSwitch, title:"No Limit")
        row.value = Settings.gameManager!.game.isNoLimit
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: Tags.IsOpen.rawValue, rowType: XLFormRowDescriptorTypeBooleanSwitch, title:"Allow Join Requests")
        row.value = Settings.gameManager!.game.isOpen
        section.addFormRow(row)
        
        self.form = form
        self.form.disabled = !Settings.gameManager!.isOwner
    }
    
}
