//
//  BeaconViewController.swift
//  FirebaseWithiBeacon
//
//  Created by YU on 2016/12/23.
//  Copyright © 2016年 YU. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class BeaconViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let ref = FIRDatabase.database().reference()
    var uuidRef: FIRDatabaseReference { return ref.child("beaconID") }
    let locationManager = CLLocationManager()
    var beaconRegions: [CLBeaconRegion] = []
    var currentRegions: [CLBeaconRegion] = []
    var infoMsgs: [String:String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkUserName()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        chekChatroom()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! MessageViewController
        let index = tableView.indexPathForSelectedRow!.row
        vc.msgKey = currentRegions[index].proximityUUID.uuidString
    }
    

}


// MARK:- UI相關
extension BeaconViewController {
    
    func showAlert(title:String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

// MARK:- Helper
extension BeaconViewController {
    
    fileprivate func checkUserName() {
        if UserDefaults.standard[PreferenceNames.userName] == nil {
            let alert = UIAlertController(title: "請輸入暱稱", message: "做為留言的識別", preferredStyle: .alert)
            
            let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
                guard let text = alert.textFields?.first?.text else{ return }
                guard !text.isEmpty else {
                    self.checkUserName()
                    return
                }
                UserDefaults.standard[PreferenceNames.userName] = text
            }
            alert.addTextField()
            alert.addAction(saveAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func chekChatroom() {
        uuidRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let arr = snapshot.value as? [[String:String]] else { return }
            
            for dic in arr {
                guard let beaconRegion = self.setupBeaconRegion(dic: dic) else {
                    continue
                }
                self.beaconRegions.append(beaconRegion)
            }
        })
    }
}


// MARK:- IBAction
extension BeaconViewController {
    
    @IBAction func detectEnableValueChanged(_ sender: UISwitch) {
        sender.isOn ? starBeacon() : stopBeacon()
    }
    
}


// MARK:- iBeacon
extension BeaconViewController {
    
    fileprivate func setupBeaconRegion(dic:[String:String]) -> CLBeaconRegion? {
        guard
            let uuidStr = dic["uuid"],
            let identifier = dic["identifier"],
            let beaconUUID = UUID(uuidString: uuidStr)
            else { return nil }
        
        let beaconRegion = CLBeaconRegion(proximityUUID: beaconUUID, identifier: identifier)
        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyOnExit = true
        return beaconRegion
    }
    
    fileprivate func starBeacon() {
        for region in beaconRegions {
            locationManager.startMonitoring(for: region)
        }
    }
    
    fileprivate func stopBeacon() {
        for region in beaconRegions {
            locationManager.stopMonitoring(for: region)
            locationManager.stopRangingBeacons(in: region)
        }
        currentRegions = []
        tableView.reloadData()
    }
}

// MARK:- CLLocationManagerDelegate
extension BeaconViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
        locationManager.requestState(for: region)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        let isInside = state == .inside
        let insideMsg = "User is inside the region\(region.identifier)"
        let outsideMsg = "User is outside the region\(region.identifier)"
        let msg = isInside ? insideMsg : outsideMsg
        let beaconRegion = region as! CLBeaconRegion
        
        if isInside {
            
            locationManager.startRangingBeacons(in: beaconRegion)
        } else {
            
            
            locationManager.stopRangingBeacons(in: beaconRegion)
        }
        showLocalNotification(msg)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        if !currentRegions.contains(region) {
            currentRegions.append(region)
        }
        
        _ = beacons.map {
            var proximityStr = ""
            switch $0.proximity {
            case .unknown:
                proximityStr = "未知"
            case .far:
                proximityStr = "有點遠"
            case .near:
                proximityStr = "很接近"
            case .immediate:
                proximityStr = "在旁邊"
                
            }
            let accuracy = String(format: "%.2f", Float($0.accuracy))
            
            let info = "\(proximityStr), RSSI: \($0.rssi), 誤差：\(accuracy) M"
            //, \(region.proximityUUID), \($0.major), \($0.minor)"
            
            infoMsgs[region.identifier] = info
            
        }
        tableView.reloadData()
    }
    
}

// MARK:- tableView的DataSource和Delegate方法
extension BeaconViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentRegions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let region = currentRegions[indexPath.row]
        
        cell.textLabel?.text = region.identifier
        cell.detailTextLabel?.text = infoMsgs[region.identifier]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("點擊了:\(indexPath.row)")
    }
}


// MARK:- LocalNotification
extension BeaconViewController {
    
    func showLocalNotification(_ message:String) {
        let noti = UILocalNotification()
        noti.fireDate = Date(timeIntervalSinceNow: 1.0)
        noti.alertBody = message
        UIApplication.shared.scheduleLocalNotification(noti)
    }
    
}
