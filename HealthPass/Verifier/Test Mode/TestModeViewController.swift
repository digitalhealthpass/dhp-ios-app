//
//  TestModeViewController.swift
//  Verifier
//
//  Created by John Martino on 2021-09-09.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit
import PhotosUI
import QRCoder
import VerificationEngine

class TestModeViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var verifyAll: UIButton!
    @IBOutlet weak var removeAll: UIButton!
    @IBOutlet weak var verifySelected: UIButton!
    @IBOutlet weak var removeSelected: UIButton!

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkVerifierCredential()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DataStore.shared.testCredentialItems = testCredentialItems.map({ testCredentialItem in
            let item = TestCredentialItem(verifiableObject: testCredentialItem.verifiableObject,
                                          image: testCredentialItem.image,
                                          imageName: testCredentialItem.imageName,
                                          status: .untested,
                                          errorMessage: "")
            return item
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showResult", let testCredentialItem = sender as? TestCredentialItem {
            if let navigationController = segue.destination as? UINavigationController,
               let resultViewController = navigationController.viewControllers.first as? ResultViewController {
                resultViewController.testMode = true
                resultViewController.verifiableObject = testCredentialItem.verifiableObject
            }
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func onVerifyAll(_ sender: UIButton) {
        updateTable()
        
        for (index, var item) in testCredentialItems.enumerated() {
            item.status = .testing
            item.errorMessage = nil
            testCredentialItems[index] = item
            
            verify(testCredential: item, at: index)
        }
    }
    
    @IBAction func onRemoveAll(_ sender: UIButton) {
        testCredentialItems = [TestCredentialItem]()
        
        updateTable()
    }
    
    @IBAction func onVerifySelected(_ sender: UIButton) {
        guard let indices = tableView.indexPathsForSelectedRows?.compactMap({ $0.row }), !(indices.isEmpty) else {
            return
        }
        
        for (index, var item) in testCredentialItems.enumerated() {
            if indices.contains(index) {
                item.status = .testing
                item.errorMessage = nil
                testCredentialItems[index] = item
                
                verify(testCredential: item, at: index)
            }
        }
        
        onEdit()
        updateTable()
    }
    
    @IBAction func onRemoveSelected(_ sender: UIButton) {
        guard let indices = tableView.indexPathsForSelectedRows?.compactMap({ $0.row }) else {
            return
        }
        
        for index in indices.sorted(by: >) {
            testCredentialItems.remove(at: index)
        }
        
        onEdit()
        updateTable()
    }
    
    @objc func onAddImages() {
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 0
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.modalPresentationStyle = .popover
            imagePickerController.delegate = self
            
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.present(self.imagePickerController, animated: true)
                    }
                }
            }
        }
    }
    
    @objc func onShareResults() {
        //Log only tested credentials
        let filteredTestCredentialItems = testCredentialItems.filter({ $0.status != .untested  })

        guard !filteredTestCredentialItems.isEmpty else {
            self.showConfirmation(title: "No Test Logs".localized,
                                  message: "There are no test results to log. Please verify credentials and try again.".localized,
                                  actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)])
            return
        }
        
        let verifierCredentialInfo = DataStore.shared.currentOrganization?.credential?.credentialSubject?["configId"] as? String
        let verifierCredentialInfoComponents = verifierCredentialInfo?.components(separatedBy: ":")
        
        let verifierCredentialId = verifierCredentialInfoComponents?.first ?? String("Unknown-Customer-Id")
        let device = String("iOS")
        let appVersionNumber = Bundle.main.appVersionNumber ?? String("Unknown-App-Version")
        
        let fileName = String("\(verifierCredentialId)_\(device)_\(appVersionNumber).csv")
        guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName) else {
            //TODO: No Path - Error Handle here
            return
        }
        
        var csvText = "Name,Spec,Status,Error\n"
        
        filteredTestCredentialItems.forEach { item in
            let newLine = "\(item.imageName ?? String("N/A")),\(item.verifiableObject.type.keyId),\(item.status.displayValue),\(item.errorMessage ?? String("N/A"))\n"
            csvText.append(newLine)
        }
        
        guard let _ = try? csvText.write(to: path, atomically: true, encoding: String.Encoding.utf8) else {
            //TODO: Write failed - Error Handle here
            return
        }
        
        let filesToShare = [path]
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.barButtonItem = self.navigationItem.rightBarButtonItems?[1]
            
            popoverController.permittedArrowDirections = [.up]
        }

        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func onEdit() {
        let isEditing = self.tableView.isEditing
        tableView.setEditing(!isEditing, animated: false)
        
        updateComponents()
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    internal var testCredentialItems = [TestCredentialItem]() {
        didSet {
            updateTable()
        }
    }
    
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private var imagePickerController: UIImagePickerController!
    
    private var addBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem.init(image: UIImage(systemName: "plus.circle.fill"), style: .done, target: self, action: #selector(onAddImages))
    }
    
    private var shareBarButtonItem: UIBarButtonItem { //pencil.circle.fill
        return UIBarButtonItem.init(image: UIImage(systemName: "pencil.circle.fill"), style: .done, target: self, action: #selector(onShareResults))
    }
    
    private var editBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem.init(image: UIImage(systemName: "ellipsis.circle.fill"), style: .done, target: self, action: #selector(onEdit))
    }
    
    // MARK: Private Methods
    
    private func checkVerifierCredential() {
        guard DataStore.shared.currentOrganization != nil else {
            showConfirmation(title: "ScanView.no.organization.title".localized,
                             message: "ScanView.no.organization.message".localized,
                             actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)]) { _ in
                self.navigationController?.popViewController(animated: true)
            }
            return
        }
        
        testCredentialItems = DataStore.shared.testCredentialItems
    }
    
    private func setupView() {
        navigationItem.title = "Test Mode"
        
        verifyAll.layer.cornerRadius = 5
        removeAll.layer.cornerRadius = 5
        verifySelected.layer.cornerRadius = 5
        removeSelected.layer.cornerRadius = 5
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        updateComponents()
    }
    
    private func updateTable() {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
            
            self.updateComponents()
        }
    }
    
    private func updateComponents() {
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItems = self.testCredentialItems.isEmpty ? [self.addBarButtonItem] : [self.addBarButtonItem, self.shareBarButtonItem, self.editBarButtonItem]

            let isEditing = self.tableView.isEditing
            self.verifyAll.isHidden = isEditing
            self.removeAll.isHidden = isEditing
            
            self.verifySelected.isHidden = !isEditing
            self.removeSelected.isHidden = !isEditing
            
            self.verifyAll.isEnabled = !(self.testCredentialItems.isEmpty)
            self.verifyAll.backgroundColor = self.verifyAll.isEnabled ? .systemBlue : .systemGray
            
            self.verifySelected.isEnabled = !(self.testCredentialItems.isEmpty)
            self.verifySelected.backgroundColor = self.verifySelected.isEnabled ? .systemBlue : .systemGray
        }
    }
    
    private func verify(testCredential: TestCredentialItem, at index: Int) {
        DispatchQueue.global(qos: .background).async {
            QRCodeDecoder().decode(image: testCredential.image) { messages, details, error in
                let detailsMessages = details?.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }
                guard let message = messages?.first ?? detailsMessages?.first else {
                    self.showFailedState(at: index, with: error)
                    return
                }
                
                let verifiableObject = VerifiableObject(string: message)
                let verifyEngine = VerifyEngine(verifiableObject: verifiableObject)
                
                let verifier = TestCredentialVerifier()
                verifier.verifiableObject = verifiableObject
                verifier.verifyEngine = verifyEngine
                
                guard let currentVerifierConfiguration = DataStore.shared.currentVerifierConfiguration else { return }

                if currentVerifierConfiguration.isLegacyConfiguration {
                    verifier.isKnown()
                        .then { _ in verifier.isNotRevoked() }
                        .then { _ in verifier.isValidSignature() }
                        .then { _ in verifier.doesMatchRules() }
                        .done { _ in self.showSuccessState(at: index) }
                        .catch { error in self.showFailedState(at: index, with: error) }
                        .finally {
                            DispatchQueue.main.async {
                                self.updateTable()
                            }
                        }
                } else {
                    verifier.isKnown(with: currentVerifierConfiguration)
                        .then { _ in verifier.isNotRevoked(with: verifier.specificationConfiguration) }
                        .then { _ in verifier.isValidSignature(with: verifier.specificationConfiguration) }
                        .then { _ in verifier.doesMatchRules(with: verifier.specificationConfiguration) }
                        .done { _ in self.showSuccessState(at: index) }
                        .catch { error in self.showFailedState(at: index, with: error) }
                        .finally {
                            DispatchQueue.main.async {
                                self.updateTable()
                            }
                        }
                }
            }
        }
    }
    
    private func showFailedState(at index: Int, with error: Error?) {
        guard index < testCredentialItems.count else {
            return
        }
        
        let item = testCredentialItems[index]
        testCredentialItems[index] = TestCredentialItem(verifiableObject: item.verifiableObject,
                                                        image: item.image,
                                                        imageName: item.imageName,
                                                        status: .failure,
                                                        errorMessage: error?.localizedDescription ?? "")
    }
    
    private func showSuccessState(at index: Int) {
        guard index < testCredentialItems.count else {
            return
        }
        
        let item = testCredentialItems[index]
        testCredentialItems[index] = TestCredentialItem(verifiableObject: item.verifiableObject,
                                                        image: item.image,
                                                        imageName: item.imageName,
                                                        status: .success,
                                                        errorMessage: "")
    }
}

extension TestModeViewController: PHPickerViewControllerDelegate {
    // ======================================================================
    // === PHPickerViewControllerDelegate ==============================================
    // ======================================================================
    
    // MARK: - PHPickerViewControllerDelegate
    
    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let itemProviders = results.compactMap({ $0.itemProvider })
        
        itemProviders.forEach { itemProvider in
            itemProvider.loadObject(ofClass: UIImage.self) { item, error in
                if let image = item as? UIImage {
                    QRCodeDecoder().decode(image: image) { messages, details, error in
                        let detailsMessages = details?.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }
                        if let message = messages?.first ?? detailsMessages?.first {
                            let verifiableObject = VerifiableObject(string: message)
                            let item = TestCredentialItem(verifiableObject: verifiableObject,
                                                          image: image,
                                                          imageName: itemProvider.suggestedName,
                                                          status: .untested,
                                                          errorMessage: "")
                            self.testCredentialItems.append(item)
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            picker.dismiss(animated: true)
        }
    }
    
}

extension TestModeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // ======================================================================
    // === UIImagePickerControllerDelegate ==============================================
    // ======================================================================
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        DispatchQueue.main.async {
            if let image = info[.originalImage] as? UIImage {
                QRCodeDecoder().decode(image: image) { messages, details, error in
                    let detailsMessages = details?.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }
                    if let message = messages?.first ?? detailsMessages?.first {
                        let verifiableObject = VerifiableObject(string: message)
                        let item = TestCredentialItem(verifiableObject: verifiableObject,
                                                      image: image,
                                                      imageName: nil,
                                                      status: .untested,
                                                      errorMessage: "")
                        self.testCredentialItems.append(item)
                    }
                }
            }
        }
    }
    
}
