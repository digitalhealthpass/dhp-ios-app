//
//  EmulatorChecker.swift
//  IOSSecuritySuite
//
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import Foundation

internal class EmulatorChecker {

    static func amIRunInEmulator() -> Bool {

        return checkCompile() || checkRuntime()
    }

    private static func checkRuntime() -> Bool {

        return ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] != nil
    }

    private static func checkCompile() -> Bool {

        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

}
