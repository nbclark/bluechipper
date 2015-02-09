//
//  BeaconMonitor.swift
//  bluechipper
//
//  Created by Nicholas Clark on 1/31/15.
//  Copyright (c) 2015 Nicholas Clark. All rights reserved.
//

import Foundation
import CoreBluetooth


protocol BeaconMonitorProtocol : NSObjectProtocol {
  func monitoringAndAdvertisingEnabled()
}

@objc protocol BeaconRangedMonitorProtocol {
  func rangedBeacons()
}

internal class BeaconMonitor : NSObject
{
  var locMan: CLLocationManager?
  var locAdv: CBPeripheralManager?
  var locReg: CLBeaconRegion?
  var advReg: CLBeaconRegion?
  var uuid  : NSUUID! = NSUUID(UUIDString: "CC7E6EC0-0D78-449C-9737-92333CB38238")
  var rangedUsers : Dictionary<UInt32, PFUser> = Dictionary()
  var monitorEnabled: Bool = false
  var advertisingEnabled: Bool = false
  var enableAlerted: Bool = false
  var delegate: BeaconMonitorProtocol?
  var rangedDelegates : NSMutableArray = NSMutableArray()
  var isUpdating : Bool = false
  
  convenience init(delegate:BeaconMonitorProtocol) {
    self.init()
    
    self.delegate = delegate
  }
  
  internal func addRangeDelegate(delegate: BeaconRangedMonitorProtocol) {
    self.rangedDelegates.addObject(delegate)
  }
  
  internal func removeRangeDelegate(delegate: BeaconRangedMonitorProtocol) {
    self.rangedDelegates.removeObject(delegate)
  }
  
  override init() {
    super.init()
    
    locMan = CLLocationManager()
    locMan?.delegate = self
    
    let options: Dictionary<NSString, AnyObject> = [ CBPeripheralManagerOptionShowPowerAlertKey: true ]
    locAdv = CBPeripheralManager(delegate: self, queue: nil, options: options)
    
    // We will set up a beacon and range with the major and minor being this hash value
    // Use that to pool people together, and set up a push group
    // When new devices show up, show them in the list
    // Allow reordering
    // When a turn is ready,
    
    locReg = CLBeaconRegion(proximityUUID: uuid, identifier: "")
    locMan?.startMonitoringForRegion(locReg)
  }
  
  func checkLoaded() {
    if (self.monitorEnabled && self.advertisingEnabled && !self.enableAlerted) {
      if (nil != self.delegate) {
        self.delegate?.monitoringAndAdvertisingEnabled()
      }
      
      self.enableAlerted = true
    }
  }
  
  internal func start() {
    if (self.locMan?.respondsToSelector(Selector("requestAlwaysAuthorization")) != nil) {
      self.locMan?.requestAlwaysAuthorization()
    }
    
    let hashValue : Int = PFUser.currentUser()["hashvalue"].integerValue
    let major : UInt16 = (UInt16(hashValue >> 16) & 0xFFFF)
    let minor : UInt16 = UInt16(hashValue & 0xFFFF)
    println("\(major) - \(minor)")
    println("\(hashValue)")
    
    advReg = CLBeaconRegion(proximityUUID: uuid, major: major, minor: minor, identifier: "")
    let data = advReg?.peripheralDataWithMeasuredPower(nil)
    locAdv?.startAdvertising(data)
  }
}


extension BeaconMonitor : CBPeripheralManagerDelegate
{
  func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
    if (peripheral.state == CBPeripheralManagerState.PoweredOn) {
      
      let perData = advReg?.peripheralDataWithMeasuredPower(-63)
      locAdv?.startAdvertising(perData)
      
      self.advertisingEnabled = true
      self.checkLoaded()
    } else {
      locAdv?.stopAdvertising()
    }
  }
}

extension BeaconMonitor : CLLocationManagerDelegate
{
  func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!) {
    manager.startRangingBeaconsInRegion(self.locReg)
  }
  func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
    manager.startRangingBeaconsInRegion(self.locReg)
  }
  func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
    manager.stopMonitoringForRegion(region)
  }
  func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
    sleep(0)
  }
  func locationManager(manager: CLLocationManager!, rangingBeaconsDidFailForRegion region: CLBeaconRegion!, withError error: NSError!) {
    sleep(0)
  }
  func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
    manager.requestStateForRegion(region)
    
    self.monitorEnabled = true
    self.checkLoaded()
  }
  func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [CLBeacon]!, inRegion region: CLBeaconRegion!) {
    var needsUpdate : Bool = false
    
    var hashes : Array<AnyObject> = []
    
    for beacon : CLBeacon in beacons {
      let hashValue : UInt32 = (((UInt32(beacon.major.unsignedShortValue) << 16) & 0xFFFF0000) | UInt32(beacon.minor.unsignedShortValue & 0xFFFF)) & 0x7FFF7FFF;
      
      if (nil == rangedUsers.indexForKey(hashValue)) {
        hashes.append(NSNumber(unsignedInt: hashValue))
        needsUpdate = true
      }
    }
    
    if (needsUpdate) {
      var query : PFQuery = PFUser.query()
      query.whereKey("hashvalue", containedIn: hashes)
      self.isUpdating = true
      query.findObjectsInBackgroundWithBlock({ (users, error) -> Void in
        for user in users as [PFUser] {
          let hashValue = user.hashvalue!.unsignedIntValue
          let name = user.name
          let pfUser = user as PFUser
          
          self.rangedUsers[hashValue] = pfUser
        }
        
        for rangedDelegate in self.rangedDelegates {
          let d = (rangedDelegate as BeaconRangedMonitorProtocol)
          d.rangedBeacons()
        }
        self.isUpdating = false
      })
    }
  }
}

extension Array {
  mutating func removeObject<T: Equatable>(object: T) {
    var index: Int?
    for (idx, objectToCompare) in enumerate(self) {
      let to = objectToCompare as T
      if object == to {
        index = idx
      }
    }
    
    if(index != nil) {
      self.removeAtIndex(index!)
    }
  }
}