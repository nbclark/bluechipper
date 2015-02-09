//
//  ViewController.swift
//  bluechipper
//
//  Created by Nicholas Clark on 10/4/14.
//  Copyright (c) 2014 Nicholas Clark. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreBluetooth

class ViewController: UIViewController {
  
  @IBOutlet var webView : UIWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let url = NSBundle.mainBundle().URLForResource("table", withExtension:"html")
    self.webView.scrollView.scrollEnabled = false
    self.webView.loadRequest(NSURLRequest(URL: url!))
  }
  
}