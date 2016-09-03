//
//  LivePreviewDelegate.swift
//  OpenSphericalCamera
//
//  Created by Tatsuhiko Arai on 9/3/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import Foundation

class LivePreviewDelegate: NSObject, NSURLSessionDataDelegate, NSURLSessionTaskDelegate {
    let JPEG_SOI: [UInt8] = [0xFF, 0xD8]
    let JPEG_EOI: [UInt8] = [0xFF, 0xD9]

    let completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)
    var dataBuffer = NSMutableData()

    init(completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
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
