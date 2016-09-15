//
//  OpenSphericalCamera+Theta.swift
//  ThetaCameraSample
//
//  Created by Tatsuhiko Arai on 5/29/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import Foundation

public protocol Theta {

}

open class ThetaCamera: OpenSphericalCamera, Theta {

    convenience public init() {
        self.init(ipAddress: "192.168.1.1", httpPort: 80)
    }

}

public enum ThetaListSort: String {
    case Newest = "newest"
    case Oldest = "oldest"
}

public enum ThetaFileType: String {
    case Full = "full"
    case Thumb = "thumb"
}

public extension OSCCameraCommand where Self: Theta {

    public func _finishWlan(sessionId: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera._finishWlan", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _finishWlan(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera._finishWlan", completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _startCapture(sessionId: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera._startCapture", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _stopCapture(sessionId: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera._stopCapture", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _listAll(entryCount: Int, continuationToken: String? = nil, detail: Bool? = nil, sort: ThetaListSort? = nil, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        var parameters: [String: Any] = ["entryCount": entryCount]
        if let continuationToken = continuationToken {
            parameters["continuationToken"] = continuationToken
        }
        if let detail = detail {
            parameters["detail"] = detail
        }
        if let sort = sort {
            parameters["sort"] = sort.rawValue
        }
        self.execute("camera._listAll", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func listFiles(fileType: FileType, startPosition: Int? = nil, entryCount: Int, maxThumbSize: Int? = nil, _detail: Bool? = nil, _sort: ThetaListSort? = nil, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Added in v2
        var parameters: [String: Any] = ["fileType": fileType.rawValue, "entryCount": entryCount]
        if let startPosition = startPosition {
            parameters["startPosition"] = startPosition
        }
        if let maxThumbSize = maxThumbSize {
            parameters["maxThumbSize"] = maxThumbSize
        }
        if let _detail = _detail {
            parameters["_detail"] = _detail
        }
        if let _sort = _sort {
            parameters["_sort"] = _sort.rawValue
        }
        self.execute("camera.listFiles", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func getImage(fileUri: String, _type: ThetaFileType, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        self.execute("camera.getImage", parameters: ["fileUri": fileUri, "_type": _type.rawValue], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _getVideo(fileUri: String, _type: ThetaFileType? = nil, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        var parameters: [String: Any] = ["fileUri": fileUri]
        if let _type = _type {
            parameters["_type"] = _type.rawValue
        }
        self.execute("camera._getVideo", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _getLivePreview(sessionId: String, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        self.execute("camera._getLivePreview", parameters: ["sessionId": sessionId], delegate: LivePreviewDelegate(completionHandler: completionHandler))
    }

    public func _stopSelfTimer(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) {
        self.execute("camera._stopSelfTimer", completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }
}
