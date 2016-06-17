//
//  AppDelegate.swift
//  Battery
//
//  Created by Steve Trease on 10/06/2015.
//  Copyright © 2015 Steve Trease. All rights reserved.
//

import UIKit


let myDeviceID: String = UIDevice.current().identifierForVendor!.uuidString
var myPushToken: String = "init"


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let versionNumber: AnyObject? = Bundle.main().infoDictionary?["CFBundleVersion"]
        print ("version \(versionNumber!)")
        
        switch (application.applicationState) {
        case UIApplicationState.active:
            print ("didFinishLaunchingWithOptions - active")
        case UIApplicationState.inactive:
            print ("didFinishLaunchingWithOptions - inactive")
        case UIApplicationState.background:
            print ("didFinishLaunchingWithOptions - background")
        }

        // register for notifications
        let types: UIUserNotificationType =
        [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
        let settings: UIUserNotificationSettings = UIUserNotificationSettings( types: types, categories: nil )
        application.registerUserNotificationSettings( settings )
        application.registerForRemoteNotifications()
        
        // UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        // every 5 minutes
        UIApplication.shared().setMinimumBackgroundFetchInterval(5 * 60)
        
        UIDevice.current().isBatteryMonitoringEnabled = true
        
        return true
    }
    
    // Support for background fetch
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print ("performFetchWithCompletionHandler")
        
        let formatter =  NumberFormatter()
        formatter.numberStyle = .percent
        
        let batteryLevel = formatter.string(from: UIDevice.current().batteryLevel)
        var chargeStatus = ""
        
        switch UIDevice.current().batteryState {
        case UIDeviceBatteryState.unknown:
            chargeStatus = "Unknown"
        case UIDeviceBatteryState.unplugged:
            chargeStatus = "Unplugged"
        case UIDeviceBatteryState.charging:
            chargeStatus = "Charging"
        case UIDeviceBatteryState.full:
            chargeStatus = "Full"
        }
        
        print(chargeStatus + " " + batteryLevel!)
        
        let request = NSMutableURLRequest(url: URL(string: "https://www.trease.eu/battery/battery/")!)
        request.httpMethod = "POST"
        var bodyData = "&device=" + UIDevice.current().name
        bodyData += "&batterystate=" + chargeStatus
        bodyData += "&reason=background"
        bodyData += "&uuid=" + myDeviceID
        bodyData += "&PushToken=" + myPushToken
        bodyData += "&batterylevel=\(UIDevice.current().batteryLevel)"
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared().dataTask(with: request as URLRequest) {
            data, response, error in
            
            let x = response as? HTTPURLResponse
            print ("status code \(x?.statusCode)")
        }
        task.resume()
        
        completionHandler(.newData)
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken:Data) {
        // let existingToken: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("deviceToken")
        print("device token is " + deviceToken.description)
        myPushToken = deviceToken.description;
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error:NSError) {
        print("Failed to register device token")
        myPushToken = "no push token"
        print( error.localizedDescription )
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        switch (application.applicationState) {
        case UIApplicationState.active:
            print ("notification received by AppDeligate whilst active")
        case UIApplicationState.inactive:
            print ("notification received by AppDeligate whilst inactive")
        case UIApplicationState.background:
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
                let data = payloadString.data(using: String.Encoding.utf8)
                let json = try JSONSerialization.jsonObject(with: data! , options: .allowFragments)
                print ("****\(json.count)")
                for jsonItem in json as! [Dictionary<String, AnyObject>] {
                    print(".")
                    
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
            let center = NotificationCenter.default()
            center.post(name: Notification.Name(rawValue: "dataChanged"), object: self)
            print ("JSON processing done")
        }

        completionHandler(UIBackgroundFetchResult.newData)
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

