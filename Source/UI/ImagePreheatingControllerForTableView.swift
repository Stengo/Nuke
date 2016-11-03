// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import UIKit

/// Preheating controller for `UITableView`.
open class ImagePreheatingControllerForTableView: ImagePreheatingController {
    /// The table view that the receiver was initialized with.
    open var tableView: UITableView {
        return scrollView as! UITableView
    }

    /// The proportion of the collection view size (either width or height depending on the scroll axis) used as a preheat window.
    open var preheatRectRatio: CGFloat = 1.0

    /// Determines how far the user needs to refresh preheat window.
    open var preheatRectUpdateRatio: CGFloat = 0.33

    fileprivate var previousContentOffset = CGPoint.zero

    /// Initializes the receiver with a given table view.
    public init(tableView: UITableView) {
        super.init(scrollView: tableView)
    }

    /// Default value is false. See superclass for more info.
    open override var enabled: Bool {
        didSet {
            if enabled {
                updatePreheatRect()
            } else {
                previousContentOffset = CGPoint.zero
                updatePreheatIndexPaths([])
            }
        }
    }

    open override func scrollViewDidScroll() {
        if enabled {
            updatePreheatRect()
        }
    }

    fileprivate func updatePreheatRect() {
        let updateMargin = tableView.bounds.height * preheatRectUpdateRatio
        let contentOffset = tableView.contentOffset
        guard distanceBetweenPoints(contentOffset, previousContentOffset) > updateMargin || previousContentOffset == CGPoint.zero else {
            return
        }
        let scrollDirection: ScrollDirection = (contentOffset.y >= previousContentOffset.y || previousContentOffset == CGPoint.zero) ? .forward : .backward

        previousContentOffset = contentOffset
        let preheatRect = preheatRectInScrollDirection(scrollDirection)
        let preheatIndexPaths = Set(tableView.indexPathsForRows(in: preheatRect) ?? []).subtracting(tableView.indexPathsForVisibleRows ?? [])
        updatePreheatIndexPaths(sortIndexPaths(preheatIndexPaths, inScrollDirection: scrollDirection))
    }

    fileprivate func preheatRectInScrollDirection(_ direction: ScrollDirection) -> CGRect {
        let viewport = CGRect(origin: tableView.contentOffset, size: tableView.bounds.size)
        let height = viewport.height * preheatRectRatio
        let y = (direction == .forward) ? viewport.maxY : viewport.minY - height
        return CGRect(x: 0, y: y, width: viewport.width, height: height).integral
    }
}
