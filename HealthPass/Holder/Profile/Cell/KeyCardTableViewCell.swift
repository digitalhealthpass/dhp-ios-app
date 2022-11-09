//
//  TableViewCell.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class KeyCardTableViewCell: UITableViewCell {
    
    @IBOutlet weak var keyTagLabel: UILabel!
    @IBOutlet weak var keyTimestampLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        keyTagLabel.font = AppFont.headlineScaled
        keyTimestampLabel.font = AppFont.caption1Scaled
        
        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
    }
    
    func populateCell(with keyPair: AsymmetricKeyPair) {
        keyTagLabel.text = "profile.untitled".localized
        keyTimestampLabel.text = nil

        if let tag = keyPair.tag {
            keyTagLabel.text = tag
        }
        if let date = keyPair.timestamp {
            keyTimestampLabel.text = String(format: "profile.createdFormat".localized, date)
        }
    }
}
