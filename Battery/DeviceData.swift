//
//  DeviceData.swift
//  Battery
//
//  Created by Steve Trease on 18/05/2016.
//  Copyright © 2016 Steve Trease. All rights reserved.
//

import Foundation



// A single, global instance of this class
var devices = [DeviceData]()

class DeviceData {
    var deviceName: String = ""
    var batteryLevel: Float = 0.0
    var batteryState: String = ""
    var timeStamp = NSDate()
}