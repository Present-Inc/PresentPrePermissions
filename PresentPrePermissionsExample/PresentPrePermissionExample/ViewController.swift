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
    @IBOutlet private var presentViewController: UIButton?
    
    var permissionsManager: PresentPrePermissions = PresentPrePermissions()
    
    private var completionHandler: PermissionCompletionHandler {
        return { granted, userResult, systemResult in
            println("Was access granted? \(granted)")
            println("\tPre-permission dialog: \(userResult.rawValue)")
            println("\tSystem dialog: \(systemResult.rawValue)")
        }
    }
    
    @IBAction func requestPhotoPermissionsPressed(_: AnyObject) {
        permissionsManager
            .showPhotoPermission(
                message: "Can I access your photos?",
                denyButtonTitle: "No",
                grantButtonTitle: "Sure",
                completion: self.completionHandler
            )
    }
    
    /**
        The message presented by the system location prompt is set in the Info.plist
     */
    @IBAction func requestLocationPermissionsPressed(_: AnyObject) {
        permissionsManager
            .showLocationPermission(
                message: "Can I access your location?",
                denyButtonTitle: "No",
                grantButtonTitle: "Sure",
                completion: self.completionHandler
            )
    }
    
    @IBAction func requestNotificationPermissionsPressed(_: AnyObject) {
        permissionsManager
            .showRemoteNotificationPermission(
                title: "Can I send you push notifications?",
                message: "I won't abuse it, scout's honor!",
                denyButtonTitle: "No",
                grantButtonTitle: "Yes",
                notificationTypes: (UIUserNotificationType.Badge | UIUserNotificationType.Alert | UIUserNotificationType.Sound)
            )
    }
    
    @IBAction func requestContactsPermissionPressed(_: AnyObject) {
        permissionsManager
            .showContactsPermission(
                message: "Can I access your contacts?",
                denyButtonTitle: "No",
                grantButtonTitle: "Yes",
                completion: self.completionHandler
            )
    }
    
    @IBAction func requestCameraPermissionsPressed(_: AnyObject) {
        permissionsManager
            .showCameraPermission(
                title: "Grant Camera Access?",
                message: "Can I access your camera?",
                denyButtonTitle: "No",
                grantButtonTitle: "Yes",
                completion: self.completionHandler
            )
    }
    
    @IBAction func requestMicrophonePermissionsPressed(_: AnyObject) {
        permissionsManager
            .showMicrophonePermission(
                title: "Grant Microphone Access?",
                message: "Can I access your microphone?",
                denyButtonTitle: "No",
                grantButtonTitle: "Yes",
                completion: self.completionHandler
            )
    }
    
    @IBAction func dismiss(_: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

