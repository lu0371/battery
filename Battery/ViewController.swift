//
//  ViewController.swift
//  Battery
//
//  Created by Steve Trease on 10/06/2015.
//  Copyright © 2015 Steve Trease. All rights reserved.
//

import Foundation
import UIKit



class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var batteryLevelLabel: UILabel!
    @IBOutlet var chargeStatusLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("viewDidLoad")
    
        // set initial value
        batteryLevelChanged()
        
        // set to update labels on battery status change notifications (only works in foreground)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.batteryLevelChanged), name: UIDeviceBatteryLevelDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.batteryLevelChanged), name: UIDeviceBatteryStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.batteryLevelChanged), name: NSProcessInfoPowerStateDidChangeNotification, object: nil)

        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        _ = notificationCenter.addObserverForName("dataChanged", object:nil, queue: mainQueue) { _ in
            self.tableView.reloadData()
        }
        
        
        // run a background task every fifteen minutes to call batteryLevelChanged
        //
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        _ = NSTimer.scheduledTimerWithTimeInterval(15 * 60.09, target: self, selector: #selector(ViewController.batteryLevelChanged), userInfo: nil, repeats: true)
        
        // call batteryLevelChanged once per second when in foreground
        // _ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.batteryLevelChanged), userInfo: nil, repeats: true)

    }

    
    func batteryLevelChanged() {
        print ("batteryLevelChanged")
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let s = DeviceData ()
        s.batteryLevel = UIDevice.currentDevice().batteryLevel
        
        switch UIDevice.currentDevice().batteryState {
        case UIDeviceBatteryState.Unknown:
            s.batteryState = "Unknown"
        case UIDeviceBatteryState.Unplugged:
            s.batteryState = "Unplugged"
        case UIDeviceBatteryState.Charging:
            s.batteryState = "Charging"
        case UIDeviceBatteryState.Full:
            s.batteryState = "Full"
        }
        
        batteryLevelLabel.text = s.formattedBatteryLevel
        chargeStatusLabel.text = s.statusSymbol
        chargeStatusLabel.textColor = s.statusColor
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.trease.eu/battery/battery/")!)
        request.HTTPMethod = "POST"
        var bodyData = "&device=" + UIDevice.currentDevice().name
        bodyData += "&batterystate=" + s.batteryState
        bodyData += "&reason=changed"
        bodyData += "&uuid=" + myDeviceID
        bodyData += "&PushToken=" + myPushToken
        bodyData += "&batterylevel=\(UIDevice.currentDevice().batteryLevel)"
        request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            if let httpResponse = response as? NSHTTPURLResponse {
                print("http response \(httpResponse.statusCode)")
                
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    print ("++++ \(json.count)")
                    for jsonItem in json as! [Dictionary<String, AnyObject>] {
                        let device = DeviceData ()
                        
                        device.deviceName = jsonItem["deviceName"] as! String
                        device.batteryLevel = jsonItem["batteryLevel"] as! Float
                        device.batteryState = jsonItem["batteryState"] as! String
                        device.uuid = jsonItem["uuid"] as! String
                        device.timeStamp = NSDate(timeIntervalSince1970: (jsonItem["timeStamp"] as! Double))
                        
                        if devices.count > 0 {
                            var found = false
                            for var d in devices {
                                if d.uuid == device.uuid {
                                    found = true
                                    d.deviceName = device.deviceName
                                    d.batteryLevel = device.batteryLevel
                                    d.batteryState = device.batteryState
                                    d.uuid = device.uuid
                                    d.timeStamp = device.timeStamp
                                    print ("%")
                                }
                            }
                            if found == false {
                                devices.append(device)
                                print ("+")
                            }
                        } else {
                            devices.append(device)
                            print ("+")
                        }
                    }
                
                } catch let error as NSError {
                    print("JSON Serialization failed. Error: \(error)")
                }
                
            } else {
                print("error=\(error!.localizedDescription)")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            print ("JSON processing done")
            self.refreshUI()
        }
        task.resume()
    }
    
    override func didReceiveMemoryWarning() {
        print("didRecieveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // print ("cellForRowAtIndexPath \(indexPath.row)")
        let cell = tableView.dequeueReusableCellWithIdentifier("batteryCell", forIndexPath: indexPath) as! customTableViewCell
        
        if (cell.deviceName?.text != devices[indexPath.row].deviceName ||
            cell.batteryLevel?.text != devices[indexPath.row].formattedBatteryLevel ||
            cell.status?.text != devices[indexPath.row].statusSymbol ||
            cell.status?.textColor != devices[indexPath.row].statusColor) {
        
            cell.alpha = 1/3
            UIView.animateWithDuration(0.45, animations: {
                cell.alpha = 1.0
            })
        }
    
        cell.deviceName?.text = devices[indexPath.row].deviceName
        cell.batteryLevel?.text = devices[indexPath.row].formattedBatteryLevel
        cell.status?.text = devices[indexPath.row].statusSymbol
        cell.status?.textColor = devices[indexPath.row].statusColor

        return cell
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        print("screen resolution changed")
        refreshUI()
    }
    
    func refreshUI() {
        dispatch_async(dispatch_get_main_queue(),{
            self.tableView.reloadData()
        });
    }
  
}
