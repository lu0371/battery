//
//  ViewController.swift
//  Battery
//
//  Created by Steve Trease on 10/06/2015.
//  Copyright © 2015 Steve Trease. All rights reserved.
//

import Foundation
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var batteryLevel: UILabel!
    @IBOutlet var chargeStatus: UILabel!
    @IBOutlet var powerState: UILabel!
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("starting")
        
        // set initial value
        batteryLevelChanged()
        
        // set to update labels on battery status change notifications (only works in foreground)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "batteryLevelChanged", name: UIDeviceBatteryLevelDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "batteryLevelChanged", name: UIDeviceBatteryStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "batteryLevelChanged", name: NSProcessInfoPowerStateDidChangeNotification, object: nil)

        
        // run a background task every fifteen minutes to call batteryLevelChanged
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        _ = NSTimer.scheduledTimerWithTimeInterval(15 * 60.09, target: self, selector: "batteryLevelChanged", userInfo: nil, repeats: true)
        
        // call batteryLevelChanged once per second when in foreground
        // _ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("batteryLevelChanged"), userInfo: nil, repeats: true)
    }
    
    func batteryLevelChanged() {
    
        let formatter =  NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        
        batteryLevel.text = formatter.stringFromNumber(UIDevice.currentDevice().batteryLevel)
        
        switch UIDevice.currentDevice().batteryState {
        case UIDeviceBatteryState.Unknown:
            chargeStatus.text = "Unknown"
        case UIDeviceBatteryState.Unplugged:
            chargeStatus.text = "Unplugged"
        case UIDeviceBatteryState.Charging:
            chargeStatus.text = "Charging"
        case UIDeviceBatteryState.Full:
            chargeStatus.text = "Full"
        }
        
        if NSProcessInfo.processInfo().lowPowerModeEnabled {
            // Low Power Mode is enabled. Start reducing activity to conserve energy.
            powerState.text = "Low power mode enabled"
        } else {
            // Low Power Mode is enabled. Start reducing activity to conserve energy.
            powerState.text = "Low power mode disabled"
        }
        
        
        print("battery status change: " + chargeStatus.text! + " " + batteryLevel.text!)

        let request = NSMutableURLRequest(URL: NSURL(string: "http://www.trease.eu/ibeacon/battery/")!)
        request.HTTPMethod = "POST"
        var bodyData = "&device=\(UIDevice.currentDevice().name)"
        bodyData += "&batterystate=" + chargeStatus.text!
        bodyData += "&batterylevel=" + batteryLevel.text!
        request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            let x = response as? NSHTTPURLResponse
            print ("status code \(x?.statusCode)")
        }
        task!.resume()
     }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

