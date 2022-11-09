# healthpass-qrcode-ios-sdk

**QRCodeder** is a simple code reader (initially only QRCode) for iOS in Swift. It is based on the `AVFoundation` framework from Apple.

It provides a default view controller to display the camera view with the scan area overlay and it also provides methods to decode a provided image to string.

It also provides methods to create QR codes image for a provided JSON, string or data.

## Requirements

- iOS 13.0+
- Xcode 11.0+
- Swift 5.0+

## Usage

In iOS13+, you will need first to reasoning about the camera use. For that you'll need to add the **Privacy - Camera Usage Description** *(NSCameraUsageDescription)* field in your Info.plist:

### Installation
