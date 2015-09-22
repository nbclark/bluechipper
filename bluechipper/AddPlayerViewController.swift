//
//  AddPlayerViewController
//  bluechipper
//
//  Created by Nicholas Clark on 8/1/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation
import XLForm

@available(iOS 8.0, *)
class AddPlayerViewController : XLFormViewController {
    
    @IBOutlet var saveButton : UIBarButtonItem!
    var player : PFUser?
    
    private enum Tags : String {
        case Name = "name"
        case Paid = "paid"
        case Purse = "purse"
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.initializeForm()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeForm()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.saveButton.enabled = Settings.gameManager!.isOwner
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func initializeForm() {
        let form : XLFormDescriptor
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        form = XLFormDescriptor(title: "Player Settings")
        
        section = XLFormSectionDescriptor.formSectionWithTitle("")
        form.addFormSection(section)
        
        // Cells
        row = XLFormRowDescriptor(tag: Tags.Name.rawValue, rowType: XLFormRowDescriptorTypeName, title:"Player Name")
        row.value = nil != self.player ? self.player!.name : "New Player"
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        // TODO - this stuff really should pull from the game-state
        row = XLFormRowDescriptor(tag: Tags.Paid.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Buy-In")
        row.value = nil != self.player ? self.player!.paid : Settings.gameManager!.game.stakes
        row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
        section.addFormRow(row)
        
        if (nil != self.player) {
            row = XLFormRowDescriptor(tag: Tags.Purse.rawValue, rowType: XLFormRowDescriptorTypeDecimal, title:"$ Remaining")
            row.value = nil != self.player ? self.player!.purse : Settings.gameManager!.game.stakes
            row.cellConfig.setObject(NSTextAlignment.Right.rawValue, forKey: "textField.textAlignment")
            section.addFormRow(row)
        }
        
        self.form = form
        self.form.disabled = !Settings.gameManager!.isOwner
    }
    
    @IBAction func saveClicked() {
        let values = self.formValues()
        
        // If we are creating a new player, we need to call a cloud function
        // beacuse Parse only let's the calling user modify users who are
        // themselves. At least there is a workaround what-what
        if (nil == self.player) {
            let username = NSUUID().UUIDString
            let name = values[Tags.Name.rawValue] as! NSString
            
            // TODO - save this player in game manager
            PFCloud.callFunctionInBackground("createNewUser", withParameters: ["username" : username, "name" : name], block: { (res, errno_t) -> Void in
                let query = PFUser.query()!
                query.whereKey("username", equalTo: username)
                query.findObjectsInBackgroundWithBlock({ (users, err) -> Void in
                    let user = users?.first as! PFUser
                    Settings.gameManager!.addPlayer(user, block: { (res, err) -> Void in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                })
            })
        } else {
            // TODO - save this player in game manager
            self.player?.purse = values[Tags.Purse.rawValue] as! NSNumber?
            self.player?.name = values[Tags.Name.rawValue] as! NSString?
            self.player?.paid = values[Tags.Paid.rawValue] as! NSNumber?
            
            // TODO - need to communicate this out
            self.player!.saveInBackgroundWithBlock({ (res, error) -> Void in
                Settings.gameManager!.addPlayer(self.player!, block: { (res, err) -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            })
        }
    }
    
    @IBAction func cancelClicked() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
