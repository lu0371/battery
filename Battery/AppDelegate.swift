//
//  AppDelegate.swift
//  Battery
//
//  Created by Steve Trease on 10/06/2015.
//  Copyright © 2015 Steve Trease. All rights reserved.
//

import UIKit


let myDeviceID: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
var myPushToken: String = "init"


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let versionNumber: AnyObject? = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"]
        print ("version \(versionNumber!)")
        
        switch (application.applicationState) {
        case UIApplicationState.Active:
            print ("didFinishLaunchingWithOptions - active")
        case UIApplicationState.Inactive:
            print ("didFinishLaunchingWithOptions - inactive")
        case UIApplicationState.Background:
            print ("didFinishLaunchingWithOptions - background")
        }

        // register for notifications
        let types: UIUserNotificationType =
        [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
        let settings: UIUserNotificationSettings = UIUserNotificationSettings( forTypes: types, categories: nil )
        application.registerUserNotificationSettings( settings )
        application.registerForRemoteNotifications()
        
        // UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        // every 5 minutes
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(5 * 60)
        
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        
        return true
    }
    
    // Support for background fetch
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print ("performFetchWithCompletionHandler")
        
        let formatter =  NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        
        let batteryLevel = formatter.stringFromNumber(UIDevice.currentDevice().batteryLevel)
        var chargeStatus = ""
        
        switch UIDevice.currentDevice().batteryState {
        case UIDeviceBatteryState.Unknown:
            chargeStatus = "Unknown"
        case UIDeviceBatteryState.Unplugged:
            chargeStatus = "Unplugged"
        case UIDeviceBatteryState.Charging:
            chargeStatus = "Charging"
        case UIDeviceBatteryState.Full:
            chargeStatus = "Full"
        }
        
        print(chargeStatus + " " + batteryLevel!)
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.trease.eu/battery/battery/")!)
        request.HTTPMethod = "POST"
        var bodyData = "&device=" + UIDevice.currentDevice().name
        bodyData += "&batterystate=" + chargeStatus
        bodyData += "&reason=background"
        bodyData += "&uuid=" + myDeviceID
        bodyData += "&PushToken=" + myPushToken
        bodyData += "&batterylevel=\(UIDevice.currentDevice().batteryLevel)"
        request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            let x = response as? NSHTTPURLResponse
            print ("status code \(x?.statusCode)")
        }
        task.resume()
        
        completionHandler(.NewData)
    }
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken:NSData) {
        // let existingToken: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("deviceToken")
        print("device token is " + deviceToken.description)
        myPushToken = deviceToken.description;
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error:NSError) {
        print("Failed to register device token")
        myPushToken = "no push token"
        print( error.localizedDescription )
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        switch (application.applicationState) {
        case UIApplicationState.Active:
            print ("notification received by AppDeligate whilst active")
        case UIApplicationState.Inactive:
            print ("notification received by AppDeligate whilst inactive")
        case UIApplicationState.Background:
            print ("notification received by AppDeligate whilst in background")
        }
        print ("______")
        print (userInfo)
        print ("______")
        
        let payloadString: String
        if let payload = userInfo["payload"] as? String {
            payloadString = payload
            print (payloadString)
            
            do {
                let data = payloadString.dataUsingEncoding(NSUTF8StringEncoding)
                let json = try NSJSONSerialization.JSONObjectWithData(data! , options: .AllowFragments)
                print ("****\(json.count)")
                for jsonItem in json as! [Dictionary<String, AnyObject>] {
                    print(".")
                    
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
            let center = NSNotificationCenter.defaultCenter()
            center.postNotificationName("dataChanged", object: self)
            print ("JSON processing done")
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

