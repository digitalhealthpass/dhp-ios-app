//
//  ConcentReceiptUnitTests.swift
//  HolderUnitTests
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import XCTest
@testable import IBM_Wallet

class ConcentReceiptUnitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testKeysGeneration() {

        KeyGen.generateNewKeys { (publicKey: SecKey?, privateKey: SecKey?, error: Error?) in

            XCTAssertNil(error)
            XCTAssertNotNil(publicKey)
            XCTAssertNotNil(privateKey)
        }
    }

    func testPrivateKeyGeneration() {

        KeyGen.generateNewKeys { (publicKey: SecKey?, privateKey: SecKey?, error: Error?) in

            XCTAssertNil(error)
            XCTAssertNotNil(publicKey)
            XCTAssertNotNil(privateKey)

            var unmanagedError: Unmanaged<CFError>?

            if let cfData = SecKeyCopyExternalRepresentation(privateKey!, &unmanagedError) {
                let data: Data = cfData as Data
                let encodedKey = data.base64EncodedString()

                let secKey = KeyGen.getCryptographicKey(fromPrivateKeyString: encodedKey)

                XCTAssertNil(secKey.error)
                XCTAssertNotNil(secKey.secKey)
                unmanagedError?.release()
            } else {
                XCTFail("Error: SecKeyCopyExternalRepresentation")
            }

            unmanagedError?.release()
        }
    }
}
