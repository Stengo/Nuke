// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import Foundation

// MARK: - ImageDataLoading

/// Data loading completion closure.
public typealias ImageDataLoadingCompletion = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void

/// Data loading progress closure.
public typealias ImageDataLoadingProgress = (_ completed: Int64, _ total: Int64) -> Void

/// Performs loading of image data.
public protocol ImageDataLoading {
    /// Creates task with a given request. Task is resumed by the object calling the method.
    func taskWith(_ request: ImageRequest, progress: ImageDataLoadingProgress, completion: ImageDataLoadingCompletion) -> URLSessionTask

    /// Invalidates the receiver.
    func invalidate()

    /// Clears the receiver's cache storage (in any).
    func removeAllCachedImages()
}


// MARK: - ImageDataLoader

/// Provides basic networking using NSURLSession.
open class ImageDataLoader: NSObject, URLSessionDataDelegate, ImageDataLoading {
    open fileprivate(set) var session: Foundation.URLSession!
    fileprivate var handlers = [URLSessionTask: DataTaskHandler]()
    fileprivate let queue = DispatchQueue(label: "ImageDataLoader.Queue", attributes: [])

    /** Initialzies data loader by creating a session with a given session configuration. Data loader is set as a delegate of the session.
     */
    public init(sessionConfiguration: URLSessionConfiguration) {
        super.init()
        self.session = Foundation.URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }

    /**
     Initializes the receiver with a default NSURLSession configuration.

     The memory capacity of the NSURLCache is set to 0, disk capacity is set to 200 Mb.
     */
    public convenience override init() {
        let conf = URLSessionConfiguration.default
        conf.urlCache = URLCache(memoryCapacity: 0, diskCapacity: (200 * 1024 * 1024), diskPath: "com.github.kean.nuke-cache")
        conf.timeoutIntervalForRequest = 60.0
        conf.timeoutIntervalForResource = 360.0
        self.init(sessionConfiguration: conf)
    }
    
    // MARK: ImageDataLoading

    /// Creates task for the given request.
    open func taskWith(_ request: ImageRequest, progress: @escaping ImageDataLoadingProgress, completion: @escaping ImageDataLoadingCompletion) -> URLSessionTask {
        let task = self.taskWith(request)
        queue.sync {
            self.handlers[task] = DataTaskHandler(progress: progress, completion: completion)
        }
        return task
    }
    
    /// Factory method for creating session tasks for given image requests.
    open func taskWith(_ request: ImageRequest) -> URLSessionTask {
        return session.dataTask(with: request.URLRequest)
    }

    /// Invalidates the instance of NSURLSession class that the receiver was initialized with.
    open func invalidate() {
        session.invalidateAndCancel()
    }

    /// Removes all cached images from the instance of NSURLCache class from the NSURLSession configuration.
    open func removeAllCachedImages() {
        session.configuration.urlCache?.removeAllCachedResponses()
    }
    
    // MARK: NSURLSessionDataDelegate
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        queue.sync {
            if let handler = self.handlers[dataTask] {
                handler.data.append(data)
                handler.progress(dataTask.countOfBytesReceived, dataTask.countOfBytesExpectedToReceive)
            }
        }
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        queue.sync {
            if let handler = self.handlers[task] {
                handler.completion(handler.data as Data, task.response, error)
                self.handlers[task] = nil
            }
        }
    }
}

private class DataTaskHandler {
    let data = NSMutableData()
    let progress: ImageDataLoadingProgress
    let completion: ImageDataLoadingCompletion
    
    init(progress: @escaping ImageDataLoadingProgress, completion: @escaping ImageDataLoadingCompletion) {
        self.progress = progress
        self.completion = completion
    }
}
