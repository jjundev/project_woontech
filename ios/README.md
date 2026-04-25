# Woontech iOS

This directory contains the SwiftUI onboarding implementation for WF1.

## Open the project

- Open [Woontech.xcodeproj](/Users/hyunjun/Documents/projects/project_woontech/ios/Woontech.xcodeproj)
- Scheme: `Woontech`

## Build from Terminal

```sh
xcodebuild -project ios/Woontech.xcodeproj -scheme Woontech -sdk iphonesimulator build
```

## Test from Terminal

Use an installed simulator destination on your machine, for example:

```sh
xcodebuild -project ios/Woontech.xcodeproj -scheme Woontech -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1' test -only-testing:WoontechTests
xcodebuild -project ios/Woontech.xcodeproj -scheme Woontech -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1' test -only-testing:WoontechUITests
```
