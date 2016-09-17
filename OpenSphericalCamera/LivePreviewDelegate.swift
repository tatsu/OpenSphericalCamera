//
//  LivePreviewDelegate.swift
//  OpenSphericalCamera
//
//  Created by Tatsuhiko Arai on 9/3/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import Foundation

class LivePreviewDelegate: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {
    let JPEG_SOI: [UInt8] = [0xFF, 0xD8]
    let JPEG_EOI: [UInt8] = [0xFF, 0xD9]

    let completionHandler: ((Data?, URLResponse?, NSError?) -> Void)
    var dataBuffer = NSMutableData()

    init(completionHandler: @escaping ((Data?, URLResponse?, NSError?) -> Void)) {
        self.completionHandler = completionHandler
    }

    @objc func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataBuffer.append(data)

        repeat {
            var soi: Int?
            var eoi: Int?
            var i = 0

            let bytes = dataBuffer.bytes.bindMemory(to: UInt8.self, capacity: dataBuffer.count)
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

            guard let start = soi, let end = eoi else {
                return
            }

            let frameData = dataBuffer.subdata(with: NSMakeRange(start, end - start))
            completionHandler(frameData, nil, nil)

            dataBuffer = NSData(data: dataBuffer.subdata(with: NSMakeRange(end + 2, dataBuffer.length - (end + 2)))) as Data as Data
        } while dataBuffer.length >= 4
    }

    @objc func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        session.invalidateAndCancel()
        self.completionHandler(nil, nil, error as NSError?)
    }
}
