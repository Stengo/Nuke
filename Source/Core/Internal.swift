// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

#if os(OSX)
    import Cocoa
    /// Alias for NSImage
    public typealias Image = NSImage
#else
    import UIKit
    /// Alias for UIImage
    public typealias Image = UIImage
#endif


// MARK: Error Handling

func errorWithCode(_ code: ImageManagerErrorCode) -> NSError {
    func reason() -> String {
        switch code {
        case .unknown: return "The image manager encountered an error that it cannot interpret."
        case .cancelled: return "The image task was cancelled."
        case .decodingFailed: return "The image manager failed to decode image data."
        case .processingFailed: return "The image manager failed to process image data."
        }
    }
    return NSError(domain: ImageManagerErrorDomain, code: code.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: reason()])
}


// MARK: GCD

func dispathOnMainThread(_ closure: @escaping (Void) -> Void) {
    Thread.isMainThread ? closure() : DispatchQueue.main.async(execute: closure)
}

extension DispatchQueue {
    func async(_ block: @escaping ((Void) -> Void)) {
        self.async(execute: block)
    }
}


// MARK: NSOperationQueue Extensions

extension OperationQueue {
    convenience init(maxConcurrentOperationCount: Int) {
        self.init()
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
    
    func addBlock(_ block: @escaping ((Void) -> Void)) -> Operation {
        let operation = BlockOperation(block: block)
        self.addOperation(operation)
        return operation
    }
}


// MARK: TaskQueue

/// Limits number of concurrent tasks, prevents trashing of NSURLSession
final class TaskQueue {
    var maxExecutingTaskCount = 8
    var congestionControlEnabled = true
    
    fileprivate let queue: DispatchQueue
    fileprivate var pendingTasks = NSMutableOrderedSet()
    fileprivate var executingTasks = Set<URLSessionTask>()
    fileprivate var executing = false
    
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    func resume(_ task: URLSessionTask) {
        if !pendingTasks.contains(task) && !executingTasks.contains(task) {
            pendingTasks.add(task)
            setNeedsExecute()
        }
    }
    
    func cancel(_ task: URLSessionTask) {
        if pendingTasks.contains(task) {
            pendingTasks.remove(task)
        } else if executingTasks.contains(task) {
            executingTasks.remove(task)
            task.cancel()
            setNeedsExecute()
        }
    }
    
    func finish(_ task: URLSessionTask) {
        if pendingTasks.contains(task) {
            pendingTasks.remove(task)
        } else if executingTasks.contains(task) {
            executingTasks.remove(task)
            setNeedsExecute()
        }
    }
    
    func setNeedsExecute() {
        if !executing {
            executing = true
            if congestionControlEnabled {
                // Executing tasks too frequently might trash NSURLSession to the point it would crash or stop executing tasks
                let delay = min(30.0, 8.0 + Double(executingTasks.count))
                queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)) {
                    self.execute()
                }
            } else {
                execute()
            }
        }
    }
    
    func execute() {
        executing = false
        if let task = pendingTasks.firstObject as? URLSessionTask, executingTasks.count < maxExecutingTaskCount {
            pendingTasks.removeObject(at: 0)
            executingTasks.insert(task)
            task.resume()
            setNeedsExecute()
        }
    }
}
