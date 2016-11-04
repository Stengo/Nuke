// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import Foundation
import UIKit

/// Signals the delegate that the preheat window changes.
public protocol ImagePreheatingControllerDelegate: class {
    /// Signals the delegate that the preheat window changes. Provides an array of index paths being added and being removed from the previously calculated preheat window.
    func preheatingController(_ controller: ImagePreheatingController, didUpdateWithAddedIndexPaths addedIndexPaths: [IndexPath], removedIndexPaths: [IndexPath])
}

/**
 Automates image preheating. Abstract class.
 
 After creating image preheating controller you should enable it by settings enabled property to true.
*/
open class ImagePreheatingController: NSObject {
    /// The delegate of the receiver.
    open weak var delegate: ImagePreheatingControllerDelegate?

    /// The scroll view that the receiver was initialized with.
    open let scrollView: UIScrollView

    /// Current preheat index paths.
    open fileprivate(set) var preheatIndexPath = [IndexPath]()

    /// Default value is false. When image preheating controller is enabled it immediately updates preheat index paths and starts reacting to user actions. When preheating controller is disabled it removes all current preheating index paths and signals its delegate.
    open var enabled = false
    
    deinit {
        scrollView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
    }

    /// Initializes the receiver with a given scroll view.
    public init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init()
        self.scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
    }

    /// Calls `scrollViewDidScroll(_)` method when `contentOffset` of the scroll view changes.
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === scrollView {
            scrollViewDidScroll()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: nil)
        }
    }
    
    // MARK: Subclassing Hooks

    /// Abstract method. Subclassing hook.
    open func scrollViewDidScroll() {
        assert(false)
    }

    /// Updates preheat index paths and signals delegate. Don't call this method directly, it should be used by subclasses.
    open func updatePreheatIndexPaths(_ indexPaths: [IndexPath]) {
        let addedIndexPaths = indexPaths.filter { return !preheatIndexPath.contains($0) }
        let removedIndexPaths = Set(preheatIndexPath).subtracting(indexPaths)
        preheatIndexPath = indexPaths
        delegate?.preheatingController(self, didUpdateWithAddedIndexPaths: addedIndexPaths, removedIndexPaths: Array(removedIndexPaths))
    }
}

// MARK: Internal

internal func distanceBetweenPoints(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    let dx = p2.x - p1.x, dy = p2.y - p1.y
    return sqrt((dx * dx) + (dy * dy))
}

internal enum ScrollDirection {
    case forward, backward
}

internal func sortIndexPaths<T: Sequence>(_ indexPaths: T, inScrollDirection scrollDirection: ScrollDirection) -> [IndexPath] where T.Iterator.Element == IndexPath {
    return indexPaths.sorted {
        switch scrollDirection {
        case .forward: return $0.section < $1.section || $0.item < $1.item
        case .backward: return $0.section > $1.section || $0.item > $1.item
        }
    }
}
