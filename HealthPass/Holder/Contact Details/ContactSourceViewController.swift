//
//  Contact.swift
//  Holder
//
//  Created by Yevtushenko Valeriia on 17.02.2022.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class ContactSourceViewController: UIViewController {
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        associatedDataTextView.font = AppFont.bodyScaled
        
        if let string = associatedData as? String {
            associatedDataTextView.text = string
        } else if let data = try? JSONSerialization.data(withJSONObject: associatedData ?? [], options: [ .prettyPrinted]), let json = String(data: data, encoding: .utf8) {
            associatedDataTextView.text = json
        }
    }
    
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var associatedDataTextView: UITextView!
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    var associatedData: Any?
}
