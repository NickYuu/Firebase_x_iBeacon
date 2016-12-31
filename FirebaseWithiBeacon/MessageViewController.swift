//
//  MessageViewController.swift
//  FirebaseWithiBeacon
//
//  Created by YU on 2016/12/23.
//  Copyright © 2016年 YU. All rights reserved.
//

import UIKit
import Firebase

class MessageViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    let ref = FIRDatabase.database().reference()
    var msgRef: FIRDatabaseReference?
    var msgs = [String]()
    var observerHandel: UInt?
    let userName = UserDefaults.standard[PreferenceNames.userName]
    var msgKey = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        msgRef = ref.child(msgKey)
        
        observerHandel = addObserver(ref: msgRef, type: .value) { (snapshot) in
            guard let arr = snapshot.value as? [String] else { return }
            self.msgs = arr
            self.tableView.reloadData()
        }
        
    }

}

// MARK:- UI相關
extension MessageViewController {
    
    func showAlert(title:String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

// MARK:- IBAction
extension MessageViewController {
    
    @IBAction func addBtnClick(_ sender: UIBarButtonItem) {
        guard (observerHandel != nil) else {
            showAlert(title: "目前不在範圍內")
            return
        }
        let alert = UIAlertController(title: "留言", message: "添加一條留言", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let text = alert.textFields?.first?.text else {return}
            guard !text.isEmpty else { return }
            
            self.msgs.append("\(self.userName!): \(text)")
            //self.msgRef?.setValue(self.msgs)
            self.saveMsg(text: text)
        }
        
        alert.addTextField()
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        present(alert, animated: true, completion: nil)
    }
    
}


// MARK:- Firebase Helper
extension MessageViewController {
    
    func addObserver(ref:FIRDatabaseReference?, type:FirebaseDatabase.FIRDataEventType, with:@escaping (_ snapshot:FIRDataSnapshot)->()) -> UInt? {
        return ref?.observe(type, with: { with($0) })
    }
    
    func removeObserverForMsg() throws {
        guard let handel = observerHandel else {
            throw error.a
        }
        observerHandel = nil
        msgs = []
        tableView.reloadData()
        msgRef?.removeObserver(withHandle: handel)
    }
    
    enum error:String, Error {
        case a = "handel is nil"
    }
    
    func saveMsg(text:String) {
        
        msgRef?.setValue(self.msgs, withCompletionBlock: { (error, ref) in
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let arr = snapshot.value as? [String] else { return }
                if !arr.contains("\(self.userName!): \(text)") {
                    self.msgs.append("\(self.userName!): \(text)")
                    self.saveMsg(text: text)
                }
            })
        })
        
        
//        msgRef?.runTransactionBlock({ (currentData) -> FIRTransactionResult in
//            guard var array = currentData.value as? [String] else { return FIRTransactionResult.success(withValue: currentData)
//            }
//            
//            array = self.msgs
//            
//            currentData.value = array
//            
//            return FIRTransactionResult.success(withValue: currentData)
//            
//        }, andCompletionBlock: { (error, committed, snapshot) in
//            if let error = error {
//                print(error.localizedDescription)
//            }
//        }, withLocalEvents: false)
        
        
    }
    
}



// MARK:- tableView的DataSource和Delegate方法
extension MessageViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = msgs[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("點擊了:\(indexPath.row)")
    }
}
