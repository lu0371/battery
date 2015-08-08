//
//  AppDelegate.swift
//  Battery
//
//  Created by Steve Trease on 10/06/2015.
//  Copyright © 2015 Steve Trease. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        switch (application.applicationState) {
        case UIApplicationState.Active:
            print ("didFinishLaunchingWithOptions - active")
        case UIApplicationState.Inactive:
            print ("didFinishLaunchingWithOptions - inactive")
        case UIApplicationState.Background:
            print ("didFinishLaunchingWithOptions - background")
        }
        
        // prompt to register for notitfications
        if(UIApplication.instancesRespondToSelector(Selector("registerUserNotificationSettings:"))) {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings (forTypes: UIUserNotificationType.None, categories: nil))
        }
        
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        // setup reoccuring local notification
        let localNotification1 = UILocalNotification()
        localNotification1.timeZone = NSTimeZone.defaultTimeZone()
        localNotification1.repeatInterval = NSCalendarUnit.Hour
        localNotification1.hasAction = false
        localNotification1.fireDate = NSDate(timeIntervalSinceNow: 15 * 60)
        localNotification1.alertTitle = "1"
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification1)

        let localNotification2 = UILocalNotification()
        localNotification2.timeZone = NSTimeZone.defaultTimeZone()
        localNotification2.repeatInterval = NSCalendarUnit.Hour
        localNotification2.hasAction = false
        localNotification2.fireDate = NSDate(timeIntervalSinceNow: 30 * 60)
        localNotification2.alertTitle = "2"
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification2)
        
        let localNotification3 = UILocalNotification()
        localNotification3.timeZone = NSTimeZone.defaultTimeZone()
        localNotification3.repeatInterval = NSCalendarUnit.Hour
        localNotification3.hasAction = false
        localNotification3.fireDate = NSDate(timeIntervalSinceNow: 45 * 60)
        localNotification3.alertTitle = "3"
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification3)
        
        let localNotification4 = UILocalNotification()
        localNotification4.timeZone = NSTimeZone.defaultTimeZone()
        localNotification4.repeatInterval = NSCalendarUnit.Hour
        localNotification4.hasAction = false
        localNotification4.fireDate = NSDate(timeIntervalSinceNow: 60 * 60)
        localNotification4.alertTitle = "4"
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification4)

        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        print ("\(notifications.count) notifications registered")
        

        UIDevice.currentDevice().batteryMonitoringEnabled = true

        return true
    }
    
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print ("didRecieveLocalNotification " + notification.alertTitle!)
        
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
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.trease.eu/ibeacon/battery/")!)
        request.HTTPMethod = "POST"
        var bodyData = "&device=\(UIDevice.currentDevice().name)"
        bodyData += "&batterystate=" + chargeStatus
        bodyData += "&batterylevel=\(UIDevice.currentDevice().batteryLevel)"
        request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            let x = response as? NSHTTPURLResponse
            print ("status code \(x?.statusCode)")
        }
        task.resume()
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

