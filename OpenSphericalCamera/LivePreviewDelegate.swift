//
//  LivePreviewDelegate.swift
//  OpenSphericalCamera
//
//  Created by Tatsuhiko Arai on 9/3/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import Foundation

class LivePreviewDelegate: NSObject, URLSessionDataDelegate {
    let JPEG_SOI: [UInt8] = [0xFF, 0xD8]
    let JPEG_EOI: [UInt8] = [0xFF, 0xD9]

    let completionHandler: ((Data?, URLResponse?, Error?) -> Void)
    var dataBuffer = Data()

    init(completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        self.completionHandler = completionHandler
    }

    @objc func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataBuffer.append(data)

        repeat {
            var soi: Int?
            var eoi: Int?
            var i = 0

            dataBuffer.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                while i < dataBuffer.count - 1 {
                    if JPEG_SOI[0] == bytes[i] && JPEG_SOI[1] == bytes[i + 1] {
                        soi = i
                        i += 1
                        break
                    }
                    i += 1
                }

                while i < dataBuffer.count - 1 {
                    if JPEG_EOI[0] == bytes[i] && JPEG_EOI[1] == bytes[i + 1] {
                        i += 1
                        eoi = i
                        break
                    }
                    i += 1
                }

            }

            guard let start = soi, let end = eoi else {
                return
            }

            let frameData = dataBuffer.subdata(in: start..<(end + 1))
            self.completionHandler(frameData, nil, nil)
            dataBuffer = dataBuffer.subdata(in: (end + 1)..<dataBuffer.count)
        } while dataBuffer.count >= 4
    }

    @objc func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        session.invalidateAndCancel()
        self.completionHandler(nil, nil, error)
    }
}
