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

    public func _finishWlan(sessionId: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera._finishWlan", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _finishWlan(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera._finishWlan", parameters: nil, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _startCapture(sessionId: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera._startCapture", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _stopCapture(sessionId: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera._stopCapture", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _listAll(entryCount: Int, continuationToken: String? = nil, detail: Bool? = nil, sort: ThetaListSort? = nil, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)) { // Deprecated in v2
        var parameters: [String: AnyObject] = ["entryCount": entryCount as AnyObject]
        if let continuationToken = continuationToken {
            parameters["continuationToken"] = continuationToken as AnyObject?
        }
        if let detail = detail {
            parameters["detail"] = detail as AnyObject?
        }
        if let sort = sort {
            parameters["sort"] = sort.rawValue as AnyObject?
        }
        self.execute("camera._listAll", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    func listFiles(fileType: FileType, startPosition: Int? = nil, entryCount: Int, maxThumbSize: Int? = nil, _detail: Bool? = nil, _sort: ThetaListSort? = nil, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)) { // Added in v2
        var parameters: [String: AnyObject] = ["fileType": fileType.rawValue as AnyObject, "entryCount": entryCount as AnyObject]
        if let startPosition = startPosition {
            parameters["startPosition"] = startPosition as AnyObject?
        }
        if let maxThumbSize = maxThumbSize {
            parameters["maxThumbSize"] = maxThumbSize as AnyObject?
        }
        if let _detail = _detail {
            parameters["_detail"] = _detail as AnyObject?
        }
        if let _sort = _sort {
            parameters["_sort"] = _sort.rawValue as AnyObject?
        }
        self.execute("camera.listFiles", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func getImage(fileUri: String, _type: ThetaFileType, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)) { // Deprecated in v2
        self.execute("camera.getImage", parameters: ["fileUri": fileUri, "_type": _type.rawValue], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _getVideo(fileUri: String, _type: ThetaFileType? = nil, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)) { // Deprecated in v2
        var parameters: [String: AnyObject] = ["fileUri": fileUri as AnyObject]
        if let _type = _type {
            parameters["_type"] = _type.rawValue as AnyObject?
        }
        self.execute("camera._getVideo", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func _getLivePreview(sessionId: String, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)) { // Deprecated in v2
        self.execute("camera._getLivePreview", parameters: ["sessionId": sessionId], delegate: LivePreviewDelegate(completionHandler: completionHandler))
    }

    public func _stopSelfTimer(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)? = nil) {
        self.execute("camera._stopSelfTimer", parameters: nil, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }
}
