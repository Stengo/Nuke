// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import Foundation

/// Manages execution of image tasks for image loading view.
open class ImageViewLoadingController {
    /// Current image task.
    open var imageTask: ImageTask?
    
    /// Handler that gets called each time current task completes.
    open var handler: (ImageTask, ImageResponse, ImageViewLoadingOptions) -> Void
    
    /// The image manager that is used for creating image tasks. The shared manager is used by default.
    open var manager: ImageManager = ImageManager.shared
    
    deinit {
        self.cancelLoading()
    }

    /// Initializes the receiver with a given handler.
    public init(handler: @escaping (ImageTask, ImageResponse, ImageViewLoadingOptions) -> Void) {
        self.handler = handler
    }
    
    /// Cancels current image task.
    open func cancelLoading() {
        if let task = imageTask {
            imageTask = nil
            // Cancel task after delay to allow new tasks to subscribe to the existing NSURLSessionTask.
            DispatchQueue.main.async(execute: {
                task.cancel()
            })
        }
    }
    
    open func setImageWith(_ request: ImageRequest, options: ImageViewLoadingOptions) -> ImageTask {
        return setImageWith(manager.taskWith(request), options: options)
    }
    
    open func setImageWith(_ task: ImageTask, options: ImageViewLoadingOptions) -> ImageTask {
        cancelLoading()
        imageTask = task
        task.completion { [weak self, weak task] in
            if let task = task, task == self?.imageTask {
                self?.handler(task, $0, options)
            }
        }
        task.resume()
        return task
    }
}
