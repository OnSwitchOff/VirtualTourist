//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 26.07.23.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataController.load()
        
        let navigationController = window!.rootViewController
        //let travelLocationViewController = navigationController.topViewController as! TravelLocationsMapViewController
        //travelLocationViewController.dataController = dataController
        return true
    }

    // MARK: UISceneSession Lifecycle

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveViewContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        saveViewContext()
    }
    
    func saveViewContext() {
        try? dataController.backgroundContext.save()
    }

}

