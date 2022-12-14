## Readme
# Healthpass iOS application

[↳ System Requirements](#system-requirements)

[↳ Notes](#installation)

## System Requirements

+ Mac OS 10.15+
+ Xcode 11.5+
+ Swift 5.0+
+ Git 2.22.0
+ RubyGems 3.0.3
+ iOS 13.0+

## Notes

As an app grows in size build times will also grow in time taken. The swift compiler sometimes gets hung up on complicated method compilation. If you find that this may be the case run the following command from within the root of the project:

    xcodebuild -workspace HealthPass.xcworkspace -scheme HealthPass clean build OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" | grep .[0-9]ms | grep -v ^0.[0-9]ms | sort -nr > culprits.txt

This will produce a text file with a list of method compilation lines to give you an indication of what functions may be the culprits of a slow build. See [http://irace.me/swift-profiling](http://irace.me/swift-profiling) for more information.
