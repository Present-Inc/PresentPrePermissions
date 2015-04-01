//
//  ViewController.swift
//  PresentPrePermissionExample
//
//  Created by Justin Makaila on 9/29/14.
//  Copyright (c) 2014 Justin Makaila. All rights reserved.
//

import UIKit
import PresentPrePermissions

class ViewController: UIViewController {
    var permissionsManager = PresentPrePermissions()

    @IBOutlet private var presentViewController: UIButton?
    
    private var completionHandler: PermissionCompletionHandler {
        return { granted, userResult, systemResult in
            println("Was access granted? \(granted)")
            println("\tPre-permission dialog: \(userResult.rawValue)")
            println("\tSystem dialog: \(systemResult.rawValue)")
        }
    }
    
    @IBAction func requestPhotoPermissionsPressed(_: AnyObject) {
        permissionsManager
            .showPhotoPermission(completion: completionHandler)
    }
    
    @IBAction func requestLocationPermissionsPressed(_: AnyObject) {
        permissionsManager
            .showLocationPermission(
                authorizationType: .Always,
                completion: completionHandler
            )
    }
    
    @IBAction func requestNotificationPermissionsPressed(_: AnyObject) {
        permissionsManager
            .showRemoteNotificationPermission(
                notificationTypes: (UIUserNotificationType.Badge | UIUserNotificationType.Alert | UIUserNotificationType.Sound)
            )
    }
    
    @IBAction func requestContactsPermissionPressed(_: AnyObject) {
        permissionsManager
            .showContactsPermission(
                completion: completionHandler
            )
    }
    
    @IBAction func requestCameraPermissionsPressed(_: AnyObject) {
        permissionsManager
            .showCameraPermission(
                completion: completionHandler
            )
    }
    
    @IBAction func requestMicrophonePermissionsPressed(_: AnyObject) {
        permissionsManager
            .showMicrophonePermission(
                completion: completionHandler
            )
    }
    
    @IBAction func dismiss(_: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

