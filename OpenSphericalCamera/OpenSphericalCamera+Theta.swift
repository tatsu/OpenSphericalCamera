//
//  OpenSphericalCamera+Theta.swift
//  ThetaCameraSample
//
//  Created by Tatsuhiko Arai on 5/29/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import Foundation

let JPEG_SOI: [UInt8] = [0xFF, 0xD8]
let JPEG_EOI: [UInt8] = [0xFF, 0xD9]

public extension OpenSphericalCamera {

    public func _finishWlan(sessionId sessionId: String, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil) {
        self.execute("camera._finishWlan", parameters: ["sessionId": sessionId], completionHandler: getWaitDoneHandler(completionHandler))
    }

    public func _startCapture(sessionId sessionId: String, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil) {
        self.execute("camera._startCapture", parameters: ["sessionId": sessionId], completionHandler: getWaitDoneHandler(completionHandler))
    }

    public func _stopCapture(sessionId sessionId: String, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil) {
        self.execute("camera._stopCapture", parameters: ["sessionId": sessionId], completionHandler: getWaitDoneHandler(completionHandler))
    }

    public func _listAll(entryCount entryCount: Int, continuationToken: String? = nil, detail: Bool? = nil, sort: String? = nil, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
        var parameters: [String: AnyObject] = ["entryCount": entryCount]
        if let continuationToken = continuationToken {
            parameters["continuationToken"] = continuationToken
        }
        if let detail = detail {
            parameters["detail"] = detail
        }
        if let sort = sort {
            parameters["sort"] = sort
        }
        self.execute("camera._listAll", parameters: parameters, completionHandler: getWaitDoneHandler(completionHandler))
    }

    public func getImage(fileUri fileUri: String, _type: String, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
        self.execute("camera.getImage", parameters: ["fileUri": fileUri, "_type": _type], completionHandler: completionHandler)
    }

    public func _getVideo(fileUri fileUri: String, _type: String? = "full", completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
        var parameters: [String: AnyObject] = ["fileUri": fileUri]
        if let _type = _type {
            parameters["_type"] = _type
        }
        self.execute("camera._getVideo", parameters: parameters, completionHandler: completionHandler)
    }

    private class GetLivePreviewDelegate: NSObject, NSURLSessionDataDelegate, NSURLSessionTaskDelegate {
        let openSphericalCamera: OpenSphericalCamera
        let completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)
        var dataBuffer = NSMutableData()

        init(openSphericalCamera: OpenSphericalCamera, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
            self.openSphericalCamera = openSphericalCamera
            self.completionHandler = completionHandler
        }

        @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
            dataBuffer.appendData(data)

            repeat {
                var soi: Int?
                var eoi: Int?
                var i = 0

                let bytes = UnsafePointer<UInt8>(dataBuffer.bytes)
                while i < dataBuffer.length - 1 {
                    if JPEG_SOI[0] == bytes[i] && JPEG_SOI[1] == bytes[i + 1] {
                        soi = i
                        i += 1
                        break
                    }
                    i += 1
                }

                while i < dataBuffer.length - 1 {
                    if JPEG_EOI[0] == bytes[i] && JPEG_EOI[1] == bytes[i + 1] {
                        eoi = i
                        // i += 1
                        break
                    }
                    i += 1
                }

                guard let start = soi, end = eoi else {
                    return
                }

                let frameData = dataBuffer.subdataWithRange(NSMakeRange(start, end - start))
                completionHandler(frameData, nil, nil)

                dataBuffer = NSMutableData(data: dataBuffer.subdataWithRange(NSMakeRange(end + 2, dataBuffer.length - (end + 2))))
            } while dataBuffer.length >= 4
        }
        
        @objc func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
            session.invalidateAndCancel()
            self.completionHandler(nil, nil, error)
        }
    }

    public func _getLivePreview(sessionId sessionId: String, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
        self.execute("camera._getLivePreview", parameters: ["sessionId": sessionId], delegate: GetLivePreviewDelegate(openSphericalCamera: self, completionHandler: completionHandler))
    }

    public func _stopSelfTimer(completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil) {
        self.execute("camera._stopSelfTimer", completionHandler: getWaitDoneHandler(completionHandler))
    }
}