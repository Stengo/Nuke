// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

import UIKit

public enum ImageTaskState {
    case Suspended, Running, Cancelled, Completed
}

public typealias ImageTaskCompletion = (ImageResponse) -> Void

/** Abstract class
*/
public class ImageTask: Hashable {
    public let request: ImageRequest
    public let identifier: Int
    public internal(set) var state: ImageTaskState = .Suspended
    public internal(set) var response: ImageResponse?
    public lazy var progress = NSProgress(totalUnitCount: -1)
    
    internal init(request: ImageRequest, identifier: Int) {
        self.request = request
        self.identifier = identifier
    }
    
    /** Adds completion block to the task. Completion block is called even if it is added to the alredy completed task.
    
    Completion block to be called on the main thread when task is either completed or cancelled. Completion block is called synchronously when the requested image can be retrieved from the memory cache and the request was made from the main thread.
    */
    public func completion(completion: ImageTaskCompletion) -> Self { return self }
    
    public var hashValue: Int {
        return self.identifier
    }
    
    public func resume() -> Self { return self }

    /** Advices image task to suspend loading. Suspended task might still complete at any time. A download task can continue transferring data at a later time. All other tasks must start over when resumed. For more info on suspending NSURLSessionTask see NSURLSession documentation.
    */
    public func suspend() -> Self { return self }
    public func cancel() -> Self { return self }
}

public func ==(lhs: ImageTask, rhs: ImageTask) -> Bool {
    return lhs === rhs
}
