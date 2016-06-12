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
    var osc: ThetaCamera!
    var model: String!
    var sessionId: String!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.osc = ThetaCamera()
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

    func testStartAndStopCaptureAndGetVideo() {
        guard model == "RICOH THETA S" else {
            return
        }

        // setOptions
        let semaphore = dispatch_semaphore_create(0)
        self.osc.setOptions(sessionId: sessionId, options: ["captureMode": "_video"]) { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.setOptions")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            // _startCapture
            self.osc._startCapture(sessionId: self.sessionId) { (data, response, error) in
                XCTAssert(data != nil && data!.length > 0)
                let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                let name = jsonDic!["name"] as? String
                XCTAssert(name != nil && name! == "camera._startCapture")

                let state = jsonDic!["state"] as? String
                XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                sleep(1)

                // _stopCapture
                self.osc._stopCapture(sessionId: self.sessionId) { (data, response, error) in
                    XCTAssert(data != nil && data!.length > 0)
                    let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                    let name = jsonDic!["name"] as? String
                    XCTAssert(name != nil && name! == "camera._stopCapture")

                    let state = jsonDic!["state"] as? String
                    XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                    // state
                    self.osc.state { (data, response, error) in
                        XCTAssert(data != nil && data!.length > 0)
                        let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                        XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                        let state = jsonDic!["state"] as? NSDictionary
                        XCTAssert(state != nil && state!.count > 0)

                        let _latestFileUri = state!["_latestFileUri"] as? String
                        XCTAssert(_latestFileUri != nil && !_latestFileUri!.isEmpty)

                        // _getVideo
                        self.osc._getVideo(fileUri: _latestFileUri!, _type: .Thumb) { (data, response, error) in
                            XCTAssert(data != nil && data!.length > 0)
                            XCTAssertNotNil(UIImage(data: data!))

                            self.osc._getVideo(fileUri: _latestFileUri!, _type: .Full) { (data, response, error) in
                                XCTAssert(data != nil && data!.length > 0)
                                // TODO: Check whether the data is mp4 or not.

                                dispatch_semaphore_signal(semaphore)
                            }
                        }
                    }
                }
            }
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    func testListAll() {
        guard model == "RICOH THETA S" else {
            return
        }

        // _listAll
        let semaphore = dispatch_semaphore_create(0)
        self.osc._listAll(entryCount: 3, detail: false, sort: .Newest) {
            (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera._listAll")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            let results = jsonDic!["results"] as? NSDictionary
            XCTAssert(results != nil && results!.count > 0)

            let entries = results!["entries"] as? [NSDictionary]
            XCTAssert(entries != nil && entries!.count > 0)

            let uri = entries![0]["uri"] as? String
            XCTAssert(uri != nil && !uri!.isEmpty)

            let totalEntries = results!["totalEntries"] as? Int
            XCTAssert(totalEntries != nil)
            
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    func testGetImage() {
        guard model == "RICOH THETA S" else {
            return
        }

        // setOptions
        let semaphore = dispatch_semaphore_create(0)
        self.osc.setOptions(sessionId: sessionId, options: ["captureMode": "image"]) { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.setOptions")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            // takePicture
            self.osc.takePicture(sessionId: self.sessionId) { (data, response, error) in
                XCTAssert(data != nil && data!.length > 0)
                let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                let name = jsonDic!["name"] as? String
                XCTAssert(name != nil && name! == "camera.takePicture")

                let state = jsonDic!["state"] as? String
                XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                let results = jsonDic!["results"] as? NSDictionary
                XCTAssert(results != nil && results!.count > 0)

                let fileUri = results!["fileUri"] as? String
                XCTAssert(fileUri != nil && !fileUri!.isEmpty)

                // getImage for Theta
                self.osc.getImage(fileUri: fileUri!, _type: .Thumb) { (data, response, error) in
                    XCTAssert(data != nil && data!.length > 0)
                    XCTAssertNotNil(UIImage(data: data!))

                    self.osc.getImage(fileUri: fileUri!, _type: .Full) { (data, response, error) in
                        XCTAssert(data != nil && data!.length > 0)
                        XCTAssertNotNil(UIImage(data: data!))

                        dispatch_semaphore_signal(semaphore)
                    }
                }
            }
        }
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

    func testStopSelfTimer() {
        guard model == "RICOH THETA S" else {
            return
        }

        // setOptions
        let semaphore = dispatch_semaphore_create(0)
        self.osc.setOptions(sessionId: sessionId, options: ["captureMode": "image"]) { (data, response, error) in
            XCTAssert(data != nil && data!.length > 0)
            let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            XCTAssert(jsonDic != nil && jsonDic!.count > 0)

            let name = jsonDic!["name"] as? String
            XCTAssert(name != nil && name! == "camera.setOptions")

            let state = jsonDic!["state"] as? String
            XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

            self.osc.setOptions(sessionId: self.sessionId, options: ["exposureDelay": 5]) { (data, response, error) in
                XCTAssert(data != nil && data!.length > 0)
                let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                XCTAssert(jsonDic != nil && jsonDic!.count > 0)

                let name = jsonDic!["name"] as? String
                XCTAssert(name != nil && name! == "camera.setOptions")

                let state = jsonDic!["state"] as? String
                XCTAssert(state != nil && OSCCommandState(rawValue: state!) == .Done)

                // takePicture
                self.osc.takePicture(sessionId: self.sessionId)
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
                    self.osc.setOptions(sessionId: self.sessionId, options: ["exposureDelay": 0]) {
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
            XCTAssert(state != nil && OpenSphericalCamera.State(rawValue: state!) == .Done)

            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    */
}
