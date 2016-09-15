//
//  OpenSphericalCameraTestsV2.swift
//  OpenSphericalCamera
//
//  Created by Tatsuhiko Arai on 8/30/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import XCTest
@testable import OpenSphericalCamera

class OpenSphericalCameraTestsV2: XCTestCase {
    var osc = OpenSphericalCamera(ipAddress: "192.168.1.1", httpPort: 80)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        let semaphore = DispatchSemaphore(value: 0)
        self.osc.startSession { (data, response, error) in
            if let data = data , error == nil {
                if let jsonDic = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any], let results = jsonDic["results"] as? [String: Any], let sessionId = results["sessionId"] as? String {
                    self.osc.setOptions(sessionId: sessionId, options: ["clientVersion": 2]) { (data, response, error) in
                        self.osc.closeSession(sessionId: sessionId) { (data, response, error) in
                            semaphore.signal()
                        }
                    }
                } else {
                    // Assume clientVersion is equal or later than 2
                    semaphore.signal()
                }
            } else {
                // Error occurred
                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testStateAndCheckForUpdates() {
        var fingerprint: String?

        // state
        var semaphore = DispatchSemaphore(value: 0)
        self.osc.state { (data, response, error) in
            XCTAssert(data != nil && data!.count > 0)
            let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            fingerprint = jsonDic!["fingerprint"] as? String
            XCTAssert(fingerprint != nil && !fingerprint!.isEmpty)

            let state = jsonDic!["state"] as? [String: Any]
            XCTAssert(state != nil && state!.count > 0)

            // Deprecated in v2
            let sessionId = state!["sessionId"] as? String
            XCTAssertNil(sessionId)

            let batteryLevel = state!["batteryLevel"] as? Double
            XCTAssert(batteryLevel != nil && [0.0, 0.33, 0.67, 1.0].contains(batteryLevel!))

            // Depreceted in v2
            let storageChanged = state!["storageChanged"] as? Bool
            XCTAssertNil(storageChanged)

            // Added in v2
            let storageUri = state!["storageUri"] as? String
            XCTAssert(storageUri != nil && !storageUri!.isEmpty)

            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        // checkForUpdates
        semaphore = DispatchSemaphore(value: 0)
        self.osc.checkForUpdates(stateFingerprint: fingerprint!) { (data, response, error) in
            XCTAssert(data != nil && data!.count > 0)
            let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let fingerprint = jsonDic!["stateFingerprint"] as? String
            XCTAssert(fingerprint != nil && !fingerprint!.isEmpty)

            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    func testTakePictureAndGetImageAndDelete() {

        // setOptions
        let semaphore = DispatchSemaphore(value: 0)
        self.osc.setOptions(options: ["captureMode": "image"]) { (data, response, error) in
            XCTAssert(data != nil && data!.count > 0)
            let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.setOptions")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            // takePicture
            self.osc.takePicture { (data, response, error) in
                XCTAssert(data != nil && data!.count > 0)
                let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
                XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                let name = jsonDic!["name"] as? String
                XCTAssert(name != nil && name! == "camera.takePicture")

                let state = jsonDic!["state"] as? String
                XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                let results = jsonDic!["results"] as? [String: Any]
                XCTAssert(results != nil && results!.count > 0)

                let fileUrl = results!["fileUrl"] as? String
                XCTAssert(fileUrl != nil && !fileUrl!.isEmpty)

                // get
                self.osc.get(fileUrl!) { (data, response, error) in
                    XCTAssert(data != nil && data!.count > 0)
                    XCTAssertNotNil(UIImage(data: data!))

                    // delete
                    self.osc.delete(fileUrls: [fileUrl!]) { (data, response, error) in
                        XCTAssert(data != nil && data!.count > 0)
                        let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
                        XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                        let name = jsonDic!["name"] as? String
                        XCTAssert(name != nil && name! == "camera.delete")

                        let state = jsonDic!["state"] as? String
                        XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)
                        
                        semaphore.signal()
                    }
                }
            }
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    func testListFiles() {

        // listFiles
        let semaphore = DispatchSemaphore(value: 0)
        self.osc.listFiles(fileType: .Image, startPosition: 1, entryCount: 5, maxThumbSize: 0) { (data, response, error) in
            XCTAssert(data != nil && data!.count > 0)
            let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.listFiles")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            let results = jsonDic!["results"] as? [String: Any]
            XCTAssert(results != nil && results!.count > 0)

            let entries = results!["entries"] as? [[String: Any]]
            XCTAssert(entries != nil && entries!.count > 0)

            let uri = entries![0]["fileUrl"] as? String
            XCTAssert(uri != nil && !uri!.isEmpty)

            let totalEntries = results!["totalEntries"] as? Int
            XCTAssert(totalEntries != nil)

            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    func testStartAndStopCaptureAndGetVideo() {

        // setOptions
        let semaphore = DispatchSemaphore(value: 0)
        self.osc.setOptions(options: ["captureMode": "video"]) { (data, response, error) in
            XCTAssert(data != nil && data!.count > 0)
            let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.setOptions")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            // startCapture
            self.osc.startCapture { (data, response, error) in
                XCTAssert(data != nil && data!.count > 0)
                let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
                XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                let name = jsonDic!["name"] as? String
                XCTAssert(name != nil && name! == "camera.startCapture")

                let state = jsonDic!["state"] as? String
                XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                sleep(1)

                // stopCapture
                self.osc.stopCapture { (data, response, error) in
                    XCTAssert(data != nil && data!.count > 0)
                    let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
                    XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                    let name = jsonDic!["name"] as? String
                    XCTAssert(name != nil && name! == "camera.stopCapture")

                    let state = jsonDic!["state"] as? String
                    XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                    let results = jsonDic!["results"] as? [String: Any]
                    XCTAssert(results != nil && results!.count > 0)

                    let fileUrls = results!["fileUrls"] as? [String]
                    XCTAssertNotNil(fileUrls)

                    // GET file
                    self.osc.get(fileUrls![0]){ (data, response, error) in
                        XCTAssert(data != nil && data!.count > 0)

                        semaphore.signal()
                    }
                }
            }
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    func testGetAndSetOptions() {

        // getOptions
        let semaphore = DispatchSemaphore(value: 0)
        self.osc.getOptions(optionNames: ["exposureProgram", "exposureProgramSupport"]) {
            (data, response, error) in
            XCTAssert(data != nil && data!.count > 0)
            let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.getOptions")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            let results = jsonDic!["results"] as? [String: Any]
            XCTAssert(results != nil && results!.count > 0)

            let options = results!["options"] as? [String: Any]
            XCTAssert(options != nil && options!.count == 2)

            let exposureProgram = options!["exposureProgram"] as? Int
            XCTAssert(exposureProgram != nil)

            let exposureProgramSupport = options!["exposureProgramSupport"] as? [Int]
            XCTAssert(exposureProgramSupport != nil && exposureProgramSupport!.contains(exposureProgram!))

            // setOptions
            self.osc.setOptions(options: ["exposureProgram": exposureProgram!]) { (data, response, error) in
                XCTAssert(data != nil && data!.count > 0)
                let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
                XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                let name = jsonDic!["name"] as? String
                XCTAssert(name != nil && name! == "camera.setOptions")

                let state = jsonDic!["state"] as? String
                XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    // TODO: getLivePreview wouldn't respond.
    /*
    func testGetLivePreview() {
        var count = 0

        // getLivePreview
        let semaphore = DispatchSemaphore(value: 0)
        self.osc.getLivePreview { (data, response, error) in
            XCTAssert(data != nil && data!.count > 0)
            XCTAssertNotNil(UIImage(data: data!))
            count += 1
            if count >= 10 {
                self.osc.cancel()
                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    */

    /*
    func testReset() {

        // reset
        let semaphore = DispatchSemaphore(value: 0)
        self.osc.reset { (data, response, error) in
            XCTAssert(data != nil && data!.count > 0)
            let jsonDic = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.reset")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    */
}
