//
//  ViewController.swift
//  CloudKitSharedDemo
//
//  Created by Jerry Wang on 3/30/19.
//  Copyright © 2019 Jerry Wang. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

protocol AddListDelegate:AnyObject{
    func addedNewRecord(controller:AddListVC,newRecord:CKRecord)
    func updatedRecord(controller:AddListVC,updatedRecord:CKRecord)
    func resetSelection()
}

class AddListVC: UIViewController {


    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    
    weak var delegate:AddListDelegate?
    //flag to distinguish between a new list and a current list
    var newList = true
    var list:CKRecord?
    
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.resetSelection()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        if list == nil {
            list = CKRecord(recordType: "List")
        }
        let name = self.textField.text! as NSString
        let privateDataBase = CKContainer.default().privateCloudDatabase
        if let list = list {
            list.setObject(name, forKey: "name")
            SVProgressHUD.show()
            privateDataBase.save(list){
                (record,error) in
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.processResponse(record:record,error:error)
                }
            }
        }
    }
    
    private func processResponse(record: CKRecord?, error:Error?){
        if let error = error{
            print(error.localizedDescription)
            let alertController = UIAlertController(title: "Error Saving!", message: nil, preferredStyle: .alert)
            present(alertController,animated:true)
        }
        else if let record = record {
            if newList {
                delegate?.addedNewRecord(controller: self, newRecord: record)
            } else {
                delegate?.updatedRecord(controller: self, updatedRecord: record)
            }
            navigationController?.popViewController(animated: true)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.newList = (self.list == nil)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AddListVC.textFieldTextDidChange(notification:)), name: UITextField.textDidChangeNotification, object: textField)
        // Do any additional setup after loading the view.
    }
    
    @objc func textFieldTextDidChange(notification:NSNotification){
        updateSaveButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //textField.becomeFirstResponder()
    }
    
    private func setupView(){
        updateNameTextField()
        updateSaveButton()
    }
    
    private func updateNameTextField(){
        if let name = list?.object(forKey: "name") as? String {
            textField.text = name
        }
    }
    
    private func updateSaveButton(){
        let text = textField.text
        if let name = text {
            saveButton.isEnabled = !name.isEmpty
        } else {
            saveButton.isEnabled = false
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
