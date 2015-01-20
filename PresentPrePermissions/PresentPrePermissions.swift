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

public class PresentPrePermissions: NSObject {
    private var locationManager: CLLocationManager?
    private var locationCompletionHandler: PermissionCompletionHandler?
    
    public class func sharedPermissions() -> PresentPrePermissions {
        struct Static {
            static let instance = PresentPrePermissions()
        }

        return Static.instance
    }
    
    public class func remoteNotificationsDidUpdate() {
        println("Remote notifications did update")
    }
    
    public func showPhotoPermission(title: String? = "Access Photos?", message: String?, var denyButtonTitle: String?, var grantButtonTitle: String?, completion: PermissionCompletionHandler?) {
        denyButtonTitle = self.title(denyButtonTitle, forTitleType: .Deny)
        grantButtonTitle = self.title(grantButtonTitle, forTitleType: .Request)
        
        var authorizationStatus = ALAssetsLibrary.authorizationStatus()
        if authorizationStatus == ALAuthorizationStatus.NotDetermined {
            self.showAlertView(
                title!,
                message: message!,
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
            completion?(granted: photoAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    public func showContactsPermission(title: String? = "Access Contacts?", message: String?, var denyButtonTitle: String?, var grantButtonTitle: String?, completion: PermissionCompletionHandler?) {
        denyButtonTitle = self.title(denyButtonTitle, forTitleType: .Deny)
        grantButtonTitle = self.title(grantButtonTitle, forTitleType: .Request)
        
        var authorizationStatus = ABAddressBookGetAuthorizationStatus()
        if authorizationStatus == ABAuthorizationStatus.NotDetermined {
            self.showAlertView(
                title!,
                message: message!,
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
            completion?(granted: contactsAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    /*
        This requires that the NSLocationWhenInUseUsageDescription key is set in the Info.plist of your application.
     */
    public func showLocationPermission(title: String? = "Access Location?", message: String?, var denyButtonTitle: String?, var grantButtonTitle: String?, authorizationType: PresentLocationAuthorizationType? = .WhenInUse, completion: PermissionCompletionHandler?) {
        denyButtonTitle = self.title(denyButtonTitle, forTitleType: .Deny)
        grantButtonTitle = self.title(grantButtonTitle, forTitleType: .Request)
        
        self.locationCompletionHandler = completion
        
        var authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == CLAuthorizationStatus.NotDetermined {
            self.showAlertView(title!,
                message: message!,
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
            completion?(granted: locationAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    /*
        The completion handler will only be called if notifications are already enabled. application:didRegisterForRemoteNotificationsWithDeviceToken: and 
        application:didFailToRegisterForRemoteNotificationsWithError: should be used as completion for granting access.
     */
    public func showRemoteNotificationPermission(title: String? = "Allow Push Notifications?", message: String?, var denyButtonTitle: String?, var grantButtonTitle: String?, notificationTypes: UIUserNotificationType? = nil, completion: PermissionCompletionHandler?) {
        denyButtonTitle = self.title(denyButtonTitle, forTitleType: .Deny)
        grantButtonTitle = self.title(grantButtonTitle, forTitleType: .Request)
        
        if !self.remoteNotificationsEnabled() {
            self.showAlertView(
                title!,
                message: message!,
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    var application = UIApplication.sharedApplication(),
                        delegate = application.delegate,
                        error = NSError(domain: "PresentPrePermissionsErrorDomain", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "User denied push notifications prompt via PresentPrePermissions."
                        ])
                    
                    delegate?.application?(application, didFailToRegisterForRemoteNotificationsWithError: error)
                },
                grantAction: {
                    self.showRemoteNotificationSystemAlert(notificationTypes ?? (.Badge | .Alert | .Sound))
                }
            )
        } else {
            completion?(granted: true, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    public func showCameraPermission(title: String? = "Allow Camera Access?", message: String?, var denyButtonTitle: String?, var grantButtonTitle: String?, completion: PermissionCompletionHandler?) {
        denyButtonTitle = self.title(denyButtonTitle, forTitleType: .Deny)
        grantButtonTitle = self.title(grantButtonTitle, forTitleType: .Request)
        
        var authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if authorizationStatus == AVAuthorizationStatus.NotDetermined {
            self.showAlertView(
                title!,
                message: message!,
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    self.fireCameraCompletionHandler(completion)
                }, grantAction: {
                    self.showCameraSystemAlert(completion)
                })
        } else {
            completion?(granted: cameraAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
    
    public func showMicrophonePermission(title: String? = "Allow Microphone Access?", message: String?, var denyButtonTitle: String?, var grantButtonTitle: String?, completion: PermissionCompletionHandler?) {
        denyButtonTitle = self.title(denyButtonTitle, forTitleType: .Deny)
        grantButtonTitle = self.title(grantButtonTitle, forTitleType: .Request)
        
        var authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        if authorizationStatus == AVAuthorizationStatus.NotDetermined {
            self.showAlertView(
                title!,
                message: message!,
                denyButtonTitle: denyButtonTitle!,
                grantButtonTitle: grantButtonTitle!,
                denyAction: {
                    println("Fire the microphone completion handler")
                    self.fireCameraCompletionHandler(completion)
                }, grantAction: {
                    println("Show the microphone system alert")
                    self.showMicrophoneSystemAlert(completion)
                })
        } else {
            completion?(granted: microphoneAccessGranted, userDialogResult: .NoAction, systemDialogResult: .NoAction)
        }
    }
}

public extension PresentPrePermissions {
    public var photoAccessGranted: Bool {
        return ALAssetsLibrary.authorizationStatus() == ALAuthorizationStatus.Authorized
    }
    
    public var contactsAccessGranted: Bool {
        return ABAddressBookGetAuthorizationStatus() == ABAuthorizationStatus.Authorized
    }
    
    public var locationAccessGranted: Bool {
        return self.locationAuthorizationStatusPermitsAccess(CLLocationManager.authorizationStatus())
    }
    
    public var remoteNotificationAccessGranted: Bool {
        return self.remoteNotificationsEnabled()
    }
    
    public var cameraAccessGranted: Bool {
        return AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Authorized
    }
    
    public var microphoneAccessGranted: Bool {
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
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        
        switch authorizationType {
        case .Always:
            self.locationManager!.requestAlwaysAuthorization()
        case .WhenInUse:
            self.locationManager!.requestWhenInUseAuthorization()
        }
        
        self.locationManager!.startUpdatingLocation()
    }
    
    func fireLocationCompletionHandler() {
        switch CLLocationManager.authorizationStatus() {
        case .Authorized, .AuthorizedWhenInUse:
            self.locationCompletionHandler?(granted: true, userDialogResult: .Granted, systemDialogResult: .Granted)
        case .Denied:
            self.locationCompletionHandler?(granted: false, userDialogResult: .Granted, systemDialogResult: .Denied)
        case .Restricted:
            self.locationCompletionHandler?(granted: false, userDialogResult: .Granted, systemDialogResult: .Restricted)
        case .NotDetermined:
            self.locationCompletionHandler?(granted: false, userDialogResult: .Denied, systemDialogResult: .NoAction)
        }
        
        self.locationManager?.stopUpdatingLocation()
        self.locationManager = nil
    }
    
    func locationAuthorizationStatusPermitsAccess(status: CLAuthorizationStatus) -> Bool {
        return (status == CLAuthorizationStatus.Authorized || status == CLAuthorizationStatus.AuthorizedWhenInUse)
    }
}

// MARK: Location Manager Delegate
extension PresentPrePermissions: CLLocationManagerDelegate {
    
    public func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .NotDetermined {
            self.fireLocationCompletionHandler()
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

// MARK - Notifications
private extension PresentPrePermissions {
    func showRemoteNotificationSystemAlert(notificationType: UIUserNotificationType) {
        var application = UIApplication.sharedApplication(),
            settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: notificationType, categories: nil)
        
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    func fireRemoteNotificationCompletionHandler(completion: PermissionCompletionHandler) {
        println("Completion handler should be fired")
    }
    
    func remoteNotificationTypes() -> UIUserNotificationType {
        return UIApplication.sharedApplication().currentUserNotificationSettings().types
    }
    
    func remoteNotificationsEnabled() -> Bool {
        if self.remoteNotificationTypes() == UIUserNotificationType.None {
            return false
        }
        
        return true
    }
}

// MARK - Camera
private extension PresentPrePermissions {
    func showCameraSystemAlert(completion: PermissionCompletionHandler?) {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { granted in
            self.fireCameraCompletionHandler(completion)
        })
    }
    
    func fireCameraCompletionHandler(completion: PermissionCompletionHandler?) {
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
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
// MARK - Microphone
private extension PresentPrePermissions {
    func showMicrophoneSystemAlert(completion: PermissionCompletionHandler?) {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeAudio, completionHandler: { granted in
            self.fireMicrophoneCompletionHandler(completion)
        })
    }
    
    func fireMicrophoneCompletionHandler(completion: PermissionCompletionHandler?) {
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio) {
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

// MARK: - Helpers
private extension PresentPrePermissions {
    func title(var title: String?, forTitleType titleType: PresentTitleType) -> String {
        switch titleType {
        case .Deny:
            return title ?? "Not Now"
        case .Request:
            return title ?? "Grant Access"
        }
    }
    
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
