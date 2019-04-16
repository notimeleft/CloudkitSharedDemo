//
//  SingleListVC.swift
//  CloudKitSharedDemo
//
//  Created by Jerry Wang on 4/13/19.
//  Copyright © 2019 Jerry Wang. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

class SingleListVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    static let cellIdentifier = "ItemCell"
    let addItemSegueID = "AddItemDetail"
    
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    var list: CKRecord!
    var items = [CKRecord]()
    
    var selectionIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        title = list.object(forKey: "name") as? String
        setupView()
        fetchItems()
    }
    
    private func setupView(){
        messageLabel.isHidden = true
        tableView.isHidden = true
        activityView.startAnimating()
    }
    
    private func updateView(){
        let recordEmpty = items.isEmpty
        tableView.isHidden = recordEmpty
        messageLabel.isHidden = !recordEmpty
        activityView.stopAnimating()
    }
    
    private func fetchItems(){
        let privateDataBase = CKContainer.default().privateCloudDatabase
        //get a reference to the current list. Note that we are also creating the reference deletion semantics: if the list itself is deleted, we delete all items in that list too
        let reference = CKRecord.Reference(recordID: list.recordID, action: .deleteSelf)
        //ask the database for all items associated with the current list
        let query = CKQuery(recordType: "Item", predicate: NSPredicate(format: "list == %@", reference))
        
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        privateDataBase.perform(query, inZoneWith: nil){
            (records, error) in
            DispatchQueue.main.async {
                self.processResponse(records, error)
            }
        }
    }
    
    private func processResponse(_ records: [CKRecord]?, _ error: Error?){
        if let error = error {
            print(error.localizedDescription)
            messageLabel.text = "error fetching list!"
        } else if let records = records {
            items = records
            if items.count > 0 {
                tableView.reloadData()
            } else {
                messageLabel.text = "no items in list!"
            }
            
        }
        updateView()
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        cell.accessoryType = .detailDisclosureButton
        let item = items[indexPath.row]
        
        if let name = item.object(forKey: "name") as? String {
            cell.textLabel?.text = name
        } else {
            cell.textLabel?.text = "..."
        }
        
        if let itemNumber = item.object(forKey: "number") as? Int {
            // Configure Cell
            cell.detailTextLabel?.text = "\(itemNumber)"
        } else {
            cell.detailTextLabel?.text = "1"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let item = items[indexPath.row]
        deleteRecord(item: item)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Save Selection
        selectionIndex = indexPath.row
        
        // Perform Segue
        performSegue(withIdentifier: addItemSegueID, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case addItemSegueID:
            // Fetch Destination View Controller
            let addItemViewController = segue.destination as! AddItemVC
            
            // Configure View Controller
            addItemViewController.list = list
            addItemViewController.delegate = self
            
            if let selection = selectionIndex {
                // Fetch Item
                let item = items[selection]
                
                // Configure View Controller
                addItemViewController.item = item
            }
        default:
            break
        }
    }
    
    private func deleteRecord(item: CKRecord) {
        // Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        // Show Progress HUD
        SVProgressHUD.show()
        
        // Delete List
        privateDatabase.delete(withRecordID: item.recordID) { (recordID, error) -> Void in
            DispatchQueue.main.async {
                // Dismiss Progress HUD
                SVProgressHUD.dismiss()
                
                // Process Response
                self.processResponseForDeleteRequest(record: item, recordID: recordID, error: error)
            }
        }
    }
    
    private func processResponseForDeleteRequest(record: CKRecord, recordID: CKRecord.ID?, error: Error?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We are unable to delete the item."
            
        } else if recordID == nil {
            message = "We are unable to delete the item."
        }
        
        if message.isEmpty {
            // Calculate Row Index
            let index = items.firstIndex(of:record)
            
            if let index = index {
                // Update Data Source
                items.remove(at:index)
                
                if items.count > 0 {
                    // Update Table View
                    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .right)
                    
                } else {
                    // Update Message Label
                    messageLabel.text = "No Items Found"
                    
                    // Update View
                    updateView()
                }
            }
            
        } else {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            // Present Alert Controller
            present(alertController, animated: true)
        }
    }

}

extension SingleListVC:AddItemViewControllerDelegate{
    func addedItem(controller: AddItemVC, didAddItem item: CKRecord) {
        // Add Item to Items
        items.append(item)
        
        // Sort Items
        sortItems()
        
        // Update Table View
        tableView.reloadData()
        
        // Update View
        updateView()
    }
    
    func updatedItem(controller: AddItemVC, didUpdateItem item: CKRecord) {
        // Sort Items
        sortItems()
        
        // Update Table View
        tableView.reloadData()
    }
    
    private func sortItems(){
        items.sort{
            if let name0 = $0.object(forKey:"name") as? String,
                let name1 = $1.object(forKey:"name") as? String{
                return (name0 < name1)
            }
            return false
        }
    }
    
}
