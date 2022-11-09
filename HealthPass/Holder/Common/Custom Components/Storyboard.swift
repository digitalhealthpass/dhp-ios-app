//
//  Storyboard.swift
//  Holder
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation
import UIKit

struct Storyboard {
    
    private struct StoryboardName {
        
        static let KeyPairManagement = "KeyPairManagement"
        static let ResearchRegistration = "ResearchRegistration"
        static let OrganizationRegistration = "OrganizationRegistration"
        static let ContactDetails = "ContactDetails"
        static let ScanComplete = "ScanComplete"
        static let Wallet = "Wallet"

    }

    static var KeyPairManagement: UIStoryboard {
        return UIStoryboard(name: StoryboardName.KeyPairManagement, bundle: nil)
    }

    static var ResearchRegistration: UIStoryboard {
        return UIStoryboard(name: StoryboardName.ResearchRegistration, bundle: nil)
    }

    static var OrganizationRegistration: UIStoryboard {
        return UIStoryboard(name: StoryboardName.OrganizationRegistration, bundle: nil)
    }

    static var ContactDetails: UIStoryboard {
        return UIStoryboard(name: StoryboardName.ContactDetails, bundle: nil)
    }

    static var ScanComplete: UIStoryboard {
        return UIStoryboard(name: StoryboardName.ScanComplete, bundle: nil)
    }

    static var Wallet: UIStoryboard {
        return UIStoryboard(name: StoryboardName.Wallet, bundle: nil)
    }

}

struct ControllerIdentifier {
    
    struct Navigation {
        static let KeyPairManagement = "KeyPairManagementNavigationController"
        static let UserAgreement = "UserAgreementNavigationController"
        static let OrgRegistration = "OrgRegistrationNavigationController"
        static let ContactCredentialDownload = "ContactCredentialDownloadNavigationController"
        static let ScanComplete = "ScanCompleteNavigationController"
        static let ContactComplete = "ContactCompleteNavigationController"
    }
    
    struct View {
        static let ContactComplete = "ContactCompleteViewController"
        static let RegistrationDetails = "RegistrationDetailsViewController"
    }
    
}
