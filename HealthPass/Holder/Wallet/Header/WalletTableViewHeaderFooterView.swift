//
//  WalletTableViewHeaderFooterView.swift
//  Holder
//
//  Created by Yevtushenko Valeriia on 12.11.2021.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class WalletTableViewHeaderFooterView: UITableViewHeaderFooterView {
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addButton.setTitle("", for: .normal)
        titleLabel.font = UIFont(name: AppFont.bold, size: 20)
    }
    
    // MARK: - IBOutlet
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addButton: UIButton!
    
    // MARK: - IBAction
    
    @IBAction private func onAdd() {
        onAddDidTap?()
    }

    // MARK: Internal Properties
    
    var onAddDidTap: (() -> ())?
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
}
