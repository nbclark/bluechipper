//
//  SettingsViewController.swift
//  bluechipper
//
//  Created by Nicholas Clark on 2/8/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation

class ProfileViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  @IBOutlet var imageView : PFImageView!
  
  @IBAction func imageTapped() {
    var actionSheet = UIImagePickerController()
    actionSheet.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
    actionSheet.delegate = self
    actionSheet.allowsEditing = true
    
    self.navigationController!.presentViewController(actionSheet, animated: true, completion: { () -> Void in
    })
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
    
    let image = info[UIImagePickerControllerEditedImage] as! UIImage
    let data  = UIImagePNGRepresentation(image)
    var file = PFFile(name: "profile.png", data: data)
    
    self.imageView.image = image
    file.saveInBackgroundWithBlock { (result, error) -> Void in
      if (result) {
        Settings.gameManager!.user.image = file
        Settings.gameManager!.user.saveInBackgroundWithBlock({ (result, error) -> Void in
          NSNotificationCenter.defaultCenter().postNotificationName("gameMemberChangedNotification", object: PFUser.currentUser())
          return
        })
      }
    }
    
    picker.dismissViewControllerAnimated(true, completion: { () -> Void in
      //
    })
  }
  
  override func viewDidLoad() {
    var gesture = UITapGestureRecognizer(target: self, action: Selector("imageTapped"))
    gesture.numberOfTapsRequired = 1
    
    self.imageView.addGestureRecognizer(gesture)

    if ((PFUser.currentUser()!.image) != nil) {
      self.imageView.file = PFUser.currentUser()!.image
      self.imageView.loadInBackground(nil)
    }
  }
}