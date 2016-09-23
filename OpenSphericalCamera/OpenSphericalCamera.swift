//
//  OpenSphericalCamera.swift
//  ThetaCameraSample
//
//  Created by Tatsuhiko Arai on 5/29/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import Foundation

public protocol OSCBase: class {
    var task: URLSessionDataTask? { get set }
    var taskState: URLSessionTask.State? { get }
    var urlSession: URLSession? { get set }
    var ipAddress: String { get set }
    var httpPort: Int { get set }
    var httpUpdatesPort: Int! { get }
    var info: OSCInfo! { get }

    func cancel()
}

public protocol OSCProtocol: class, OSCBase {
    func info(completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void))
    func state(completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void))
    func checkForUpdates(stateFingerprint: String, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void))
    func execute(_ name: String, parameters: [String: Any]?, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?)
    func execute(_ name: String, parameters: [String: Any]?, delegate: URLSessionDelegate)
    func getWaitDoneHandler(progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) -> (Data?, URLResponse?, Error?) -> Void
    func status(id: String, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void))
}

public protocol OSCCameraCommand: class, OSCProtocol {
    func startSession(progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Deprecated in v2
    func updateSession(sessionId: String, progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Deprecated in v2
    func closeSession(sessionId: String, progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) // Deprecated in v2
    func takePicture(sessionId: String, progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) // Deprecated in v2
    func takePicture(progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?)
    func startCapture(progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) // Added in v2
    func stopCapture(progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) // Added in v2
    func listImages(entryCount: Int, maxSize: Int?, continuationToken: String?, includeThumb: Bool?, progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Deprecated in v2
    func listFiles(fileType: FileType, startPosition: Int?, entryCount: Int, maxThumbSize: Int?, progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Added in v2
    func delete(fileUri: String, progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) // Modified in v2
    func delete(fileUrls: [String], progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?)
    func getImage(fileUri: String, maxSize: Int?, progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Deprecated in v2
    func getMetadata(fileUri: String, progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Deprecated in v2
    func getLivePreview(_ completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Added in v2
    func getOptions(sessionId: String, optionNames: [String], progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Deprecated in v2
    func getOptions(optionNames: [String], progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void))
    func reset(progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) // Added in v2
    func setOptions(sessionId: String, options: [String: Any], progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) // Deprecated in v2
    func setOptions(options: [String: Any], progressNeeded: Bool, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void))
    func processPicture(previewFileUrls: [String], progressNeeded: Bool, completionHandler: ((Data?, URLResponse?, Error?) -> Void)?) // Added in v2
}

public struct OSCEndpoints {
    var httpPort: Int = 0
    var httpUpdatesPort: Int = 0
}

public struct OSCInfo {
    var manufacturer: String = ""
    var model: String = ""
    var serialNumber: String = ""
    var firmwareVersion: String = ""
    var supportUrl: String = ""
    var endpoints: OSCEndpoints = OSCEndpoints()
    var gps: Bool = false
    var gyro: Bool = false
    var uptime: Int = 0
    var api: [String] = []
    var apiLevel: [Int] = [] // v2
}

public enum OSCCommandState: String {
    case inProgress
    case done
    case error
}

public enum OSCErrorCode: String {
    case unknownCommand // 400 Invalid command is issued
    case disabledCommand // 403 Command cannot be executed due to the camera status
    case missingParameter // 400 Insufficient required parameters to issue the command
    case invalidParameterName // 400 Parameter name or option name is invalid
    case invalidParameterValue // 400 Parameter value when command was issued is invalid
    case invalidSessionId // 403 sessionID when command was issued is invalid (Deprecated in v2)
    case tooManyParameters // 403 Number of parameters exceeds limit (Added in v2)
    case corruptedFile // 403 Process request for corrupted file
    case cameraInExclusiveUse // 400 Session start not possible when camera is in exclusive use (Deprecated in v2)
    case powerOffSequenceRunning // 403 Process request when power supply is off
    case invalidFileFormat // 403 Invalid file format specified
    case serviceUnavailable // 503 Processing requests cannot be received temporarily
    case canceledShooting // 403 Shooting request cancellation of the self-timer. Returned in Commands/Status of camera.takePicture (Firmware version 01.42 or above)
    case unexpected // 503 Other errors
}

public enum FileType: String {
    case all
    case image
    case video
}

open class OpenSphericalCamera: OSCCameraCommand {
    open var task: URLSessionDataTask?
    open var taskState: URLSessionTask.State? {
        if let task = self.task {
            return task.state
        }
        return nil
    }
    open var urlSession: URLSession? = URLSession(configuration: URLSessionConfiguration.default)

    open var ipAddress: String
    open var httpPort: Int
    open lazy var httpUpdatesPort: Int! = {
        return self.info.endpoints.httpUpdatesPort
    }()

    open lazy var info: OSCInfo! = {
        var info = OSCInfo()

        let semaphore = DispatchSemaphore(value: 0)

        self.info { (data, response, error) in
            if let data = data , error == nil {
                if let jsonDic = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any] {
                    info.manufacturer = (jsonDic["manufacturer"] as? String) ?? ""
                    info.model = (jsonDic["model"] as? String) ?? ""
                    info.serialNumber = (jsonDic["serialNumber"] as? String) ?? ""
                    info.firmwareVersion = (jsonDic["firmwareVersion"] as? String) ?? ""
                    info.supportUrl = (jsonDic["supportUrl"] as? String) ?? ""
                    if let endpoints = jsonDic["endpoints"] as? [String: Any] {
                        info.endpoints.httpPort = (endpoints["httpPort"] as? Int) ?? 0
                        info.endpoints.httpUpdatesPort = (endpoints["httpUpdatesPort"] as? Int) ?? 0
                    }
                    info.gps = (jsonDic["gps"] as? Bool) ?? false
                    info.gyro = (jsonDic["gyro"] as? Bool) ?? false
                    info.uptime = (jsonDic["uptime"] as? Int) ?? 0
                    info.api = (jsonDic["api"] as? [String]) ?? []
                    info.apiLevel = (jsonDic["apiLevel"] as? [Int]) ?? [1] // v2
                }
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)

        return info
    }()

    public init(ipAddress: String, httpPort: Int) {
        self.ipAddress = ipAddress
        self.httpPort  = httpPort
    }

    deinit {
        self.cancel()
    }

}

public extension OSCCameraCommand {

    // MARK: OSCBase Methods

    public func cancel() {
        if let task = self.task {
            switch task.state {
            case .running:
                fallthrough
            case .suspended:
                task.cancel()
            // case .Canceling:
            // case .Completed:
            default:
                break
            }
        }
    }

    // MARK: - GET Method (Added in v2)

    public func get(_ urlString: String, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        self.cancel()

        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        self.task = self.urlSession!.dataTask(with: request, completionHandler: { (data, response, error) in
            completionHandler(data, response, error)
        }) 
        self.task!.resume()
    }

    // MARK: - OSCProtocol Methods

    public func info(completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        self.cancel()

        let url = URL(string: "http://\(ipAddress):\(httpPort)/osc/info")!
        let request = URLRequest(url: url)
        self.task = self.urlSession!.dataTask(with: request, completionHandler: { (data, response, error) in
            completionHandler(data, response, error)
        }) 
        self.task!.resume()
    }

    public func state(completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        self.cancel()

        let url = URL(string: "http://\(ipAddress):\(httpPort)/osc/state")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        self.task = self.urlSession!.dataTask(with: request, completionHandler: { (data, response, error) in
            completionHandler(data, response, error)
        }) 
        self.task!.resume()
    }

    public func checkForUpdates(stateFingerprint: String, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        self.cancel()

        let url = URL(string: "http://\(ipAddress):\(httpUpdatesPort)/osc/checkForUpdates")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charaset=utf-8", forHTTPHeaderField: "Content-Type")
        let object: [String: Any] = ["stateFingerprint": stateFingerprint]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        } catch {
            assertionFailure(error.localizedDescription)
        }

        self.task = self.urlSession!.dataTask(with: request, completionHandler: { (data, response, error) in
            completionHandler(data, response, error)
        }) 
        self.task!.resume()
    }

    public func getRequestForExecute(_ name: String, parameters: [String: Any]? = nil) -> URLRequest {
        let url = URL(string: "http://\(ipAddress):\(httpPort)/osc/commands/execute")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charaset=utf-8", forHTTPHeaderField: "Content-Type")
        var object: [String: Any] = ["name": name]
        if let parameters = parameters {
            object["parameters"] = parameters
        }
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        } catch {
            assertionFailure(error.localizedDescription)
        }

        return request
    }

    public func execute(_ name: String, parameters: [String: Any]? = nil, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) {
        self.cancel()

        let request = getRequestForExecute(name, parameters: parameters)
        self.task = completionHandler == nil ?
            self.urlSession!.dataTask(with: request) :
            self.urlSession!.dataTask(with: request, completionHandler: { (data, response, error) in
                completionHandler!(data, response, error)
            }) 
        self.task!.resume()
    }

    public func execute(_ name: String, parameters: [String: Any]? = nil, delegate: URLSessionDelegate) {
        self.cancel()

        let urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                      delegate: delegate, delegateQueue: OperationQueue.main)
        let request = getRequestForExecute(name, parameters: parameters)
        self.task = urlSession.dataTask(with: request)
        self.task!.resume()
    }

    public func status(id: String, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        self.cancel()

        let url = URL(string: "http://\(ipAddress):\(httpPort)/osc/commands/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charaset=utf-8", forHTTPHeaderField: "Content-Type")
        let object: [String: Any] = ["id": id]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        } catch {
            assertionFailure(error.localizedDescription)
        }
        self.task = self.urlSession!.dataTask(with: request, completionHandler: { (data, response, error) in
            completionHandler(data, response, error)
        }) 
        self.task!.resume()
    }

    public func getWaitDoneHandler(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) -> (Data?, URLResponse?, Error?) -> Void {
        var waitDoneHandler: ((Data?, URLResponse?, Error?) -> Void)!
        waitDoneHandler = { (data, response, error) in
            guard let d = data , error == nil else {
                completionHandler?(data, response, error)
                return
            }

            let jsonDic = try? JSONSerialization.jsonObject(with: d, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            guard let dic = jsonDic, let rawState = dic["state"] as? String, let state = OSCCommandState(rawValue: rawState) else {
                completionHandler?(data, response, error)
                return
            }

            switch state {
            case .inProgress:
                if progressNeeded {
                    completionHandler?(data, response, error)
                }
                if let id = dic["id"] as? String {
                    sleep(1)
                    self.status(id: id, completionHandler: waitDoneHandler)
                }
            case .done:
                fallthrough
            case .error:
                fallthrough
            default:
                completionHandler?(data, response, error)
            }
        }

        return waitDoneHandler
    }

    // MARK: - OSCCameraCommand Methods

    public func startSession(progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        self.execute("camera.startSession", completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func updateSession(sessionId: String, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        self.execute("camera.updateSession", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func closeSession(sessionId: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera.closeSession", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func takePicture(sessionId: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Deprecated in v2
        self.execute("camera.takePicture", parameters: ["sessionId": sessionId], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func takePicture(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) {
        self.execute("camera.takePicture", completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func startCapture(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Added in v2
        self.execute("camera.startCapture", completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func stopCapture(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Added in v2
        self.execute("camera.stopCapture", completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func listImages(entryCount: Int, maxSize: Int? = nil, continuationToken: String? = nil, includeThumb: Bool? = nil, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        var parameters: [String: Any] = ["entryCount": entryCount]
        if let maxSize = maxSize {
            parameters["maxSize"] = maxSize
        }
        if let continuationToken = continuationToken {
            parameters["continuationToken"] = continuationToken
        }
        if let includeThumb = includeThumb {
            parameters["includeThumb"] = includeThumb
        }
        self.execute("camera.listImages", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func listFiles(fileType: FileType, startPosition: Int? = nil, entryCount: Int, maxThumbSize: Int? = nil, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Added in v2
        var parameters: [String: Any] = ["fileType": fileType.rawValue, "entryCount": entryCount]
        if let startPosition = startPosition {
            parameters["startPosition"] = startPosition
        }
        if let maxThumbSize = maxThumbSize {
            parameters["maxThumbSize"] = maxThumbSize
        }
        self.execute("camera.listFiles", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func delete(fileUri: String, progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Modified in v2
        let parameters: [String: Any] = ["fileUri": fileUri]
        self.execute("camera.delete", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func delete(fileUrls: [String], progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) {
        let parameters: [String: Any] = ["fileUrls": fileUrls]
        self.execute("camera.delete", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func getImage(fileUri: String, maxSize: Int? = nil, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        var parameters: [String: Any] = ["fileUri": fileUri]
        if let maxSize = maxSize {
            parameters["maxSize"] = maxSize
        }
        self.execute("camera.getImage", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func getMetadata(fileUri: String, progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        let parameters: [String: Any] = ["fileUri": fileUri]
        self.execute("camera.getMetadata", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func getLivePreview(_ completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Added in v2
        self.execute("camera.getLivePreview", delegate: LivePreviewDelegate(completionHandler: completionHandler))
    }

    public func getOptions(sessionId: String, optionNames: [String], progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        self.execute("camera.getOptions", parameters: ["sessionId": sessionId, "optionNames": optionNames], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func getOptions(optionNames: [String], progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        self.execute("camera.getOptions", parameters: ["optionNames": optionNames], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func reset(progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Added in v2
        self.execute("camera.reset", completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func setOptions(sessionId: String, options: [String: Any], progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) { // Deprecated in v2
        self.execute("camera.setOptions", parameters: ["sessionId": sessionId, "options": options], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func setOptions(options: [String: Any], progressNeeded: Bool = false, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        self.execute("camera.setOptions", parameters: ["options": options], completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

    public func processPicture(previewFileUrls: [String], progressNeeded: Bool = false, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) { // Added in v2
        let parameters: [String: Any] = ["previewFileUrls": previewFileUrls]
        self.execute("camera.processPicture", parameters: parameters, completionHandler: self.getWaitDoneHandler(progressNeeded: progressNeeded, completionHandler: completionHandler))
    }

}
