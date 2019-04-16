//
//  AddItemVC.swift
//  CloudKitSharedDemo
//
//  Created by Jerry Wang on 4/13/19.
//  Copyright © 2019 Jerry Wang. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

protocol AddItemViewControllerDelegate {
    func addedItem(controller: AddItemVC, didAddItem item: CKRecord)
    func updatedItem(controller: AddItemVC, didUpdateItem item: CKRecord)
}

class AddItemVC: UIViewController {
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var numberStepper: UIStepper!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var delegate: AddItemViewControllerDelegate?
    var newItem: Bool = true
    
    var list: CKRecord!
    var item: CKRecord?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        // Update Helper
        newItem = item == nil
        
        
        // Add Observer
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(AddItemVC.textFieldTextDidChange(notification:)), name: UITextField.textDidChangeNotification, object: nameTextField)
    }
    
    private func updateNumberStepper() {
        if let number = item?.object(forKey: "number") as? Double {
            numberStepper.value = number
        }
    }
    
    @IBAction func numberDidChange(sender: UIStepper) {
        let number = Int(sender.value)
        
        // Update Number Label
        numberLabel.text = "\(number)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        nameTextField.becomeFirstResponder()
    }
    
    @objc func textFieldTextDidChange(notification: NSNotification) {
        updateSaveButton()
    }
    
    private func setupView() {
        updateNameTextField()
        updateNumberStepper()
        updateSaveButton()
    }
    
    private func updateNameTextField() {
        if let name = item?.object(forKey: "name") as? String {
            nameTextField.text = name
        }
    }
    
    private func updateSaveButton() {
        let text = nameTextField.text
        
        if let name = text {
            saveButton.isEnabled = !name.isEmpty
        } else {
            saveButton.isEnabled = false
        }
    }
    
    
    @IBAction func cancel(sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func save(sender: AnyObject) {
        // Helpers
        let name = nameTextField.text
        let number = Int(numberStepper.value)
        // Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        if item == nil {
            // Create Record
            item = CKRecord(recordType: "Item")
            
            // Initialize Reference
            let listReference = CKRecord.Reference(recordID: list.recordID, action: .deleteSelf)
            
            // Configure Record
            item?.setObject(listReference, forKey: "list")
            
        }
        
        // Configure Record
        if let validName = name as CKRecordValue?, let validNumber = number as CKRecordValue?{
            item?.setObject(validName, forKey: "name")
            item?.setObject(validNumber, forKey: "number")
        }
        
        // Show Progress HUD
        SVProgressHUD.show()
        
        // Save Record
        privateDatabase.save(item!) {
            (record, error) -> Void in
            DispatchQueue.main.async {
                // Dismiss Progress HUD
                SVProgressHUD.dismiss()
                // Process Response
                self.processResponse(record: record, error: error)
            }
        }
    }
    
    private func processResponse(record: CKRecord?, error: Error?) {
        var message = ""
        
        if let error = error {
            print(error.localizedDescription)
            message = "We were not able to save your item."
            
        } else if record == nil {
            message = "We were not able to save your item."
        }
        
        if !message.isEmpty {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            // Present Alert Controller
            present(alertController, animated: true, completion: nil)
            
        } else {
            // Notify Delegate
            if newItem {
                delegate?.addedItem(controller: self, didAddItem: item!)
            } else {
                delegate?.updatedItem(controller: self, didUpdateItem: item!)
            }
            
            // Pop View Controller
            navigationController?.popViewController(animated: true)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
