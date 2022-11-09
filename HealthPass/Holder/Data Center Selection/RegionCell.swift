//
//  RegionCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class RegionCell: UITableViewCell {
    @IBOutlet weak var regionNameLabel: UILabel!
    @IBOutlet weak var selectionIndicatorImageView: UIImageView!
    
    static let reuseID = "RegionCell"
    
    func populateCell(with title: String, isSelected: Bool) {
        regionNameLabel.text = title
        selectionIndicatorImageView.image = isSelected ? UIImage(systemName: "checkmark") : nil
    }
}
