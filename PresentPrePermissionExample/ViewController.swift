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
    private var completionHandler: PermissionCompletionHandler {
        return { granted, userResult, systemResult in
            println("Was access granted? \(granted)")
            println("  Pre-permission dialog: \(userResult.toRaw())")
            println("  System dialog: \(systemResult.toRaw())")
        }
    }
    
    @IBAction func requestPhotoPermissionsPressed(_: AnyObject) {
        PresentPrePermissions
            .sharedPermissions()
            .showPhotoPermission(
                message: "Can I access your photos?",
                denyButtonTitle: "No",
                grantButtonTitle: "Sure",
                completion: self.completionHandler
            )
    }
    
    @IBAction func requestLocationPermissionsPressed(_: AnyObject) {
        PresentPrePermissions
            .sharedPermissions()
            .showLocationPermission(
                message: "Can I access your location?",
                denyButtonTitle: "No",
                grantButtonTitle: "Sure",
                completion: self.completionHandler
            )
    }
    
    @IBAction func requestNotificationPermissionsPressed(_: AnyObject) {
        PresentPrePermissions
            .sharedPermissions()
            .showRemoteNotificationPermission(
                title: "Can I send you push notifications?",
                message: "I won't abuse it, scout's honor!",
                denyButtonTitle: "No",
                grantButtonTitle: "Yes",
                completion: self.completionHandler
            )
    }
    
    @IBAction func requestContactsPermissionPressed(_: AnyObject) {
        PresentPrePermissions
            .sharedPermissions()
            .showContactsPermission(
                message: "Can I access your contacts?",
                denyButtonTitle: "No",
                grantButtonTitle: "Yes",
                completion: self.completionHandler
            )
    }
}

