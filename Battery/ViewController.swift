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
    
    @IBOutlet var batteryLevelButton: UIButton!
    @IBOutlet var chargeStatusLabel: UILabel!
    @IBOutlet var powerStateLabel: UILabel!
    @IBOutlet var networkStatusLabel: UILabel!
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("viewDidLoad")
        
        // set initial value
        batteryLevelChanged()
        
        // set to update labels on battery status change notifications (only works in foreground)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "batteryLevelChanged", name: UIDeviceBatteryLevelDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "batteryLevelChanged", name: UIDeviceBatteryStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "batteryLevelChanged", name: NSProcessInfoPowerStateDidChangeNotification, object: nil)

        
        // run a background task every fifteen minutes to call batteryLevelChanged
        //
        // backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
             // UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        // })
        _ = NSTimer.scheduledTimerWithTimeInterval(15 * 60.09, target: self, selector: "batteryLevelChanged", userInfo: nil, repeats: true)
        
        // call batteryLevelChanged once per second when in foreground
        // _ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("batteryLevelChanged"), userInfo: nil, repeats: true)
    }
    
    func batteryLevelChanged() {
        print ("batteryLevelChanged")
        
        networkStatusLabel.text = "updating"
        self.networkStatusLabel.hidden = false
    
        let formatter =  NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        batteryLevelButton.setTitle(formatter.stringFromNumber(UIDevice.currentDevice().batteryLevel), forState: .Normal)
        
        switch UIDevice.currentDevice().batteryState {
        case UIDeviceBatteryState.Unknown:
            chargeStatusLabel.text = "Unknown"
        case UIDeviceBatteryState.Unplugged:
            chargeStatusLabel.text = "Unplugged"
        case UIDeviceBatteryState.Charging:
            chargeStatusLabel.text = "Charging"
        case UIDeviceBatteryState.Full:
            chargeStatusLabel.text = "Full"
        }
        
        if NSProcessInfo.processInfo().lowPowerModeEnabled {
            // Low Power Mode is enabled. Start reducing activity to conserve energy.
            powerStateLabel.text = "Low power mode enabled"
            powerStateLabel.hidden = false
        } else {
            // Low Power Mode is enabled. Start reducing activity to conserve energy.
            powerStateLabel.text = "Low power mode disabled"
            powerStateLabel.hidden = true
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.trease.eu/ibeacon/battery/")!)
        request.HTTPMethod = "POST"
        var bodyData = "&device=\(UIDevice.currentDevice().name)"
        bodyData += "&batterystate=" + chargeStatusLabel.text!
        bodyData += "&reason=changed" 
        bodyData += "&batterylevel=\(UIDevice.currentDevice().batteryLevel)"
        request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            if let httpResponse = response as? NSHTTPURLResponse {
                print("http response \(httpResponse.statusCode)")
                self.networkStatusLabel.hidden = false
                self.networkStatusLabel.text = "\(httpResponse.statusCode)"
                if httpResponse.statusCode == 200 {
                        self.networkStatusLabel.hidden = true
                } else {
                        self.networkStatusLabel.hidden = false
                }
            }
        }
        task.resume()
    }
    
    @IBAction func refreshButton(sender: AnyObject) {
        print("refresh button pressed")
        batteryLevelChanged()
    }


    override func didReceiveMemoryWarning() {
        print("didRecieveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}