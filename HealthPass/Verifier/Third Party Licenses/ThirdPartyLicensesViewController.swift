//
//  ThirdPartyLicensesViewController.swift
//  Verifier
//
//  Created by Gautham Velappan on 3/4/22.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import WebKit
import PDFKit

class ThirdPartyLicensesViewController: UIViewController {

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        //setupPDFViewer()
        displayWebView()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem?
    
    // MARK: - IBAction
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: Private Properties

    private let pdfView = PDFView()
    
    // MARK: Private Methods

    private func displayWebView() {
        if let webView = self.createWebView(withFrame: self.view.bounds) {
            self.view.addSubview(webView)
        }
    }

    private func createWebView(withFrame frame: CGRect) -> WKWebView? {
        let webView = WKWebView(frame: frame)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let resourceUrl = self.resourceUrl(forFileName: "Third Party Notices") {
            webView.loadFileURL(resourceUrl, allowingReadAccessTo: resourceUrl)
            return webView
        }
        
        return nil
    }

    private func resourceUrl(forFileName fileName: String) -> URL? {
        if let resourceUrl = Bundle.main.url(forResource: fileName, withExtension: "pdf") {
            return resourceUrl
        }
        
        return nil
    }

    private func setupPDFViewer() {
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)

        pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        guard let path = Bundle.main.url(forResource: "Third Party Notices", withExtension: "pdf") else { return }

        if let document = PDFDocument(url: path) {
            pdfView.document = document
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
