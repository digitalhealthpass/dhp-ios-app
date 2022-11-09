//
//  UIViewController+SoundFeedback.swift
//  Verifier
//
//  Created by Gautham Velappan on 3/4/22.
//  (c) Copyright Merative US L.P. and others 2020-2022 
//
//  SPDX-Licence-Identifier: Apache 2.0
//

import AVFoundation
import UIKit

extension UIViewController {
    
    func generateSoundFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        switch type {
        case .success:
            AudioServicesPlaySystemSound(SystemSoundID(1111))

        case .error:
            AudioServicesPlaySystemSound(SystemSoundID(1116))

        case .warning:
            AudioServicesPlaySystemSound(SystemSoundID(1115))

        @unknown default:
            AudioServicesPlaySystemSound(SystemSoundID(1115))
        }
        
        /*
        guard let filePath = Bundle.main.path(forResource: "btn_click_sound", ofType: "mp3") else { return }
        let pianoSound = URL(fileURLWithPath: filePath)
        
        guard let audioPlayer = try? AVAudioPlayer(contentsOf: pianoSound) else { return }
        audioPlayer.play()
         */
    }
    
}
