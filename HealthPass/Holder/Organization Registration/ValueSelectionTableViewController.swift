//
//  ValueSelectionTableViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ValueSelectionTableViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        constructDataSource()
        
        isModalInPresentation = true
        
        title = valueTitle?.snakeCased()?.capitalized
        
        tableView.tableFooterView = UIView()
        
        navigationItem.rightBarButtonItem = isSingleSelection ? nil : doneBarButtonItem
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    
    // MARK: - IBAction
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDone(_ sender: Any) {
        performSegue(withIdentifier: unwindToRegistrationDetailsSegue, sender: nil)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    var valueTitle: String?
    var valueDictionary: [String: Any]?
    
    var isSingleSelection: Bool = true
    
    var dataSource: [String]? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    var selectedData: String? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    var selectedArray: [String]? {
        didSet {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties
    
    private let unwindToRegistrationDetailsSegue = "unwindToRegistrationDetails"
    
    private var locations: [[String: Any]]?
    
    // MARK: Private Methods
    
    private func constructDataSource() {
        if valueTitle == "location" {
            locations = readLocationFile()
            dataSource = locations?.compactMap { $0["State"] as? String }
        } else {
            let items = valueDictionary?["items"] as? [String: Any]
            dataSource = (valueDictionary?["enum"] as? [String]) ?? (items?["enum"] as? [String])
        }
        
        if let selectionType = valueDictionary?["type"] as? String {
            isSingleSelection = !(selectionType == "array")
        }
        
    }
    
    private func readLocationFile() -> [[String: Any]]? {
        guard let path = Bundle.main.path(forResource: String("location"), ofType: String("json")) else {
            return nil
        }
        
        let fileUrl = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: fileUrl, options: .mappedIfSafe) else {
            return nil
        }
        
        let locations = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        return locations
    }
    
}

extension ValueSelectionTableViewController {
    // ======================================================================
    // === UITableView ======================================================
    // ======================================================================
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return valueDictionary?["description"] as? String
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ValueSelectionTableViewCell", for: indexPath)
        
        if let data = dataSource?[indexPath.row] {
            cell.textLabel?.text = data
            cell.textLabel?.font = AppFont.bodyScaled
            
            if isSingleSelection {
                cell.accessoryType = (selectedData == data) ? .checkmark : .none
            } else {
                cell.accessoryType = (selectedArray?.contains(data) ?? false) ? .checkmark : .none
            }
            
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let data = dataSource?[indexPath.row] {
            if isSingleSelection {
                selectedData = data
                performSegue(withIdentifier: unwindToRegistrationDetailsSegue, sender: nil)
            } else {
                if selectedArray == nil {
                    selectedArray = []
                }
                
                if selectedArray?.contains(data) ?? false {
                    selectedArray = selectedArray?.filter { $0 != data }
                } else {
                    //For Race options
                    //If Decline to state is selected, remove any other items selected in the list
                    let dts = "reg.decline".localized
                    if data == dts {
                        selectedArray?.removeAll()
                        selectedArray?.append(data)
                    } else {
                        if let dtsIndex = selectedArray?.firstIndex(of: dts) {
                            selectedArray?.remove(at: dtsIndex)
                        }
                    }
                    
                    //For Race options
                    //If more than 3 options are selected, notify the user regarding the limit
                    if selectedArray?.count == 3 {
                        showConfirmation(title: valueTitle?.snakeCased()?.capitalized ?? "",
                                         message: "reg.confirmation".localized,
                                         actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
                        return
                    }
                    
                    selectedArray = selectedArray?.filter { $0 != data }
                    selectedArray?.append(data)
                }
            }
        }
    }
    
}
