//
//  LoadingViewController.swift
//  bluechipper
//
//  Created by Nicholas Clark on 2/8/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation

// LoadedSegue
class LoadingViewController: UIViewController, GameManagerDelegate, UIActionSheetDelegate {
    @IBOutlet var loadingLabel : UILabel!
    @IBOutlet var activitySpinner : UIActivityIndicatorView!
    @IBOutlet var editProfileButton : UIButton!
    @IBOutlet var startGameButton : UIButton!
    @IBOutlet var joinGameButton : UIButton!
    
    var joinGames : Array<Game> = Array<Game>()
    var existingGame : Game?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Settings.gameManager!.addDelegate(self)
    }
    
    internal func loaded() {
        self.performSegueWithIdentifier("LoadedSegue", sender: self)
    }
    
    @IBAction func startClicked() {
        Settings.gameManager!.createGame()
    }
    
    @IBAction func joinClicked() {
        var sheet = UIActionSheet(title: "Join Existing Game", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)
        sheet.tag = 0
        
        self.joinGames = Array<Game>(Settings.gameManager!.joinGames)
        
        for game in Settings.gameManager!.joinGames {
            let name = String(game.name!)
            let index = sheet.addButtonWithTitle(name)
        }
        
        sheet.showInView(self.view)
    }
    
    func didChangeState(state: Int, message: String) {
        self.loadingLabel.text = message
        
        if (state > 2) {
            self.startGameButton.hidden = false
        }
        
        // We found existing games to join
        if (state >= 4) {
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.75 * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
                self.joinGameButton.hidden = false
                self.activitySpinner.hidden = true
                self.loadingLabel.hidden = true
                self.joinGameButton?.setTitle(String(format: "Join Game (%d)", Settings.gameManager!.joinGames.count), forState: UIControlState.Normal)
                self.joinGameButton?.layoutSubviews()
            }
        } else {
            self.joinGameButton.hidden = true
            self.activitySpinner.hidden = false
            self.loadingLabel.hidden = false
        }
    }
    func foundExistingGame(game: Game) {
        // We found an existing game
        var sheet = UIActionSheet(title: "Re-join Existing Game", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: "Delete Game")
        sheet.tag = 1
        sheet.addButtonWithTitle(String(format: "Join '%@'", game.name!))
        sheet.showInView(self.view)
        
        self.existingGame = game
    }
    
    func joinedGame(game: Game) {
        self.performSegueWithIdentifier("GameSettingsSegue", sender: self)
    }
    
    func actionSheet(actionSheet: UIActionSheet, willDismissWithButtonIndex buttonIndex: Int) {
        if (actionSheet.tag == 0) {
            // Join existing
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                // We are cancelling now
                return
            } else {
                var game = self.joinGames[buttonIndex - 1]
                Settings.gameManager!.joinGame(game)
            }
        } else if (actionSheet.tag == 1) {
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                // Do nothing
            } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
                // Let's delete
                Settings.gameManager!.exitGame(self.existingGame!)
            } else {
                // Lets join
                Settings.gameManager!.joinGame(self.existingGame!)
            }
        }
    }
}