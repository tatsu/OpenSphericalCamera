//
//  OpenSphericalCameraTests.swift
//  OpenSphericalCameraTests
//
//  Created by Tatsuhiko Arai on 6/3/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import XCTest
@testable import OpenSphericalCamera

class OpenSphericalCameraTests: XCTestCase {
    var osc: OpenSphericalCamera!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.osc = OpenSphericalCamera.sharedCamera(ipAddress: "192.168.1.1", httpPort: 80)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInfo() {
        XCTAssert(osc.httpUpdatesPort != 0)

        XCTAssertFalse(osc.info.manufacturer.isEmpty)
        XCTAssertFalse(osc.info.model.isEmpty)
        XCTAssertFalse(osc.info.serialNumber.isEmpty)
        XCTAssertFalse(osc.info.firmwareVersion.isEmpty)
        XCTAssertFalse(osc.info.supportUrl.isEmpty)
        XCTAssert(osc.info.endpoints.httpPort != 0)
        XCTAssert(osc.info.endpoints.httpUpdatesPort != 0)
        XCTAssert(osc.info.uptime != 0)
        XCTAssertFalse(osc.info.api.isEmpty)
    }

    func testStateAndCheckForUpdates() {
        var fingerprint: String?

        // state
        var semaphore = dispatch_semaphore_create(0)
        self.osc.state { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            fingerprint = jsonDic!["fingerprint"] as? String
            XCTAssert(fingerprint != nil && !fingerprint!.isEmpty)

            let state = jsonDic!["state"] as? NSDictionary
            XCTAssert(state != nil && state!.count > 0)

            let sessionId = state!["sessionId"] as? String
            XCTAssert(sessionId != nil && !sessionId!.isEmpty)

            let batteryLevel = state!["batteryLevel"] as? Double
            XCTAssert(batteryLevel != nil && [0.0, 0.33, 0.67, 1.0].contains(batteryLevel!))

            let storageChanged = state!["storageChanged"] as? Bool
            XCTAssertNotNil(storageChanged)

            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

        // checkForUpdates
        semaphore = dispatch_semaphore_create(0)
        self.osc.checkForUpdates(stateFingerprint: fingerprint!) { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let fingerprint = jsonDic!["stateFingerprint"] as? String
            XCTAssert(fingerprint != nil && !fingerprint!.isEmpty)

            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    func testTakePictureAndGetImage() {
        var sessionId: String?

        // startSession
        var semaphore = dispatch_semaphore_create(0)
        self.osc.startSession { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let results = jsonDic!["results"] as? NSDictionary
            XCTAssert(results != nil && results!.count > 0)

            sessionId = results!["sessionId"] as? String
            XCTAssert(sessionId != nil && !sessionId!.isEmpty)

            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

        // takePicture (uses Execute and Status commands)
        semaphore = dispatch_semaphore_create(0)
        var completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)!
        completionHandler = { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && state! == "done")

            let results = jsonDic!["results"] as? NSDictionary
            XCTAssert(results != nil && results!.count > 0)

            let fileUri = results!["fileUri"] as? String
            XCTAssert(fileUri != nil && !fileUri!.isEmpty)

            // getImage
            self.osc.getImage(fileUri: fileUri!) { (data, response, error) in
                XCTAssert(data != nil && data!.length > 0)
                XCTAssertNotNil(UIImage(data: data!))

                dispatch_semaphore_signal(semaphore)
            }
        }
        self.osc.takePicture(sessionId: sessionId!, completionHandler: completionHandler)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

        // closeSession
        self.osc.closeSession(sessionId: sessionId!)
    }
}
