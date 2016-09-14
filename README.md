# OpenSphericalCamera Client in Swift
A Swift OpenSphericalCamera API library with Ricoh Theta S extension

## Requirements

* Swift 2.2+
* Xcode 7.3+
* OpenSphericalCamera API level 2 and/or 1 (RICOH THETA API v2.1 and/or v2.0)

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate OpenSphericalCamera into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
  pod 'OpenSphericalCamera', '~> 2.0.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate OpenSphericalCamera into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "tatsu/OpenSphericalCamera" ~> 2.0.0
```

Run `carthage update` to build the framework and drag the built `OpenSphericalCamera.framework` into your Xcode project.

## Usage

```swift
import OpenSphericalCamera

// Construct OSC generic camera
let osc = OpenSphericalCamera(ipAddress: "192.168.1.1", httpPort: 80)
// Or, Ricoh THETA S camera
let osc = ThetaCamera()

// Set OSC API level 2 (for Ricoh THETA S)
self.osc.startSession { (data, response, error) in
    if let data = data where error == nil {
        if let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary, results = jsonDic["results"] as? NSDictionary, sessionId = results["sessionId"] as? String {
            self.osc.setOptions(sessionId: sessionId, options: ["clientVersion": 2]) { (data, response, error) in
                self.osc.closeSession(sessionId: sessionId)
            }
        } else {
            // Assume clientVersion is equal or later than 2
        }
    }
}

// Take picture
self.osc.takePicture { (data, response, error) in
    if let data = data where error == nil {
        let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
        if let jsonDic = jsonDic, rawState = jsonDic["state"] as? String, state = OSCCommandState(rawValue: rawState) {
            switch state {
            case .InProgress:
                /*
                 * Set execute commands' progressNeeded parameter true explicitly,
                 * except for getLivePreview, if you want this handler to be
                 * called back "inProgress". In any case, they are waiting for
                 * "done" or "error" internally.
                 */
            case .Done:
                if let results = jsonDic["results"] as? NSDictionary, fileUrl = results["fileUrl"] as? String {
                    self.osc.get(fileUrl) { (data, response, error) in
                        dispatch_async(dispatch_get_main_queue()) {
                            self.previewView.image = UIImage(data: data!)
                        }
                    }
                }
            case .Error:
                break // TODO
            }
        }
    }
}
```

## Sample App
* [OpenSphericalCameraSample](https://github.com/tatsu/OpenSphericalCameraSample)

## References
* [Open Spherical Camera API](https://developers.google.com/streetview/open-spherical-camera/)
* [Ricoh THETA API v2.1](https://developers.theta360.com/en/docs/v2.1/api_reference/)

## License

This library is licensed under MIT. Full license text is available in [LICENSE](LICENSE).
