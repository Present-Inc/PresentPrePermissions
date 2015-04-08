//
//  PresentPrePermissions.swift
//  PresentPrePermissions
//
//  Created by Justin Makaila on 9/29/14.
//  Copyright (c) 2014 Justin Makaila. All rights reserved.
//

import CoreLocation
import AddressBook
import AssetsLibrary
import AVFoundation

public enum PresentDialogResult: String {
    case NoAction = "No Action"
    case Denied = "Denied"
    case Granted = "Granted"
    // iOS parental permissions prevented access. Typically only for system dialog.
    case Restricted = "Restricted"
}

public enum PresentLocationAuthorizationType {
    case WhenInUse
    case Always
}

public typealias PermissionCompletionHandler = (granted: Bool, userDialogResult: PresentDialogResult, systemDialogResult: PresentDialogResult) -> ()

private enum PresentTitleType {
    case Request
    case Deny
}

private enum PermissionsType {
    case Photos
    case Contacts
    case Location
    case PushNotifications
    case Microphone
    case Camera
}

private let kDenyButtonTitle = "Not Now"
private let kGrantButtonTitle = "Grant Access"

public class PresentPrePermissions: NSObject {
    private var locationManager: CLLocationManager?
    private var locationCompletionHandler: PermissionCompletionHandler?
    private var appName: String? {
        return NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String
    }
    
    public class func sharedPermissions() -> PresentPrePermissions {
        struct Static {
            static let instance = PresentPrePermissions()
        }
        
        return Static.instance
    }

    public func showPhotoPermission(title: String? = nil, message: String? = nil, denyButtonTitle: String? = kDenyButtonTitle, grantButtonTitle: String? = kGrantButtonTitle, completion: PermissionCompletionHandler?) {
        let authorizationStatus = ALAssetsLibrary.authorizationStatus()
        
        if authorizationStatus == ALAuthorizationStatus.NotDetermined {
            showAlertView(
                title ?? titleForPermission(.Photos),
                message: message ?? messageForPermission(.Photos),
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    self.firePhotoCompletionHandler(completion)
                },
                grantAction: {
                    self.showPhotoPermissionSystemAlert(completion)
                }
            )
        } else {
            completion?(granted: PresentPrePermissions.photoAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    public func showContactsPermission(title: String? = nil, message: String? = nil, denyButtonTitle: String? = kDenyButtonTitle, grantButtonTitle: String? = kGrantButtonTitle, completion: PermissionCompletionHandler?) {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        
        if authorizationStatus == ABAuthorizationStatus.NotDetermined {
            self.showAlertView(
                title ?? titleForPermission(.Contacts),
                message: message ?? messageForPermission(.Contacts),
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    self.fireContactsPermissionCompletionHandler(completion)
                },
                grantAction: {
                    self.showContactsPermissionSystemAlert(completion)
                }
            )
        } else {
            completion?(granted: PresentPrePermissions.contactsAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    /*
        This requires that the NSLocationWhenInUseUsageDescription key is set in the Info.plist of your application.
     */
    public func showLocationPermission(title: String? = nil, message: String? = nil, denyButtonTitle: String? = kDenyButtonTitle, grantButtonTitle: String? = kGrantButtonTitle, authorizationType: PresentLocationAuthorizationType? = .WhenInUse, completion: PermissionCompletionHandler?) {
        self.locationCompletionHandler = completion
        
        var authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == CLAuthorizationStatus.NotDetermined {
            self.showAlertView(
                title ?? titleForPermission(.Location),
                message: message ?? messageForPermission(.Location),
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    self.fireLocationCompletionHandler()
                },
                grantAction: {
                    self.showLocationPermissionSystemAlert(authorizationType!)
                }
            )
        } else {
            completion?(granted: PresentPrePermissions.locationAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    /*
        The completion handler will only be called if notifications are already enabled. application:didRegisterForRemoteNotificationsWithDeviceToken: and 
        application:didFailToRegisterForRemoteNotificationsWithError: should be used as completion for granting access.
     */
    public func showRemoteNotificationPermission(title: String? = nil, message: String? = nil, denyButtonTitle: String? = kDenyButtonTitle, var grantButtonTitle: String? = kGrantButtonTitle, notificationTypes: UIUserNotificationType? = nil) {
        if !PresentPrePermissions.remoteNotificationsEnabled() {
            showAlertView(
                title ?? titleForPermission(.PushNotifications),
                message: message ?? messageForPermission(.PushNotifications),
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    let application = UIApplication.sharedApplication()
                    let delegate = application.delegate
                    
                    let error = NSError(domain: "PresentPrePermissionsErrorDomain", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "User denied push notifications prompt via PresentPrePermissions."
                    ])
                    
                    delegate?.application?(application, didFailToRegisterForRemoteNotificationsWithError: error)
                },
                grantAction: {
                    self.showRemoteNotificationSystemAlert(notificationTypes ?? (.Badge | .Alert | .Sound))
                }
            )
        }
    }
    
    public func showCameraPermission(title: String? = nil, message: String? = nil, denyButtonTitle: String? = kDenyButtonTitle, var grantButtonTitle: String? = kGrantButtonTitle, completion: PermissionCompletionHandler?) {
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if authorizationStatus == AVAuthorizationStatus.NotDetermined {
            showAlertView(
                title ?? titleForPermission(.Camera),
                message: message ?? messageForPermission(.Camera),
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    self.fireCameraCompletionHandler(completion)
                },
                grantAction: {
                    self.showCameraSystemAlert(completion)
                })
        } else {
            completion?(granted: PresentPrePermissions.cameraAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    public func showMicrophonePermission(title: String? = nil, message: String? = nil, denyButtonTitle: String? = kDenyButtonTitle, grantButtonTitle: String? = kGrantButtonTitle, completion: PermissionCompletionHandler?) {
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        if authorizationStatus == AVAuthorizationStatus.NotDetermined {
            showAlertView(
                title ?? titleForPermission(.Microphone),
                message: message ?? messageForPermission(.Microphone),
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    println("Fire the microphone completion handler")
                    self.fireMicrophoneCompletionHandler(completion)
                },
                grantAction: {
                    println("Show the microphone system alert")
                    self.showMicrophoneSystemAlert(completion)
                })
        } else {
            completion?(granted: PresentPrePermissions.microphoneAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    public func showCameraAndMicrophonePermission(title: String? = nil, message: String? = nil, denyButtonTitle: String? = kDenyButtonTitle, grantButtonTitle: String? = kGrantButtonTitle, completion: PermissionCompletionHandler?) {
        
        let cameraStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        let microphoneStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        
        let cameraCompletionHandler: PermissionCompletionHandler = { granted, userDialogResult, systemDialogResult in
            self.showMicrophoneSystemAlert(completion)
        }
        
        showCameraSystemAlert(cameraCompletionHandler)
    }
}

public extension PresentPrePermissions {
    public class var photoAccessGranted: Bool {
        return ALAssetsLibrary.authorizationStatus() == ALAuthorizationStatus.Authorized
    }
    
    public class var contactsAccessGranted: Bool {
        return ABAddressBookGetAuthorizationStatus() == ABAuthorizationStatus.Authorized
    }
    
    public class var locationAccessGranted: Bool {
        let status = CLLocationManager.authorizationStatus()
        
        return (status == CLAuthorizationStatus.AuthorizedAlways || status == CLAuthorizationStatus.AuthorizedWhenInUse)
    }
    
    public class var remoteNotificationAccessGranted: Bool {
        return remoteNotificationsEnabled()
    }
    
    public class var cameraAccessGranted: Bool {
        return AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Authorized
    }
    
    public class var microphoneAccessGranted: Bool {
        return AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio) == AVAuthorizationStatus.Authorized
    }
}

// MARK: - Photos
private extension PresentPrePermissions {
    func showPhotoPermissionSystemAlert(completion: PermissionCompletionHandler?) {
        ALAssetsLibrary().enumerateGroupsWithTypes(Int(ALAssetsGroupSavedPhotos), usingBlock: { group, stop in
            self.firePhotoCompletionHandler(completion)
            stop.memory = true
        },
        failureBlock: { error in
            self.firePhotoCompletionHandler(completion)
        })
    }
    
    func firePhotoCompletionHandler(completion: PermissionCompletionHandler?) {
        switch ALAssetsLibrary.authorizationStatus() {
        case .NotDetermined:
            completion?(granted: false, userDialogResult: .Denied, systemDialogResult: .NoAction)
        case .Authorized:
            completion?(granted: true, userDialogResult: .Granted, systemDialogResult: .Granted)
        case .Denied:
            completion?(granted: false, userDialogResult: .Granted, systemDialogResult: .Denied)
        case .Restricted:
            completion?(granted: false, userDialogResult: .Granted, systemDialogResult: .Restricted)
        }
    }
}

// MARK: - Location
private extension PresentPrePermissions {
    func showLocationPermissionSystemAlert(authorizationType: PresentLocationAuthorizationType) {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        switch authorizationType {
        case .Always:
            locationManager?.requestAlwaysAuthorization()
        case .WhenInUse:
            locationManager?.requestWhenInUseAuthorization()
        }
        
        locationManager?.startUpdatingLocation()
    }
    
    func fireLocationCompletionHandler() {
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            locationCompletionHandler?(granted: true, userDialogResult: .Granted, systemDialogResult: .Granted)
        case .Denied:
            locationCompletionHandler?(granted: false, userDialogResult: .Granted, systemDialogResult: .Denied)
        case .Restricted:
            locationCompletionHandler?(granted: false, userDialogResult: .Granted, systemDialogResult: .Restricted)
        case .NotDetermined:
            locationCompletionHandler?(granted: false, userDialogResult: .Denied, systemDialogResult: .NoAction)
        }
        
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
}

// MARK: Location Manager Delegate
extension PresentPrePermissions: CLLocationManagerDelegate {
    public func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .NotDetermined {
            fireLocationCompletionHandler()
        }
    }
}

// MARK: - Contacts
private extension PresentPrePermissions {
    func showContactsPermissionSystemAlert(completion: PermissionCompletionHandler?) {
        var error: Unmanaged<CFError>? = nil
        var addressBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
        ABAddressBookRequestAccessWithCompletion(addressBook, { granted, error in
            dispatch_async(dispatch_get_main_queue(), {
                self.fireContactsPermissionCompletionHandler(completion)
            })
        })
    }
    
    func fireContactsPermissionCompletionHandler(completion: PermissionCompletionHandler?) {
        switch ABAddressBookGetAuthorizationStatus() {
        case .NotDetermined:
            completion?(granted: false, userDialogResult: .Denied, systemDialogResult: .NoAction)
        case .Authorized:
            completion?(granted: true, userDialogResult: .Granted, systemDialogResult: .Granted)
        case .Denied:
            completion?(granted: false, userDialogResult: .Granted, systemDialogResult: .Denied)
        case .Restricted:
            completion?(granted: false, userDialogResult: .Granted, systemDialogResult: .Restricted)
        }
    }
}

// MARK: - Notifications
private extension PresentPrePermissions {
    func showRemoteNotificationSystemAlert(notificationType: UIUserNotificationType) {
        let application = UIApplication.sharedApplication()
        let settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: notificationType, categories: nil)
        
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    class func remoteNotificationTypes() -> UIUserNotificationType {
        return UIApplication.sharedApplication().currentUserNotificationSettings().types
    }
    
    class func remoteNotificationsEnabled() -> Bool {
        if self.remoteNotificationTypes() == UIUserNotificationType.None {
            return false
        }
        
        return true
    }
}

// MARK: - Camera
private extension PresentPrePermissions {
    func showCameraSystemAlert(completion: PermissionCompletionHandler?) {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { granted in
            self.fireCameraCompletionHandler(completion)
        })
    }
    
    func fireCameraCompletionHandler(completion: PermissionCompletionHandler?) {
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        switch authorizationStatus {
        case .NotDetermined:
            completion?(granted: false, userDialogResult: .Denied, systemDialogResult: .NoAction)
        case .Authorized:
            completion?(granted: true, userDialogResult: .Granted, systemDialogResult: .Granted)
        case .Denied:
            completion?(granted: false, userDialogResult: .Granted, systemDialogResult: .Denied)
        case .Restricted:
            completion?(granted: false, userDialogResult: .Granted, systemDialogResult: .Restricted)
        }
    }
    
}
// MARK: - Microphone
private extension PresentPrePermissions {
    func showMicrophoneSystemAlert(completion: PermissionCompletionHandler?) {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeAudio, completionHandler: { granted in
            self.fireMicrophoneCompletionHandler(completion)
        })
    }
    
    func fireMicrophoneCompletionHandler(completion: PermissionCompletionHandler?) {
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        
        switch authorizationStatus {
        case .NotDetermined:
            completion?(granted: false, userDialogResult: .Denied, systemDialogResult: .NoAction)
        case .Authorized:
            completion?(granted: true, userDialogResult: .Granted, systemDialogResult: .Granted)
        case .Denied:
            completion?(granted: false, userDialogResult: .Granted, systemDialogResult: .Denied)
        case .Restricted:
            completion?(granted: false, userDialogResult: .Granted, systemDialogResult: .Restricted)
        }
    }
}

// ???: Twitter
// ???: Facebook

// MARK: - Strings
private extension PresentPrePermissions {
    func titleForPermission(type: PermissionsType) -> String {
        switch type {
        case .Photos:
            return "Allow Photos Access"
        case .Contacts:
            return "Allow Contacts Access"
        case .Location:
            return "Allow Location Access"
        case .PushNotifications:
            return "Allow Push Notifications"
        case .Microphone:
            return "Allow Microphone Access"
        case .Camera:
            return "Allow Camera Access"
        }
    }
    
    func messageForPermission(type: PermissionsType) -> String {
        let appName = self.appName ?? "This app"
        
        switch type {
        case .Photos:
            return "\(appName) would like to access your photos."
        case .Contacts:
            return "\(appName) would like to access your contacts."
        case .Location:
            return "\(appName) would like to access your location."
        case .PushNotifications:
            return "\(appName) would like to send you push notifications."
        case .Microphone:
            return "\(appName) would like to access your microphone."
        case .Camera:
            return "\(appName) would like to access your camera."
        }
    }
}

// MARK: - Helpers
private extension PresentPrePermissions {
    func showAlertView(title: String, message: String, denyButtonTitle: String, grantButtonTitle: String, denyAction: () -> (), grantAction: () -> ()) {
        var alertViewController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        alertViewController.addAction(
            UIAlertAction(title: denyButtonTitle,
                style: .Cancel,
                handler: { action in
                    denyAction()
                }
            )
        )
        
        alertViewController.addAction(
            UIAlertAction(
                title: grantButtonTitle,
                style: .Default,
                handler: { action in
                    grantAction()
                }
            )
        )
        
        if let viewController = topViewController() {
            viewController.presentViewController(alertViewController, animated: true, completion: nil)
        }
    }
    
    func topViewController() -> UIViewController? {
        if let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            return topViewController(rootViewController)
        }
        
        return nil
    }
    
    func topViewController(rootViewController: UIViewController) -> UIViewController? {
        if rootViewController.presentedViewController == nil {
            return rootViewController
        }
        
        if let navigationController = rootViewController.presentedViewController as? UINavigationController {
            if let lastViewController = navigationController.viewControllers.last as? UIViewController {
                return topViewController(lastViewController)
            }
        }
        
        if let presentedViewController = rootViewController.presentedViewController {
            return topViewController(presentedViewController)
        }
        
        return nil
    }
}
