//
//  DeviceData.swift
//  Battery
//
//  Created by Steve Trease on 18/05/2016.
//  Copyright © 2016 Steve Trease. All rights reserved.
//

import Foundation
import UIKit



// A single, global instance of this class
var devices = [DeviceData]()

class DeviceData {
    var uuid: String = ""
    var deviceName: String = ""
    var batteryLevel: Float = 0.0
    var batteryState: String = ""
    var timeStamp = NSDate()
    
    var statusSymbol: String {
        get {
            switch (batteryLevel * 100) {
            case 0..<5:
                return "\u{f244}"     // battery-empty
            case 5..<35:
                return "\u{f243}"     // battery-quarter
            case 35..<65:
                return "\u{f242}"     // battery-half
            case 65..<95:
                return "\u{f241}"     // battery-three-quarters
            case 95...100:
                return "\u{f240}"     // battery-full
            case -100:
                return "\u{f0e7}"     // in simualtor
            default:
                return "."
            }
        }
    }
    var statusColor: UIColor {
        get {
            switch UIDevice.currentDevice().batteryState {
            case UIDeviceBatteryState.Unknown:
                return UIColor.blackColor()
            case UIDeviceBatteryState.Unplugged:
                return  UIColor.grayColor()
            case UIDeviceBatteryState.Charging:
                return UIColor.orangeColor()
            case UIDeviceBatteryState.Full:
                return UIColor.greenColor()
            }
        }
    }
    var formattedBatteryLevel: String {
        let formatter =  NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        return formatter.stringFromNumber(batteryLevel)!
    }
}