//
//  ScanViewController.swift
//  Verifier
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import UIKit
import AVFoundation
import QRCoder
import VerifiableCredential
import VerificationEngine

class ScanViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Network.reachabilityManager?.listener = { status in
            self.offlineModeView.isHidden = !(status == .notReachable || status == .unknown)
        }
        
        Network.reachabilityManager?.startListening()
        
        instructionLabel.font = AppFont.title3Scaled
        statusLabel.font = AppFont.title3Scaled
        
        enableGestures()
        
        prepareView()
        
        startScanner()
        
        startMetricsLimitCheck()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        profileButton.accessibilityLabel = "accessibility.settings".localized
        
        refreshScanView()

        //test()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    
    @IBOutlet weak var scannerView: QRCodeScannerView!
    @IBOutlet weak var instructionLabel: UILabel!

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var organizationView: UIView!
    @IBOutlet weak var organizationImage: UIImageView!
    @IBOutlet weak var organizationTitle: UILabel!
    @IBOutlet weak var organizationDetail: UILabel!
    @IBOutlet weak var organizationExpiration: UILabel!
    
    @IBOutlet weak var offlineModeView: UIView!
    
    // MARK: - IBAction Methods
    
    @IBAction func onToggle(_ sender: Any) {
        scannerView.toggleCameraPosition()
        flashButton.isHidden = !(scannerView.hasTorch)
    }
    
    @IBAction func onFlash(_ sender: Any) {
        scannerView.toggleFlash()
    }
    
    @IBAction func onSettings(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl, completionHandler: nil)
    }
    
    @objc func refreshScanView() {
        self.flashButton.isHidden = !(self.scannerView.hasTorch)
        self.toggleButton.isHidden = !(self.scannerView.hasFrontCamera)
        
        self.checkCameraPosition()
    }
    
    // MARK: - Navigation
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        isTopView = false
        scannerView.stopScanner()
        
        if segue.identifier == showScanResultSegue, let verifiableObject = sender as? VerifiableObject {
            if let navigationController = segue.destination as? UINavigationController,
               let resultViewController = navigationController.viewControllers.first as? ResultViewController {
                resultViewController.verifiableObject = verifiableObject
                navigationController.presentationController?.delegate = self
            }
        } else if segue.identifier == showCameraAccessSegue, let cameraAccessViewController = segue.destination as? CameraAccessViewController {
            cameraAccessViewController.scannerView = sender as? QRCodeScannerView
        } else if segue.identifier == showOrganizationDetailsSegue, let credential = sender as? Credential,
                  let navigationController = segue.destination as? UINavigationController,
                  let organizationDetailsTableViewController = navigationController.viewControllers.first as? OrganizationDetailsTableViewController {
            organizationDetailsTableViewController.credential = credential
        }
        
    }
    
    @IBAction func unwindToScan(segue: UIStoryboardSegue) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.isTopView = true
            
            if let _ = segue.source as? CameraAccessViewController {
                self.startScanner()
            } else {
                self.scannerView.startScanner()
            }
            
            self.prepareView()
        }
    }
    
    // ======================================================================
    // MARK: - Internal
    // ======================================================================
    
    // MARK: - Internal Properties
    
    internal var metricsUploadTimer: Timer? = nil
    
    internal var currentOrganization: Package?
    
    internal let showScanResultSegue = "showScanResult"
    
    internal let showOrganizationDetailsSegue = "showOrganizationDetails"
    internal let unwindToLaunchSegue = "unwindToLaunch"
    internal let showCameraAccessSegue = "showCameraAccess"
    
    // MARK: - Internal Methods
    
    internal func showResult(for verifiableObject: VerifiableObject? = nil) {
        if let verifiableObject = verifiableObject {
            showResult(verifiableObject: verifiableObject)
        } else {
            showErrorAlert(title: "scan.invalid.title".localized, message: "scan.invalid.message".localized)
        }
    }
    
    
    // ======================================================================
    // MARK: - Private
    // ======================================================================
    
    // MARK: - Private Properties
    
    private let scanButtonTitle = "scan.scan.buttonTitle".localized
    private let settingsButtonTitle = "scan.settings.buttonTitle".localized
    
    private var isTopView: Bool = true
    
    // MARK: - Private Methods
    
    private func enableGestures() {
        let organizationViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(onOrganizationViewTap))
        organizationView.addGestureRecognizer(organizationViewTapGesture)
        
        let offlineViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(onOfflineViewTap))
        offlineModeView.addGestureRecognizer(offlineViewTapGesture)
    }
    
    private func prepareView() {
        organizationView.isHidden = true
        statusLabel.isHidden = false
        
        self.currentOrganization = DataStore.shared.currentOrganization
        
        if let currentOrganization = currentOrganization {
            showOrganizationFooter(currentOrganization)
        } else if let activeOrganization = DataStore.shared.allOrganization?.filter({ !($0.credential?.isExpired ?? false) }), !(activeOrganization.isEmpty) {
            showSelectOrganization()
        }
    }
    
    private func startScanner() {
        showInfoView(false)
        scannerView.delegate = self
        
        if scannerView.getCameraStatus() == .authorized {
            self.scannerView.initializeScanner { isAuthorized in
                if isAuthorized {
                    self.scannerView.stopScannerAfterDecode = false
                    self.scannerView.showScanFrame = true
                    
                    self.showInfoView(true)
                    UIAccessibility.post(notification: .screenChanged, argument: self.statusLabel)
                    self.refreshScanView()
                } else {
                    self.performSegue(withIdentifier: self.showCameraAccessSegue, sender: self.scannerView)
                }
            }
        } else {
            self.performSegue(withIdentifier: self.showCameraAccessSegue, sender: self.scannerView)
        }
    }
    
    private func checkCameraPosition() {
        if DataStore.shared.frontCameraState {
            self.scannerView.frontCameraPosition()
        } else {
            self.scannerView.backCameraPosition()
        }
    }
    
    private func showInfoView(_ show: Bool) {
        self.toggleButton.isHidden = !show
        self.flashButton.isHidden = !show
        self.statusLabel.isHidden = !show
        self.instructionLabel.isHidden = !show
    }
    
    private func showResult(verifiableObject: VerifiableObject) {
        self.performSegue(withIdentifier: showScanResultSegue, sender: verifiableObject)
    }
    
    @objc func onOrganizationViewTap() {
        performSegue(withIdentifier: "showOrganizationList", sender: nil)
    }
    
    @objc func onOfflineViewTap() {
        self.showConfirmation(title: "Now in Offline Mode",
                              message: "You can continue to verify health passes and cards while this app is offline",
                              actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)],
                              completion: { _ in
            self.scannerView.startScanner()
        },
                              presentCompletion: {
            self.scannerView.stopScanner()
        })
    }
    
}

extension ScanViewController: QRCodeScannerViewDelegate {
    // ======================================================================
    // MARK: - QRCodeScannerViewDelegate
    // ======================================================================
    
    func scannerView(_ scannerView: QRCodeScannerView, didScanQRCodeMessages messages: [String]) { }
    
    func scannerView(_ scannerView: QRCodeScannerView, didScanQRCodeDetails details: [[String : Any]]) {
        var verifiableObjects: [VerifiableObject]?
        
        let messages = (details.compactMap { $0["message"] as? String ?? $0["rawMessage"] as? String }).filter { !($0.isEmpty) }
        let errorCorrectedPayload = (details.compactMap { $0["errorCorrectedPayload"] as? Data}).filter { !($0.isEmpty) }
        
        if !(messages.isEmpty) {
            verifiableObjects = messages.compactMap { VerifiableObject(string: $0) }
        } else if !(errorCorrectedPayload.isEmpty) {
            
            let payloadData = errorCorrectedPayload.compactMap { Data(bytes: zip($0.advanced(by: 2), $0.advanced(by: 3)).map { (byte1, byte2) in
                return byte1 << 4 | byte2 >> 4
            }) }
            
            verifiableObjects = payloadData.compactMap { VerifiableObject(data: $0) }
        }
        
        guard let verifiableObject = verifiableObjects?.first else {
            showErrorAlert(title: "scan.invalid.title".localized, message: "scan.invalid.message".localized)
            return
        }
        
        if let credential = verifiableObject.credential, credential.isOrganizationCredential {
            handleOrganizationCredential(credential: credential)
        }
        
        guard checkOrganization() else { return }
        guard checkOrganizationValidity() else { return }
        
        scannerView.stopScanner()
        showResult(for: verifiableObject)
    }
    
    func scannerView(_ scannerView: QRCodeScannerView, didReceiveError error: Error) {
        showErrorAlert(title: "scan.invalid.title".localized, message: "scan.invalid.message".localized)
    }
    
    private func showErrorAlert(title: String, message: String) {
        showConfirmation(title: title,
                         message: message,
                         actions: [("button.title.ok".localized, IBMAlertActionStyle.cancel)],
                         completion:  { _ in
            if self.isTopView {
                self.scannerView.startScanner()
            }
        }, presentCompletion: {
            self.scannerView.stopScanner()
        })
    }
    
}

extension ScanViewController {
    
    func test() {
        //DCC
        //let messages = ["HC1:NCFOXN%TS3DH3ZSUZK+.V0ETD%65NL-AH-R6IOOK.IR9B+9G4G50PHZF0AT4V22F/8X*G3M9JUPY0BX/KR96R/S09T./0LWTKD33236J3TA3M*4VV2 73-E3GG396B-43O058YIB73A*G3W19UEBY5:PI0EGSP4*2DN43U*0CEBQ/GXQFY73CIBC:G 7376BXBJBAJ UNFMJCRN0H3PQN*E33H3OA70M3FMJIJN523.K5QZ4A+2XEN QT QTHC31M3+E32R44$28A9H0D3ZCL4JMYAZ+S-A5$XKX6T2YC 35H/ITX8GL2-LH/CJTK96L6SR9MU9RFGJA6Q3QR$P2OIC0JVLA8J3ET3:H3A+2+33U SAAUOT3TPTO4UBZIC0JKQTL*QDKBO.AI9BVYTOCFOPS4IJCOT0$89NT2V457U8+9W2KQ-7LF9-DF07U$B97JJ1D7WKP/HLIJL8JF8JFHJP7NVDEBU1J*Z222E.GJ457661CFFTWM-8P2IUE7K*SSW613:9/:TT5IYQBTBU16R4I1A/9VRPJ-TS.7ZEM7MSVOCD4RG2L-TQJROXL2J:52J7F0Q10SMAP3CG3KHF0DWIH"]
        
        //DCC
        //let messages = ["HC1:6BFOXN%TS3DH1QG9WA6H98BRPRHO DJS4F3S-%2LXKQGLAVDQ81LO2-36/X0X6BMF6.UCOMIN6R%E5UX4795:/6N9R%EPXCROGO3HOWGOKEQBKL/645YPL$R-ROM47E.K6K8I115DL-9C1QD+82D8C+ CH8CV9CA$DPN0NTICZU80LZW4Z*AK.GNNVR*G0C7PHBO33/X086BTTTCNB*UJHMJ8J3HONNQN09B5PNVNNWGJZ730DNHMJSLJ*E3G23B/S7-SN2H N37J3 QTULJ7CB3ZC6.27AL4%IY.IQH5YRT5*K51T 1DT 456L X4CZKHKB-43.E3KD3OAJ/9TL4T1C9 UP IPGTUI7FKQU2N1L8VFLU9WU.B9 UPYR181A0+P8V7/JA--J/XTQWE/PEBLEH-BY.CECH$6KJEM*PC9JAU-BZ8ERJCS0DUMQI+O1-ST*QGTA4W7.Y7G+SB.V Q5NN9TJ1TM8554.8EW E2NS6F9$J3-MQPSUB*H1EI+TUN73 39EX4165ABSXFB487V*K9J8UJC08H3N7T:DAIJC8K8T3TCF*6P.OB9Q721UJ+K.OJ4EW/S1*13PNG"]
        
        
        //VCI
        let messages = ["shc:/5676290952432060346029243740446031222959532654603460292540772804336028702864716745222809286241223803127633772937404037614124294155414509364367694562294037054106322567213239452755415503563944035363327154065460573601064529315312707424283950386922127665692556406006755827381263204052296731073633336938032657205862295436331233001038777166267636080841395530320800652165762441362803242857077523526658582376617444074234353670540063112906665420274436523366382304602107767029707171334108734276684565635208375565457563322471672760357021665706085950625412002674423522224030506963232661415312244132090030453772406306417423662309532523260843360611573335546928636952121165576620063352423445634359263550040933717135282666502161411060535328357507067026205662030867662176550358331239376030354273507464583735110504295868572522002173252857647240335911202037376465607440553126595038263970046656405673746131356344086926543072252440506367244563433356534066680341557461756531106867066553770055003036753775232262724306592473682129383062706963764322332904767209381153203524540675505523331235666055060843543133254025035967745422762336295543622911066934442359426234757003523363530611063822286508566139256656124156522068253558626433374141736523530427126029625529093765366823256865346812432923416903366712115464253640425868606269403165075577444527664075575042682312435045443305115507344373232739127570015337743958387633706808342204723059403677730037776870557454675839075737432329107350426656345261586855215764266923665627220610056306387757323974697554376377395250746439382058"]
        
        //IDHP
        //let messages = ["{\n        \"@context\": [\n            \"https://www.w3.org/2018/credentials/v1\"\n        ],\n        \"id\": \"did:hpass:5c3caed09426bda7eb7ea51973b7d1eb87c3ec5b472163935ee05e757ecf10fe:f2fff85d420e498de8faa5ca567472c42e522a13f1c18e875a54ef0abdb76c9f#vc-d5d80989-f8f6-4b1e-a613-9b5841ce0e08\",\n        \"type\": [\n            \"VerifiableCredential\"\n        ],\n        \"issuer\": \"did:hpass:5c3caed09426bda7eb7ea51973b7d1eb87c3ec5b472163935ee05e757ecf10fe:f2fff85d420e498de8faa5ca567472c42e522a13f1c18e875a54ef0abdb76c9f\",\n        \"issuanceDate\": \"2021-02-16T04:38:10Z\",\n        \"expirationDate\": \"2021-12-07T00:00:00Z\",\n        \"credentialSchema\": {\n            \"id\": \"did:hpass:5c3caed09426bda7eb7ea51973b7d1eb87c3ec5b472163935ee05e757ecf10fe:f2fff85d420e498de8faa5ca567472c42e522a13f1c18e875a54ef0abdb76c9f;id=test;version=0.2\",\n            \"type\": \"JsonSchemaValidator2018\"\n        },\n        \"credentialSubject\": {\n            \"display\": \"limegreen\",\n            \"occurenceDate\": \"2020-12-07T00:00:00Z\",\n            \"result\": \"Negative\",\n            \"subject\": {\n                \"address\": \"\",\n                \"birthDate\": \"2000-10-10\",\n                \"email\": \"\",\n                \"gender\": \"female\",\n                \"identity\": [\n                    {\n                        \"system\": \"travel.state.gov\",\n                        \"type\": \"PPN\",\n                        \"value\": \"AP12345F\"\n                    }\n                ],\n                \"name\": {\n                    \"family\": \"Smith\",\n                    \"given\": \"Jane\"\n                },\n                \"phone\": \"\"\n            },\n            \"testCode\": \"94500-6\",\n            \"testId\": \"Order Number\",\n            \"testType\": \"SARS-CoV-2 (COVID-19) RNA [Presence] in Respiratory specimen by NAA with probe detection\",\n            \"type\": \"Covid-19 PCR Test\"\n        },\n        \"proof\": {\n            \"created\": \"2021-02-16T04:38:10Z\",\n            \"creator\": \"did:hpass:5c3caed09426bda7eb7ea51973b7d1eb87c3ec5b472163935ee05e757ecf10fe:f2fff85d420e498de8faa5ca567472c42e522a13f1c18e875a54ef0abdb76c9f#key-1\",\n            \"nonce\": \"a664672f-ede2-4647-a3ec-3f196c53e26b\",\n            \"signatureValue\": \"MEUCIQDNwOPSyJhdjnsVMbutL5CThAvXzwtig3opeBKpMCDD1AIgZitTedO7AAFr13lRTo400S96sDm5D8ljCdPQdGxwtXo\",\n            \"type\": \"EcdsaSecp256r1Signature2019\"\n        }\n    }"]
        
        //GHP
        //let messages = ["{\n  \"@context\": [\n    \"https://www.w3.org/2018/credentials/v1\"\n  ],\n  \"credentialSchema\": {\n    \"id\": \"did:hpass:19b0cf0d5fc7017dd66ddd2374fbd9b796d988aced083d709abbaa0f7480b474:c4d1492e81bfcb951d028c0a4bd3c1edec16d32aed77a608c76ed917f3231f7e;id=ghp-vaccination-credential;version=0.3\",\n    \"type\": \"JsonSchemaValidator2018\"\n  },\n  \"credentialSubject\": {\n    \"countryOfTest\": \"us\",\n    \"dateOfResult\": \"2020-12-30\",\n    \"dateOfSample\": \"2020-12-30\",\n    \"disease\": \"Covid-19\",\n    \"display\": \"#32CD32\",\n    \"recipient\": {\n      \"birthDate\": \"2000-10-10\",\n      \"familyName\": \"Smith\",\n      \"givenName\": \"Jane\",\n      \"middleName\": \"Sarah\"\n    },\n    \"stateOfTest\": \"ca\",\n    \"testCommercialName\": \"BinaxNOWTM COVID-19 Ag CARD\",\n    \"testManufacturer\": \"Abbott Rapid Diagnostics\",\n    \"testResult\": \"260415000\",\n    \"testType\": \"SARS-CoV-2 (COVID-19) Ag [Presence] in Respiratory specimen by Rapid immunoassay\",\n    \"testingCentre\": \"Acme Test Site\",\n    \"type\": \"Test Results\"\n  },\n  \"expirationDate\": \"2021-12-31T00:00:00Z\",\n  \"id\": \"did:hpass:19b0cf0d5fc7017dd66ddd2374fbd9b796d988aced083d709abbaa0f7480b474:c4d1492e81bfcb951d028c0a4bd3c1edec16d32aed77a608c76ed917f3231f7e#vc-934a8b60-9ad2-4c95-afe9-7cf34562d35c\",\n  \"issuanceDate\": \"2021-07-06T12:18:11Z\",\n  \"issuer\": \"did:hpass:19b0cf0d5fc7017dd66ddd2374fbd9b796d988aced083d709abbaa0f7480b474:c4d1492e81bfcb951d028c0a4bd3c1edec16d32aed77a608c76ed917f3231f7e\",\n  \"proof\": {\n    \"created\": \"2021-07-06T12:18:11Z\",\n    \"creator\": \"did:hpass:19b0cf0d5fc7017dd66ddd2374fbd9b796d988aced083d709abbaa0f7480b474:c4d1492e81bfcb951d028c0a4bd3c1edec16d32aed77a608c76ed917f3231f7e#key-1\",\n    \"nonce\": \"2ba4914a-4c64-4a7c-b508-4bb8c6811f82\",\n    \"signatureValue\": \"MEUCIAgDfTQb16ZIy3-0Zn-uoBkxcy4CJtO_WDGZwmyqLDk5AiEA7WZiO6I2bTrJ9sFbAiOqcbOFYzJYCQ3JbewHsg0LjwA\",\n    \"type\": \"EcdsaSecp256r1Signature2019\"\n  },\n  \"type\": [\n    \"VerifiableCredential\",\n    \"GoodHealthPass\",\n    \"TestCredential\"\n  ]\n}"]
        
        //GHP
        //let messages = ["{\"@context\":[\"https://www.w3.org/2018/credentials/v1\"],\"id\":\"did:hpass:19b0cf0d5fc7017dd66ddd2374fbd9b796d988aced083d709abbaa0f7480b474:c4d1492e81bfcb951d028c0a4bd3c1edec16d32aed77a608c76ed917f3231f7e#vc-c509f964-0b6a-4214-8562-3e5f08112a72\",\"type\":[\"VerifiableCredential\",\"GoodHealthPass\",\"RecoveryCredential\"],\"issuer\":\"did:hpass:19b0cf0d5fc7017dd66ddd2374fbd9b796d988aced083d709abbaa0f7480b474:c4d1492e81bfcb951d028c0a4bd3c1edec16d32aed77a608c76ed917f3231f7e\",\"issuanceDate\":\"2021-07-06T12:15:32Z\",\"expirationDate\":\"2021-12-31T00:00:00Z\",\"credentialSchema\":{\"id\":\"did:hpass:19b0cf0d5fc7017dd66ddd2374fbd9b796d988aced083d709abbaa0f7480b474:c4d1492e81bfcb951d028c0a4bd3c1edec16d32aed77a608c76ed917f3231f7e;id=ghp-recovery-credential;version=0.1\",\"type\":\"JsonSchemaValidator2018\"},\"credentialSubject\":{\"certificateValidFrom\":\"2021-03-15\",\"certificateValidTo\":\"2021-06-15\",\"countryOfTest\":\"us\",\"dateOfFirstPositiveResult\":\"2021-03-01\",\"disease\":\"Covid-19\",\"display\":\"#32CD32\",\"recipient\":{\"birthDate\":\"2000-10-10\",\"familyName\":\"Smith\",\"givenName\":\"Jane\",\"middleName\":\"Sarah\"},\"type\":\"Proof of Recovery\"},\"proof\":{\"created\":\"2021-07-06T12:15:32Z\",\"creator\":\"did:hpass:19b0cf0d5fc7017dd66ddd2374fbd9b796d988aced083d709abbaa0f7480b474:c4d1492e81bfcb951d028c0a4bd3c1edec16d32aed77a608c76ed917f3231f7e#key-1\",\"nonce\":\"1be784d6-143e-4454-ad2f-f1ec72cd6d04\",\"signatureValue\":\"MEQCIE2vjW1164LCYNkLKc0C0SQgtgWIsAd5wRNmOpbbkF2QAiARjX-_UknCeQEOirGD0ECypEtZ9FjGG7MxrGHe8c85nQ\",\"type\":\"EcdsaSecp256r1Signature2019\"}}"]
        
        let verifiableObjects = messages.compactMap { VerifiableObject(string: $0) }
        
        guard let verifiableObject = verifiableObjects.first else {
            return
        }
        
        scannerView.stopScanner()
        showResult(for: verifiableObject)
    }
    
}

