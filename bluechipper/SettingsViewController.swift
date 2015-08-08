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
        case Logistics = "logistics"
        case DateTimeInline = "dateTimeInline"
        case CountDownTimerInline = "countDownTimerInline"
        case DatePicker = "datePicker"
        case Date = "date"
        case Time = "time"
        case DateTime = "dateTime"
        case CountDownTimer = "countDownTimer"
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.initializeForm()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeForm()
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
        row.value = "20.00"
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        // Stakes
        row = XLFormRowDescriptor(tag: Tags.Stakes.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Small Blind")
        row.value = "0.25"
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        // Stakes
        row = XLFormRowDescriptor(tag: Tags.Stakes.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Big Blind")
        row.value = "0.50"
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        section = XLFormSectionDescriptor.formSectionWithTitle("The Logistics")
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: Tags.Logistics.rawValue, rowType: XLFormRowDescriptorTypeBooleanSwitch, title:"No Limit")
        row.value = true
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: Tags.Logistics.rawValue, rowType: XLFormRowDescriptorTypeBooleanSwitch, title:"Allow Join Requests")
        row.value = true
        section.addFormRow(row)
        
        self.form = form
    }
}
