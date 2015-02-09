//
//  LoadingViewController.swift
//  bluechipper
//
//  Created by Nicholas Clark on 2/8/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation

// LoadedSegue
class LoadingViewController: UIViewController {
  internal func loaded() {
    self.performSegueWithIdentifier("LoadedSegue", sender: self)
  }
}