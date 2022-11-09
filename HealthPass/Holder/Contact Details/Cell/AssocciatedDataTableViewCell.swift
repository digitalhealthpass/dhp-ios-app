//
//  AssocciatedDataTableViewCell.swift
//  Holder
//
//  Created by Yevtushenko Valeriia on 21.02.2022.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class AssocciatedDataTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var contentLabel: UILabel!
    
    var text: String? {
        didSet {
            contentLabel.text = text
        }
    }
    
}
