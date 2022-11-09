//
//  ImportCompleteViewController.swift
//  Holder
//
//  Created by Gautham Velappan on 11/29/21.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ImportCompleteViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        addBarButtonItem?.title = "scan.add".localized
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateView()
    }
    
    @IBAction func onCancel(_ sender: Any) {
        performSegue(withIdentifier: unwindToWalletSegue, sender: nil)
    }
    
    @IBAction func onAddToWallet(_ sender: Any) {
        addToWallet()
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    var credentialString: [String]? {
        didSet {
            verifiableObjects = credentialString?.compactMap { VerifiableObject(string: $0) }
        }
    }
    
    var credentialData: [Data]? {
        didSet {
            verifiableObjects = credentialData?.compactMap { VerifiableObject(data: $0) }
        }
    }
    
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem?
    @IBOutlet var addBarButtonItem: UIBarButtonItem?
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let unwindToWalletSegue = "unwindToWallet"
    
    private let toast = Toast()
    
    private var verifiableObjects: [VerifiableObject]? {
        didSet {
            packages = verifiableObjects?.compactMap { verifiableObject in
                var packageDictionary = [String: Any]()
                
                packageDictionary["credential"] = verifiableObject.rawString
                packageDictionary["schema"] = nil
                packageDictionary["issuerMetadata"] = nil
                
                return Package(value: packageDictionary)
            }
        }
    }
    
    private var packages: [Package]? {
        didSet {
            self.updateView()
        }
    }
    
    private func updateView() {
        let isEmpty = packages?.isEmpty ?? true
        
        cancelBarButtonItem?.isEnabled = !isEmpty
        addBarButtonItem?.isEnabled = !isEmpty
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
    
    private func addToWallet() {
        cancelBarButtonItem?.isEnabled = false
        addBarButtonItem?.isEnabled = false
        
        packages?.forEach { package in
            DataStore.shared.savePackage(package)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.showConfirmationToast()
            self.generateNotificationFeedback(.success)
            
            DataStore.shared.loadUserData()
        }
    }
    
    private func showConfirmationToast() {
        toast.label.text = "import.verification.success".localized
        toast.glyph.image = UIImage(systemName: "wallet.pass")
        
        toast.layer.setValue("0.01", forKeyPath: "transform.scale")
        toast.alpha = 0
        view.addSubview(toast)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
            self.toast.alpha = 1
            UIAccessibility.post(notification: .screenChanged, argument: self.toast.label)
            self.toast.layer.setValue(1, forKeyPath: "transform.scale")
        }) { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
                    self.toast.alpha = 0
                    self.toast.layer.setValue(0.8, forKeyPath: "transform.scale")
                }) { (completion) in
                    self.performSegue(withIdentifier: self.unwindToWalletSegue, sender: nil)
                }
            }
        }
    }
    
}

extension ImportCompleteViewController {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return verifiableObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.zero
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == (verifiableObjects?.count ?? 1) - 1 {
            return CGFloat(40.0)
        }
        
        return CGFloat.zero
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == (verifiableObjects?.count ?? 1) - 1 {
            return "import.verification.footer".localized
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let package = packages?[indexPath.section], let cell = tableView.dequeueReusableCell(withIdentifier: "ImportCompleteItemCell", for: indexPath) as? ImportCompleteItemTableViewCell else {
            return UITableViewCell()
        }
        
        cell.populateCell(with: package)
        
        return cell
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
