//
//  TableViewCell.swift
//  HealthPass
//
//  Created by Gautham Velappan on 8/19/20.
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

        separatorInset = UIEdgeInsets.init(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
    }

    func populateCell(with keyPairDictionary: [String: Any]) {

    }

}
