//
//  GetStartedCollectionViewController.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit

struct GetStartedConfig {
    var title: String?
    var detail: String?
    var image: UIImage?
    var finished: Bool?
}

protocol GetStartedCollectionViewControllerDelegate: AnyObject {
    func nextSelected()
    func finishSelected()
}

class GetStartedCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        setupConfig()
        setupView()
    }
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: Private Properties

    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        
        pageControl.currentPage = 0
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        pageControl.pageIndicatorTintColor = .secondaryLabel
        pageControl.currentPageIndicatorTintColor = .label

        return pageControl
    }()

    private var getStartedConfigArray = [GetStartedConfig]()
    
    // MARK: Private Methods
    
    private func setupConfig() {
        getStartedConfigArray = [ GetStartedConfig(title: "gs.step0.title".localized, detail: "gs.step0.message".localized, image: UIImage(named: "Step 0"), finished: false),
                                  GetStartedConfig(title: "gs.step1.title".localized, detail: "gs.step1.message".localized, image: UIImage(named: "Step 1"), finished: false),
                                  GetStartedConfig(title: "gs.step2.title".localized, detail: "gs.step2.message".localized, image: UIImage(named: "Step 2"), finished: true) ]
    }
    
    private func setupView() {
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        
        pageControl.numberOfPages = getStartedConfigArray.count

        view.addSubview(pageControl)
        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        let minimumHeightConstraint = NSLayoutConstraint(item: pageControl, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 44)
        pageControl.addConstraint(minimumHeightConstraint)
        
        let minimumWidthConstraint = NSLayoutConstraint(item: pageControl, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 44)
        pageControl.addConstraint(minimumWidthConstraint)
    }
}

extension GetStartedCollectionViewController {
    // ======================================================================
    // === UICollectionView ==============================================
    // ======================================================================
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getStartedConfigArray.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GetStartedCollectionViewCell", for: indexPath) as? GetStartedCollectionViewCell else {
            return UICollectionViewCell()
        }

        cell.getStartedConfig = getStartedConfigArray[indexPath.item]
        cell.delegate = self
        
        return cell
    }
    
    // ======================================================================
    // === UICollectionViewLayout ==============================================
    // ======================================================================
    
    // MARK: UICollectionViewLayoutDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // ======================================================================
    // === UIScrollView ==============================================
    // ======================================================================
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPage = scrollView.contentOffset.x / view.frame.width
        pageControl.currentPage = Int(currentPage.rounded())
    }

}

extension GetStartedCollectionViewController: GetStartedCollectionViewControllerDelegate {
   
    func nextSelected() {
        let cellSize = CGSize(width: view.frame.width, height: view.frame.height)
        let contentOffset = collectionView.contentOffset

        let offsetHeight = cellSize.height - 64 // eliminates the screen shifting
        let visibleRect = CGRect(x: contentOffset.x + cellSize.width, y: contentOffset.y, width: cellSize.width, height: offsetHeight)
        collectionView.scrollRectToVisible(visibleRect, animated: true)
    }
    
    func finishSelected() {
        DataStore.shared.didGetStarted = true
        performSegue(withIdentifier: "unwindToLaunch", sender: nil)
    }
    
}
