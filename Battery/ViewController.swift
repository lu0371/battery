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
        NotificationCenter.default().addObserver(self, selector: #selector(ViewController.batteryLevelChanged), name: NSNotification.Name.UIDeviceBatteryLevelDidChange, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(ViewController.batteryLevelChanged), name: NSNotification.Name.UIDeviceBatteryStateDidChange, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(ViewController.batteryLevelChanged), name: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil)

        
        let notificationCenter = NotificationCenter.default()
        let mainQueue = OperationQueue.main()
        _ = notificationCenter.addObserver(forName: "dataChanged" as NSNotification.Name, object:nil, queue: mainQueue) { _ in
            self.tableView.reloadData()
        }
        
        
        // run a background task every fifteen minutes to call batteryLevelChanged
        //
        backgroundTaskIdentifier = UIApplication.shared().beginBackgroundTask(expirationHandler: {
            UIApplication.shared().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        _ = Timer.scheduledTimer(timeInterval: 15 * 60.09, target: self, selector: #selector(ViewController.batteryLevelChanged), userInfo: nil, repeats: true)
        
        // call batteryLevelChanged once per second when in foreground
        // _ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.batteryLevelChanged), userInfo: nil, repeats: true)

    }

    
    func batteryLevelChanged() {
        print ("batteryLevelChanged")
        
        UIApplication.shared().isNetworkActivityIndicatorVisible = true

        let s = DeviceData ()
        s.batteryLevel = UIDevice.current().batteryLevel
        
        switch UIDevice.current().batteryState {
        case UIDeviceBatteryState.unknown:
            s.batteryState = "Unknown"
        case UIDeviceBatteryState.unplugged:
            s.batteryState = "Unplugged"
        case UIDeviceBatteryState.charging:
            s.batteryState = "Charging"
        case UIDeviceBatteryState.full:
            s.batteryState = "Full"
        }
        
        batteryLevelLabel.text = s.formattedBatteryLevel
        chargeStatusLabel.text = s.statusSymbol
        chargeStatusLabel.textColor = s.statusColor
        
        let request = NSMutableURLRequest(url: URL(string: "https://www.trease.eu/battery/battery/")!)
        request.httpMethod = "POST"
        var bodyData = "&device=" + UIDevice.current().name
        bodyData += "&batterystate=" + s.batteryState
        bodyData += "&reason=changed"
        bodyData += "&uuid=" + myDeviceID
        bodyData += "&PushToken=" + myPushToken
        bodyData += "&batterylevel=\(UIDevice.current().batteryLevel)"
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared().dataTask(with: request as URLRequest) {
            data, response, error in
            UIApplication.shared().isNetworkActivityIndicatorVisible = true
            if let httpResponse = response as? HTTPURLResponse {
                print("http response \(httpResponse.statusCode)")
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    print ("++++ \(json.count)")
                    for jsonItem in json as! [Dictionary<String, AnyObject>] {
                        let device = DeviceData ()
                        
                        device.deviceName = jsonItem["deviceName"] as! String
                        device.batteryLevel = jsonItem["batteryLevel"] as! Float
                        device.batteryState = jsonItem["batteryState"] as! String
                        device.uuid = jsonItem["uuid"] as! String
                        device.timeStamp = Date(timeIntervalSince1970: (jsonItem["timeStamp"] as! Double))
                        
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
            UIApplication.shared().isNetworkActivityIndicatorVisible = false
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // print ("cellForRowAtIndexPath \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "batteryCell", for: indexPath) as! customTableViewCell
        
        if (cell.deviceName?.text != devices[(indexPath as NSIndexPath).row].deviceName ||
            cell.batteryLevel?.text != devices[(indexPath as NSIndexPath).row].formattedBatteryLevel ||
            cell.status?.text != devices[(indexPath as NSIndexPath).row].statusSymbol ||
            cell.status?.textColor != devices[(indexPath as NSIndexPath).row].statusColor) {
        
            cell.deviceName?.alpha = 1/3
            cell.batteryLevel?.alpha = 1/3
            cell.status?.alpha = 1/3
            UIView.animate(withDuration: 0.4, animations: {
                cell.deviceName?.alpha = 1
                cell.batteryLevel?.alpha = 1
                cell.status?.alpha = 1
            })
        }
    
        cell.deviceName?.text = devices[(indexPath as NSIndexPath).row].deviceName
        cell.batteryLevel?.text = devices[(indexPath as NSIndexPath).row].formattedBatteryLevel
        cell.status?.text = devices[(indexPath as NSIndexPath).row].statusSymbol
        cell.status?.textColor = devices[(indexPath as NSIndexPath).row].statusColor

        return cell
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("screen resolution changed")
        refreshUI()
    }
    
    func refreshUI() {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        });
    }
  
}
