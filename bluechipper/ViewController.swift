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

class ViewController: UIViewController, GameManagerDelegate {
    
    @IBOutlet var webView : UIWebView!
    var firstLoad : Bool
    
    required init(coder aDecoder: NSCoder)
    {
        self.firstLoad = true
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Yes I am going to write the game table in HTML
        // Once they make a better UI language, I'll use that - but fuck recompiling
        let url = NSBundle.mainBundle().URLForResource("table", withExtension:"html")
        self.webView.scrollView.scrollEnabled = false
        self.webView.loadRequest(NSURLRequest(URL: url!))
        self.webView.delegate = Settings.gameManager
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (self.firstLoad) {
            self.pauseGame({ () -> Void in
                // TODO
            })
        }
        
        self.firstLoad = false
        Settings.gameManager?.addDelegate(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        Settings.gameManager?.removeDelegate(self)
        super.viewWillDisappear(animated)
    }
    
    var winnersChosenBlock : BCChooseWinnersBlock?
    var pots : [Pot] = []
    
    func chooseWinners(pots: [Pot], block: BCChooseWinnersBlock) {
        self.pots = pots
        self.winnersChosenBlock = block
        self.performSegueWithIdentifier("ChooseWinnersSegue", sender: self)
    }
    
    func pauseGame(block: BCUnpauseGameBlock) {
        self.performSegueWithIdentifier("PlayersSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender);
        
        if let navVC = segue.destinationViewController as? UINavigationController {
            if let winnersVC = navVC.topViewController as? PotWinnerViewController {
                winnersVC.pots = self.pots
            }
        }
    }
}