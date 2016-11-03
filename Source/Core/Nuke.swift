// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import Foundation

// MARK: - Convenience

/// Creates a task with a given URL. After you create a task, you start it by calling its resume method.
public func taskWith(_ URL: Foundation.URL, completion: ImageTaskCompletion? = nil) -> ImageTask {
    return ImageManager.shared.taskWith(URL, completion: completion)
}

/// Creates a task with a given request. After you create a task, you start it by calling its resume method.
public func taskWith(_ request: ImageRequest, completion: ImageTaskCompletion? = nil) -> ImageTask {
    return ImageManager.shared.taskWith(request, completion: completion)
}

/**
 Prepares images for the given requests for later use.

 When you call this method, ImageManager starts to load and cache images for the given requests. ImageManager caches images with the exact target size, content mode, and filters. At any time afterward, you can create tasks with equivalent requests.
 */
public func startPreheatingImages(_ requests: [ImageRequest]) {
    ImageManager.shared.startPreheatingImages(requests)
}

/// Stop preheating for the given requests. The request parameters should match the parameters used in startPreheatingImages method.
public func stopPreheatingImages(_ requests: [ImageRequest]) {
    ImageManager.shared.stopPreheatingImages(requests)
}

/// Stops all preheating tasks.
public func stopPreheatingImages() {
    ImageManager.shared.stopPreheatingImages()
}


// MARK: - ImageManager (Convenience)

/// Convenience methods for ImageManager.
public extension ImageManager {
    /// Creates a task with a given request. For more info see `taskWith(_)` methpd.
    func taskWith(_ URL: Foundation.URL, completion: ImageTaskCompletion? = nil) -> ImageTask {
        return self.taskWith(ImageRequest(URL: URL), completion: completion)
    }
    
    /// Creates a task with a given request. For more info see `taskWith(_)` methpd.
    func taskWith(_ request: ImageRequest, completion: ImageTaskCompletion?) -> ImageTask {
        let task = self.taskWith(request)
        if completion != nil { task.completion(completion!) }
        return task
    }
}


// MARK: - ImageManager (Shared)

/// Manages shared ImageManager instance.
public extension ImageManager {
    fileprivate static var sharedManagerIvar: ImageManager = ImageManager(configuration: ImageManagerConfiguration(dataLoader: ImageDataLoader()))
    fileprivate static var lock = OS_SPINLOCK_INIT
    fileprivate static var token: Int = 0
    
    /// The shared image manager. This property as well as all `ImageManager` methods are thread safe.
    public class var shared: ImageManager {
        set {
            OSSpinLockLock(&lock)
            sharedManagerIvar = newValue
            OSSpinLockUnlock(&lock)
        }
        get {
            var manager: ImageManager
            OSSpinLockLock(&lock)
            manager = sharedManagerIvar
            OSSpinLockUnlock(&lock)
            return manager
        }
    }
}
