# OpenSphericalCamera Client in Swift
A Swift OpenSphericalCamera API library with Ricoh Theta S extension

## Requirements

* Swift 2.2+
* Xcode 7.3+

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
  pod 'OpenSphericalCamera', '~> 0.1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage

```swift
import OpenSphericalCamera

// Construct osc generic camera
let osc = OpenSphericalCamera(ipAddress: "192.168.1.1", httpPort: 80)
// Or, Ricoh THETA S camera
let osc = ThetaCamera()

// camera.startSession
self.osc.startSession { (data, response, error) in
    if let data = data where error == nil {
        let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
        if let jsonDic = jsonDic, results = jsonDic["results"] as? NSDictionary {
            self.sessionId = results["sessionId"] as? String
        }
    }
}

// camera.takePicture
self.osc.takePicture(sessionId: sessionId) { (data, response, error) in
    if let data = data where error == nil {
        let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
        if let jsonDic = jsonDic, rawState = jsonDic["state"] as? String, state = OSCCommandState(rawValue: rawState) {
            switch state {
            case .InProgress:
                // Not reached here since the library is waiting for "done" or "error" internally.
                assertionFailure()
            case .Done:
                if let results = jsonDic["results"] as? NSDictionary, fileUri = results["fileUri"] as? String {
                    self.osc.getImage(fileUri: fileUri, _type: .Thumb) { (data, response, error) in
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

// camera.closeSession
self.osc.closeSession(sessionId: self.sessionId)
```

## Sample App
* [OpenSphericalCameraSample](https://github.com/tatsu/OpenSphericalCameraSample)

## References
* [Open Spherical Camera API](https://developers.google.com/streetview/open-spherical-camera/)
* [Ricoh THETA API v2](https://developers.theta360.com/en/docs/v2/api_reference/)

## License

This library is licensed under MIT. Full license text is available in [LICENSE](LICENSE).
