//
//  SceneDelegate.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 26.07.23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    let dataController = DataController(modelName: "VirtualTourist")

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        dataController.load()
        
        let navigationController = window?.rootViewController as! UINavigationController
        let travelLocationViewController = navigationController.topViewController as! TravelLocationsMapViewController
        travelLocationViewController.dataController = dataController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        saveViewContext()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        saveViewContext()
    }

    func saveViewContext() {
        try? dataController.backgroundContext.save()
    }
}

