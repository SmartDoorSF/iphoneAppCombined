//
//  ViewController.swift
//  2in1V1
//
//  Created by Ryan Jones on 4/24/16.
//  Copyright © 2016 Ryan Jones. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController, CLLocationManagerDelegate, CBPeripheralManagerDelegate {

    @IBOutlet weak var incomingUUID: UILabel!
    @IBOutlet weak var incomingMajor: UILabel!
    @IBOutlet weak var incomingMinor: UILabel!
    @IBOutlet weak var incomingRSSI: UILabel!
    @IBOutlet weak var transmitting: UILabel!
    @IBOutlet weak var outgoingUUID: UILabel!
    @IBOutlet weak var outgoingMajor: UILabel!
    @IBOutlet weak var outgoingMinor: UILabel!
    
    let locationManager = CLLocationManager()
    let region = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!, identifier: "MySmartDoor")
    
    var localBeacon: CLBeaconRegion!
    var beaconPeripheralData: NSDictionary!
    var peripheralManager: CBPeripheralManager!
    var isBroadcasting = false
    var needToWait = false
    var beaconTimer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self;
        locationManager.startRangingBeaconsInRegion(region)
        locationManager.requestAlwaysAuthorization()
    }

    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        if beacons.count != 0 {
            let beacon = beacons[0]
            updateInterface(beacons)
            print("beacon ID", beacon.proximityUUID)
            print("isBroadcasting", isBroadcasting)
            
            if beacon.proximityUUID == self.region.proximityUUID && !isBroadcasting && !needToWait {
                transmitBeacon()
                print("trying to transmit")
            }
//            if beacon.proximityUUID != self.region.proximityUUID && isBroadcasting {
//                stopLocalBeacon()
//                self.needToWait = false
//                print("trying to turn off")
//            }
            if beacon.rssi > -60 {
                print("ran cycle")
                runThroughCycle(2)
                beaconTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(ViewController.resetBeacon), userInfo: nil, repeats: false)
            }
        }
//        if beacons.count == 0 && isBroadcasting {
//            stopLocalBeacon()
//            needToWait = false
//            print("trying to turn off")
//        }
    }
    
    func updateInterface(beacons: [CLBeacon]){
        let newBeacon = beacons[0]
        self.incomingUUID.text = "\(newBeacon.proximityUUID)"
        self.incomingMajor.text = "\(newBeacon.major)"
        self.incomingMinor.text = "\(newBeacon.minor)"
        self.incomingRSSI.text = "\(newBeacon.rssi)"
        
    }

    func initLocalBeacon(minorNum : Int) {
        if localBeacon != nil {
            stopLocalBeacon()
        }
        
        print("initializing")
        let localBeaconUUID = "66dae67d-22e2-466b-b7d6-7093d52ceeb7"
        let localBeaconMajor: CLBeaconMajorValue = 8127
        let localBeaconMinor: CLBeaconMinorValue = UInt16(minorNum)
        
        let uuid = NSUUID(UUIDString: localBeaconUUID)!
        localBeacon = CLBeaconRegion(proximityUUID: uuid, major: localBeaconMajor, minor: localBeaconMinor, identifier: "MySmartDoor")
        isBroadcasting = true
        beaconPeripheralData = localBeacon.peripheralDataWithMeasuredPower(nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        
    }
    
    func stopLocalBeacon() {
        needToWait = true
        isBroadcasting = false
        peripheralManager.stopAdvertising()
        peripheralManager = nil
        beaconPeripheralData = nil
        localBeacon = nil
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if peripheral.state == .PoweredOn {
            peripheralManager.startAdvertising(beaconPeripheralData as! [String: AnyObject]!)
            transmitting.text = "Yes!"
        } else if peripheral.state == .PoweredOff {
            peripheralManager.stopAdvertising()
            transmitting.text = "No"
        }
    }
    
    func updateOutgoingInterface(minorNum: Int){
        
        let localBeaconUUID = "66dae67d-22e2-466b-b7d6-7093d52ceeb7"
        let localBeaconMajor: CLBeaconMajorValue = 8127
        let localBeaconMinor: CLBeaconMinorValue = UInt16(minorNum)
        
        self.outgoingUUID.text = "\(localBeaconUUID)"
        self.outgoingMajor.text = "\(localBeaconMajor)"
        self.outgoingMinor.text = "\(localBeaconMinor)"
    }
    
    func runThroughCycle(minorNum : Int) {
        stopLocalBeacon()
        initLocalBeacon(minorNum)
        isBroadcasting = true
        updateOutgoingInterface(minorNum)
    }
    
    func resetBeacon(){
        runThroughCycle(1)
    }
    
    func transmitBeacon() {
        if !isBroadcasting {
            initLocalBeacon(1)
            isBroadcasting = true
            updateOutgoingInterface(1)
        }
        else {
            stopLocalBeacon()
            isBroadcasting = false
        }
    }

    @IBAction func unlock(sender: AnyObject) {
        runThroughCycle(2)
        beaconTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(ViewController.resetBeacon), userInfo: nil, repeats: false)
    }
}

