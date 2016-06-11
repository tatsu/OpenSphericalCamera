//
//  OpenSphericalCamera+ThetaTests.swift
//  OpenSphericalCamera
//
//  Created by Tatsuhiko Arai on 6/5/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import XCTest
@testable import OpenSphericalCamera

class OpenSphericalCamera_ThetaTests: XCTestCase {
    var osc: OpenSphericalCamera!
    var model: String!
    var sessionId: String!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.osc = OpenSphericalCamera.sharedCamera(ipAddress: "192.168.1.1", httpPort: 80)
        self.model = osc.info.model

        // startSession
        let semaphore = dispatch_semaphore_create(0)
        self.osc.startSession { (data, response, error) in
            if let data = data where error == nil {
                let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                if let jsonDic = jsonDic, results = jsonDic["results"] as? NSDictionary {
                    self.sessionId = results["sessionId"] as? String
                }
            }
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // closeSession
        let semaphore = dispatch_semaphore_create(0)
        self.osc.closeSession(sessionId: self.sessionId) { (data, response, error) in
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

        super.tearDown()
    }

    func testGetImage() {
        guard model == "RICOH THETA S" else {
            return
        }

        // takePicture (uses Execute and Status commands)
        let semaphore = dispatch_semaphore_create(0)
        var completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)!
        completionHandler = { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.takePicture")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && state! == "done")

            let results = jsonDic!["results"] as? NSDictionary
            XCTAssert(results != nil && results!.count > 0)

            let fileUri = results!["fileUri"] as? String
            XCTAssert(fileUri != nil && !fileUri!.isEmpty)

            // _getImage
            self.osc._getImage(fileUri: fileUri!, _type: "thumb") { (data, response, error) in
                XCTAssert(data != nil && data!.length > 0)
                XCTAssertNotNil(UIImage(data: data!))

                self.osc._getImage(fileUri: fileUri!, _type: "full") { (data, response, error) in
                    XCTAssert(data != nil && data!.length > 0)
                    XCTAssertNotNil(UIImage(data: data!))

                    dispatch_semaphore_signal(semaphore)
                }
            }
        }
        self.osc.takePicture(sessionId: self.sessionId, completionHandler: completionHandler)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    // TODO: _getLivePreview wouldn't respond.
    /*
    func testGetLivePreview() {
        guard model == "RICOH THETA S" else {
            return
        }

        var count = 0

        // _getLivePreview
        let semaphore = dispatch_semaphore_create(0)
        self.osc._getLivePreview(sessionId: sessionId) { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            XCTAssertNotNil(UIImage(data: data!))
            count += 1
            if count >= 10 {
                self.osc.cancel()
                dispatch_semaphore_signal(semaphore)
            }
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    */

    func testFinishWlan() {
        guard model == "RICOH THETA S" else {
            return
        }

        // _finishWlan
        let semaphore = dispatch_semaphore_create(0)
        self.osc._finishWlan(sessionId: self.sessionId) { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera._finishWlan")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && state! == "done")

            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
}
