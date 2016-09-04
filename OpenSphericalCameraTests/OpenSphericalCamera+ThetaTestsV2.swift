//
//  OpenSphericalCamera+ThetaTestsV2.swift
//  OpenSphericalCamera
//
//  Created by Tatsuhiko Arai on 9/4/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import XCTest
@testable import OpenSphericalCamera

class OpenSphericalCamera_ThetaTestsV2: XCTestCase {
    var osc = ThetaCamera()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        let semaphore = dispatch_semaphore_create(0)
        self.osc.startSession { (data, response, error) in
            if let data = data where error == nil {
                if let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary, results = jsonDic["results"] as? NSDictionary, sessionId = results["sessionId"] as? String {
                    self.osc.setOptions(sessionId: sessionId, options: ["clientVersion": 2]) { (data, response, error) in
                        self.osc.closeSession(sessionId: sessionId) { (data, response, error) in
                            dispatch_semaphore_signal(semaphore)
                        }
                    }
                } else {
                    // Assume clientVersion is equal or later than 2
                    dispatch_semaphore_signal(semaphore)
                }
            } else {
                // Error occurred
                dispatch_semaphore_signal(semaphore)
            }
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testListFiles() {
        guard self.osc.info.model == "RICOH THETA S" else {
            return
        }

        // listFiles
        let semaphore = dispatch_semaphore_create(0)
        self.osc.listFiles(fileType: .Image, startPosition: 1, entryCount: 5, maxThumbSize: 640, _detail: false, _sort: .Oldest) { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.listFiles")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            let results = jsonDic!["results"] as? NSDictionary
            XCTAssert(results != nil && results!.count > 0)

            let entries = results!["entries"] as? [NSDictionary]
            XCTAssert(entries != nil && entries!.count > 0)

            let uri = entries![0]["fileUrl"] as? String
            XCTAssert(uri != nil && !uri!.isEmpty)

            let dateTime = entries![0]["dateTime"] as? String // Acquired when "_detail" is false
            XCTAssert(dateTime != nil && !dateTime!.isEmpty)

            let _thumbSize = entries![0]["_thumbSize"] as? Int // Acquired when "maxThumbSize" is set
            XCTAssertNotNil(_thumbSize)

            let totalEntries = results!["totalEntries"] as? Int
            XCTAssert(totalEntries != nil)

            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    func testStopSelfTimer() {
        guard self.osc.info.model == "RICOH THETA S" else {
            return
        }

        // setOptions
        let semaphore = dispatch_semaphore_create(0)
        self.osc.setOptions(options: ["captureMode": "image"]) { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.setOptions")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            self.osc.setOptions(options: ["exposureDelay": 5]) { (data, response, error) in
                XCTAssert(data != nil && data!.length > 0)
                let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                let name = jsonDic!["name"] as? String
                XCTAssert(name != nil && name! == "camera.setOptions")

                let state = jsonDic!["state"] as? String
                XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                // takePicture
                self.osc.takePicture()
                sleep(3)

                // _stopSelfTimer
                self.osc._stopSelfTimer { (data, response, error) in
                    XCTAssert(data != nil && data!.length > 0)
                    let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                    let name = jsonDic!["name"] as? String
                    XCTAssert(name != nil && name! == "camera._stopSelfTimer")

                    let state = jsonDic!["state"] as? String
                    XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                    // setOptions
                    self.osc.setOptions(options: ["exposureDelay": 0]) {
                        (data, response, error) in
                        XCTAssert(data != nil && data!.length > 0)
                        let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                        XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                        let name = jsonDic!["name"] as? String
                        XCTAssert(name != nil && name! == "camera.setOptions")

                        let state = jsonDic!["state"] as? String
                        XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                        dispatch_semaphore_signal(semaphore)
                    }
                }
            }
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    /*
    func testFinishWlan() {
        guard self.osc.info.model == "RICOH THETA S" else {
            return
        }

        // _finishWlan
        let semaphore = dispatch_semaphore_create(0)
        self.osc._finishWlan { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera._finishWlan")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    */
}
