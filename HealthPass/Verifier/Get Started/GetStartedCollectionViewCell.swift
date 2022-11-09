//
//  GetStartedCollectionViewCell.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

class GetStartedCollectionViewCell: UICollectionViewCell {
    // MARK: - IBOutlet
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var finishButton: Button!
    
    // MARK: - IBAction
    
    @IBAction func onFinished(_ sender: Any) {
        if isFinished {
            delegate?.finishSelected()
            return
        }
        
        delegate?.nextSelected()
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: Internal Properties
    
    weak var delegate : GetStartedCollectionViewControllerDelegate?

    var getStartedConfig: GetStartedConfig? {
        didSet {
            setupCell()
        }
    }
    
    var isFinished: Bool {
        return getStartedConfig?.finished ?? true
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Methods
    
    private func setupCell() {
        titleLabel.font = AppFont.title1Scaled
        detailLabel.font = AppFont.bodyScaled
        finishButton.titleLabel?.font = AppFont.headlineScaled
        
        titleLabel.text = getStartedConfig?.title
        detailLabel.text = getStartedConfig?.detail
        
        imageView.image = getStartedConfig?.image
        if let finished = getStartedConfig?.finished, finished {
            finishButton.setTitle("gs.finishButtonTitle.getStarted".localized, for: .normal)
        } else {
            finishButton.setTitle("gs.verifier.buttonTitle.continue".localized, for: .normal)
        }
        
        layoutIfNeeded()
        setNeedsDisplay()
    }
}
