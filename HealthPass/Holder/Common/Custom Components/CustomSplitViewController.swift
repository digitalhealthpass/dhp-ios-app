//
//  CustomSplitViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class CustomSplitViewController: UISplitViewController {
    
    let maximimWidth = CGFloat(428.0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredDisplayMode = .allVisible
        
        preferredPrimaryColumnWidthFraction = 0.5
        
        let requiredWidth = maximimWidth < (view.frame.width/2) ? maximimWidth : (view.frame.width/2)
        minimumPrimaryColumnWidth = requiredWidth
        maximumPrimaryColumnWidth = requiredWidth
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
