//
//  InformationTableViewCell.swift
//  Holder
//
//  Created by Yevtushenko Valeriia on 11.11.2021.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

enum PlaceholderType {
    case card
    case conection
}

class PlaceholderTableViewCell: UITableViewCell {
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet weak var placeholderImageView: UIImageView!
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Methods
    
    func setupCell(with type: PlaceholderType) {
        switch type {
        case .card:
            titleLabel.text = "sectionPlaceholder.cards.title".localized
            descriptionLabel.text = "sectionPlaceholder.cards.description".localized
            placeholderImageView.image = UIImage(named: "cards-placeholder-logo")
        case .conection:
            titleLabel.text =  "sectionPlaceholder.connections.title".localized
            descriptionLabel.text = "sectionPlaceholder.connections.description".localized
            placeholderImageView.image = UIImage(named: "connections-placeholder-logo")
        }
    }
}
