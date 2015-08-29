//
//  BTActionSheet.swift
//  bluechipper
//
//  Created by Nicholas Clark on 8/19/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation

class BCActionSheet : UIActionSheet, UIActionSheetDelegate
{
    private var _userButtonHandlers : Dictionary<NSNumber, (()->Void)> = Dictionary<NSNumber, (()->Void)>()
    
    var cancelButtonHandler : (()->Void)?
    var destructiveButtonHandler : (()->Void)?
    
    init(title: String?, cancelButtonTitle: String?, destructiveButtonTitle: String?)
    {
        super.init(title: title, delegate: nil, cancelButtonTitle: cancelButtonTitle, destructiveButtonTitle: destructiveButtonTitle);
        self.delegate = self
    }
    override init(frame: CGRect) { super.init(frame: frame) }
    required init(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    func addButtonWithTitle(title: String, handler: (()->Void)?) -> Int
    {
        let index = super.addButtonWithTitle(title)
        
        if (nil != handler) {
            _userButtonHandlers[index] = handler
        }
        
        return index
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int)
    {
        if (actionSheet.cancelButtonIndex == buttonIndex) {
            self.cancelButtonHandler?()
        } else if (actionSheet.destructiveButtonIndex == buttonIndex) {
            self.destructiveButtonHandler?()
        } else {
            self._userButtonHandlers[buttonIndex]?()
        }
    }
}