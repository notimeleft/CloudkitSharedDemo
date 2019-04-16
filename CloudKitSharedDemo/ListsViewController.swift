//
//  ViewController.swift
//  CloudKitSharedDemo
//
//  Created by Jerry Wang on 3/28/19.
//  Copyright © 2019 Jerry Wang. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

class ListsViewController: UIViewController {
    let cellReuseIdentifier = "cell"
    let listRecordTypeID = "List"
    let itemRecordTypeID = "Item"
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    var lists = [CKRecord]()
    var userSelectionIndex:Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //fetchUserRecordID()
        setupView()
        fetchLists()
    }

//    private func fetchUserRecordID(){
//        let defaultContainer = CKContainer.default()
//
//        defaultContainer.fetchUserRecordID{
//            (recordId, error) in
//
//            if let error = error { print(error.localizedDescription) }
//
//            if let userRecordId = recordId{
//                print(userRecordId.recordName,userRecordId.zoneID.zoneName)
//                DispatchQueue.main.async{
//                    self.fetchPrivateRecord(recordID:userRecordId)
//                }
//            }
//        }
//    }
//
//    private func fetchPrivateRecord(recordID:CKRecord.ID){
//        let defaultContainer = CKContainer.default()
//        let privateDataBase = defaultContainer.privateCloudDatabase
//
//        privateDataBase.fetch(withRecordID:recordID){
//            (record,error) in
//            if let error = error { print(error.localizedDescription)}
//            if let userRecord = record { print(userRecord.recordID) }
//        }
//    }
    
    func setupView(){
        tableView.isHidden = true
        messageLabel.isHidden = true
        activityIndicator.startAnimating()
    }
    
    func fetchLists(){
        let privateDatabase = CKContainer.default().privateCloudDatabase
        let query = CKQuery(recordType: "List", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key:"name",ascending: true)]
        privateDatabase.perform(query, inZoneWith: nil){
            (records,error) in
            guard error == nil else {print(error?.localizedDescription ?? "eh?");return}
            records?.forEach{
                (record) in
                print(record.value(forKey: "name") ?? "no value")
                self.lists.append(record)
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                    self.messageLabel.text = ""
                    self.updateView()
                }
                
            }
        }
    }
    
    func updateView(){
        let listExists = lists.count > 0
        self.tableView.isHidden = !listExists
        self.messageLabel.isHidden = listExists
        activityIndicator.stopAnimating()
    }
    
}


extension ListsViewController:UITableViewDelegate,UITableViewDataSource{
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        cell.accessoryType = .detailDisclosureButton
        let list = lists[indexPath.row]
        if let listName = list.object(forKey: "name") as? String{
            cell.textLabel?.text = listName
        } else {
            cell.textLabel?.text = "---"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let list = lists[indexPath.row]
        deleteRecord(list)
    }
    
    func deleteRecord(_ list:CKRecord){
        let privateDataBase = CKContainer.default().privateCloudDatabase
        SVProgressHUD.show()
        privateDataBase.delete(withRecordID: list.recordID){
            (record,error) in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self.processResponse(record,error)
            }
        }
    }
    
    private func processResponse(_ recordID:CKRecord.ID?,_ error:Error?){
        if let error = error {
            print(error.localizedDescription)
            let ac = UIAlertController(title: "Error!", message: nil, preferredStyle: .alert)
            present(ac,animated:true)
        }
        else {
            let deleteIndex = lists.firstIndex{
                $0.recordID == recordID
            }
            if let deleteIndex = deleteIndex{
                lists.remove(at: deleteIndex)
                tableView.deleteRows(at: [IndexPath(row: deleteIndex, section: 0)], with: .automatic)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        userSelectionIndex = indexPath.row
        performSegue(withIdentifier: "AddListSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            case "AddListSegue":
                if let addListVC = segue.destination as? AddListVC{
                    addListVC.delegate = self
                    if let selection = userSelectionIndex {
                        addListVC.list = lists[selection]
                    }
                }
            case "ShowListSegue":
                if let singleVC = segue.destination as? SingleListVC{
                    if let validSelection = tableView.indexPathForSelectedRow?.row {
                        singleVC.list = lists[validSelection]
                    }
                }
            default: return
        }
    }
    
    
}


extension ListsViewController: AddListDelegate{
    func addedNewRecord(controller: AddListVC, newRecord: CKRecord) {
        lists.append(newRecord)
        sortLists()
        tableView.reloadData()
        updateView()
    }
    
    private func sortLists(){
        lists.sort{
            let first = $0.object(forKey:"name") as! String
            let second = $1.object(forKey: "name") as! String
            return  first < second
        }
    }
    
    func updatedRecord(controller: AddListVC, updatedRecord: CKRecord) {
        sortLists()
        tableView.reloadData()
    }
    
    func resetSelection(){
        userSelectionIndex = nil
    }
}
