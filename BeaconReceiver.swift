//
//  BeaconReceiver.swift
//  Manvendra
//
//  Created by Manvendra on 31/12/20.
//

import UIKit
import CoreLocation
import UserNotifications

class BeaconReceiver: GLBaseViewController {
    let locationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        locationPermission()
        notificationPermission()
    }
}
// Setup
extension BeaconReceiver: CLLocationManagerDelegate {
    func locationPermission() {
        locationManager.delegate = self
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    debugPrint("Ranging Available")
                    startScanning()
                } else {
                    debugPrint("Ranging UnAvailable")
                }
            }
        } else {
            locationManager.requestAlwaysAuthorization()
        } }
    func notificationPermission() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else {
                debugPrint("All set!")
            }
        }
    }
    func startScanning() {
        for value in DataModel.list {
            if let uuidString = value["uuid"] as? String,
                let majorString = value["major"] as? String,
                let minorString = value["minor"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let major = UInt16(majorString),
                let minor = UInt16(minorString) {
                let identifier = uuidString + majorString + minorString
                let beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: major, minor: minor, identifier: identifier)
                locationManager.startMonitoring(for: beaconRegion)
                locationManager.startRangingBeacons(in: beaconRegion)
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if let beacon = beacons.first {
            checkProximity(beacon)
        }
    }
    
    func checkProximity(_ beacon: CLBeacon) {
        let uuid = beacon.proximityUUID.description
        let identifier = uuid + "\(beacon.major)" + "\(beacon.minor)"
        switch beacon.proximity {
        case .near, .immediate:
            self.checkIn(identifier)
        case .unknown: break
        case .far:
            self.checkOut(from: identifier)
        @unknown default: break
        }
    }
    
    
    func checkIn(_ identifier: String) {
        guard let beacon = getBeaconData(for: identifier) else {
            return
        }
        if !isRecuringNotification(for: identifier) {
            debugPrint("Recuring Notification")
            return
        }
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                debugPrint("authorized")
                self.callNotificaion(for: beacon)
            case .denied:
                debugPrint("denied")
            case .notDetermined:
                debugPrint("notDetermined")
            @unknown default:
                debugPrint("not determined, ask user for permission now")
            }
        })
    }
    private func getBeaconData(for identifier: String) -> [String: Any]? {
        let first = DataModel.list.first(where: {
            let uuidString = $0["uuid"] as? String ?? ""
            let majorString = $0["major"] as? String ?? ""
            let minorString = $0["minor"] as? String ?? ""
            let identifierString = uuidString + majorString + minorString
            return identifierString == identifier
        })
        return first
    }
    private func isRecuringNotification(for identifier: String) -> Bool {
        let currentDate = Date()
        let dateKey = identifier + "date"
        if let isInRegion = UserDefaults.standard.value(forKey: identifier) as? Bool, isInRegion {
            if let oldTime = UserDefaults.standard.value(forKey: dateKey) as? Date {
                let calendar = Calendar.current
                let day = calendar.dateComponents([.day], from: oldTime, to: currentDate).minute ?? 0
                if day < 1 {
                    return false
                }
            }
        }
        UserDefaults.standard.setValue(true, forKey: identifier)
        UserDefaults.standard.setValue(currentDate, forKey: dateKey)
        UserDefaults.standard.synchronize()
        return true
    }
    
    private func callNotificaion(for becon: [String: Any]) {
        debugPrint("Enter in Region \(becon)")
        let time = Double(becon["notifyTime"] as? String ?? "1") ?? 1
        let content = UNMutableNotificationContent()
        content.title = becon["message"] as? String ?? ""
        content.sound = UNNotificationSound.default()
        content.userInfo = becon
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time > 0 ? time: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().add(request)
    }
    
    
    private func checkOut(from identifier: String) {
        debugPrint("Exit from Region \(identifier)")
        UserDefaults.standard.setValue(false, forKey: identifier)
        UserDefaults.standard.synchronize()
    }
    func checkIn(_ identifier: String) {
        guard let beacon = getBeaconData(for: identifier) else {
            return
        }
        if !isRecuringNotification(for: identifier) {
            debugPrint("Recuring Notification")
            return
        }     UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                debugPrint("authorized")
                self.callNotificaion(for: beacon)
            case .denied:
                debugPrint("denied")
            case .notDetermined:
                debugPrint("notDetermined")
            @unknown default:
                debugPrint("not determined, ask user for permission now")
            }
        })
    }
    private func getBeaconData(for identifier: String) -> [String: Any]? {
        let first = DataModel.list.first(where: {
            let uuidString = $0["uuid"] as? String ?? ""
            let majorString = $0["major"] as? String ?? ""
            let minorString = $0["minor"] as? String ?? ""
            let identifierString = uuidString + majorString + minorString
            return identifierString == identifier
        })
        return first
    }
    private func isRecuringNotification(for identifier: String) -> Bool {
        let currentDate = Date()
        let dateKey = identifier + "date"
        if let isInRegion = UserDefaults.standard.value(forKey: identifier) as? Bool, isInRegion {
            if let oldTime = UserDefaults.standard.value(forKey: dateKey) as? Date {
                let calendar = Calendar.current
                let day = calendar.dateComponents([.day], from: oldTime, to: currentDate).minute ?? 0
                if day < 1 {
                    return false
                }
            }
        }
        UserDefaults.standard.setValue(true, forKey: identifier)
        UserDefaults.standard.setValue(currentDate, forKey: dateKey)
        UserDefaults.standard.synchronize()
        return true
    }
}
extension BeaconReceiver: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        debugPrint("did Receive Beacon Notification")
        let userInfo = response.notification.request.content.userInfo
        debugPrint(userInfo)
    }
}
struct DataModel {
    static var list: [[String: Any]] = [
        [
            "uuid": "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5",
            "major": "9",
            "minor": "1",
            "status": "1",
            "message": "Welcome to Walmart Los angeles first floor",
            "notifyTime": "1"
        ],
        [
            "uuid": "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5",
            "major": "9",
            "minor": "5",
            "status": "1",
            "message": "Welcome to Walmart Los angeles fifth floor",
            "notifyTime": "1"
        ]
    ]
}
