//
//  AppDelegate.swift
//  bluechipper
//
//  Created by Nicholas Clark on 10/4/14.
//  Copyright (c) 2014 Nicholas Clark. All rights reserved.
//

import UIKit
import CoreBluetooth

struct Settings {
  static var current: AppDelegate?
  static var beaconMonitor: BeaconMonitor?
  static var gameManager: GameManager?
}

@UIApplicationMain
internal class AppDelegate: UIResponder, UIApplicationDelegate, BeaconMonitorProtocol {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    Settings.current = self
    // Override point for customization after application launch.
    Game.registerSubclass()
    Parse.setApplicationId("GJ3ntLAsWRr0W0kdjHafaXalLDXYi5dksD1GvejT",
      clientKey: "N4C7s205pJYOxNVmHQKloGNIBH2EicUppnmZsqOu")
    PFUser.enableAutomaticUser()
    PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
    
    let user = PFUser.currentUser()
    user.saveInBackgroundWithBlock { (result, error) -> Void in
      let userId = user.objectId;
      let hashValue = userId.hash & 0x7FFF7FFF
      PFUser.currentUser().hashvalue = hashValue
      PFUser.currentUser().name = UIDevice.currentDevice().name
      PFUser.currentUser().saveInBackgroundWithBlock { (result, error) -> Void in
        Settings.beaconMonitor = BeaconMonitor(delegate: self)
        Settings.beaconMonitor?.start()
      }
      
      let settings = UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound, categories: nil)
      let types : UIRemoteNotificationType = UIRemoteNotificationType.Alert | UIRemoteNotificationType.Badge | UIRemoteNotificationType.Sound;
      
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }

    return true
  }
  
  func monitoringAndAdvertisingEnabled() {
    // Give 2 seconds to range beacons
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
      let loadingController = self.window?.rootViewController as LoadingViewController
      loadingController.loaded()
      
      dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
        Settings.gameManager = GameManager(beaconMonitor: Settings.beaconMonitor!)
      }
    }
  }
  
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    sleep(0)
  }
  
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    var installation = PFInstallation.currentInstallation()
    installation.setDeviceTokenFromData(deviceToken)
    installation.addUniqueObject("c" + PFUser.currentUser().objectId, forKey: "channels")
    installation.saveInBackgroundWithBlock { (res, error) -> Void in
      return
    }
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    sleep(0)
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    var msg = userInfo["action"] as NSString?
    
    if (nil != msg) {
      if (msg!.isEqualToString("gamemembers")) {
        NSNotificationCenter.defaultCenter().postNotificationName("gameMembersChangedNotification", object: nil)
      } else if (msg!.isEqualToString("gamestate")) {
        //
      }
    }
    
    completionHandler(UIBackgroundFetchResult.NewData)
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}
