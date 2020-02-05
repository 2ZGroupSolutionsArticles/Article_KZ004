//
//  AsyncImageProcessor.swift
//  ImagePerfomanceTest
//
//  Created by Kseniia Zozulia on 3/4/19.
//  Copyright © 2019 Sezorus. All rights reserved.
//

import UIKit

/// `AsyncImageProcessor` class perform async operations on images
class AsyncImageProcessor {

    /// A serial `OperationQueue` to lock access to the `imageProcessingQueue` and `completionHandlers` properties.
    private let serialAccessQueue = OperationQueue()
    
    /// An `OperationQueue` that contains `ImageDownsamplingOperation`s for processing image data.
    private let imageProcessingQueue = OperationQueue()
    
    /// A dictionary of arrays of closures
    private var completionHandlers = [UUID: [(UIImage?) -> Void]]()
    
    /// An `NSCache` used to store downsampled images.
    private var cache = NSCache<NSUUID, UIImage>()
    
    // MARK: Initialization
    
    init() {
        serialAccessQueue.maxConcurrentOperationCount = 1
    }
    
    // MARK: Image processing
    
    ///  Asynchronously downsample image from specific `URL` to `maxDimentionInPixels` size.
    ///
    /// - Parameters:
    ///   - identifier: The `UUID` for downsampled image.
    ///   - imageURL: The `URL` to local stored image file.
    ///   - maxDimentionInPixels: The maximum width and height in pixels of a thumbnail.
    ///   - completion: An optional handler which called when image has been downsamples.
    func downsampleAsync(_ identifier: UUID, imageURL: URL, maxDimentionInPixels: CGFloat, completion: ((UIImage?) -> Void)? = nil) {
        serialAccessQueue.addOperation {
            if let completion = completion {
                let handlers = self.completionHandlers[identifier, default: []]
                self.completionHandlers[identifier] = handlers + [completion]
            }
            
            self.downsampleImage(for: identifier, imageURL: imageURL, maxDimentionInPixels: maxDimentionInPixels)
        }
    }
    
    /// Begin downsample operation for image by specific `URL`, invoke completion handler when operation is finished
    ///
    /// - Parameters:
    ///   - identifier: The `UUID` for downsampled image.
    ///   - imageURL: The `URL` to local stored image file.
    ///   - maxDimentionInPixels: The maximum width and height in pixels of a thumbnail.
    private func downsampleImage(for identifier: UUID, imageURL: URL, maxDimentionInPixels: CGFloat) {
        guard operation(for: identifier) == nil else { return }
        
        if let data = downsampledImage(for: identifier) {
            invokeCompletionHandlers(for: identifier, with: data)
            return
        }
        
        let downsampleOperation = ImageDownsamplingOperation(identifier: identifier, imageURL: imageURL,
                                                             maxDimentionInPixels: maxDimentionInPixels)
        
        downsampleOperation.completionBlock = { [weak downsampleOperation] in
            guard let downsampledImage = downsampleOperation?.downsampledImage else { return }
            self.cache.setObject(downsampledImage, forKey: identifier as NSUUID)
            
            self.serialAccessQueue.addOperation {
                self.invokeCompletionHandlers(for: identifier, with: downsampledImage)
            }
        }
        
        imageProcessingQueue.addOperation(downsampleOperation)
    }
    
    /// Returns the previously downsampled `UIImage` by specified `UUID`.
    ///
    /// - Parameter identifier: The `UUID` for downsampled image
    /// - Returns: The already downsampled 'UIImage' object from `cache` or nil.
    func downsampledImage(for identifier: UUID) -> UIImage? {
        return cache.object(forKey: identifier as NSUUID)
    }
    
    // MARK: Manage enqueued operations.

    /// Cancel enqueued downsampling operation by `identifier`.
    ///
    /// - Parameter identifier: The `UUID` to cancel downsampling operation.
    func cancelDownsampling(_ identifier: UUID) {
        serialAccessQueue.addOperation {
            self.imageProcessingQueue.isSuspended = true

            self.operation(for: identifier)?.cancel()
            self.completionHandlers[identifier] = nil
            
            self.imageProcessingQueue.isSuspended = false
        }
    }
    
    /// Returns equeued `ImageDownsamplingOperation` for specified `identifier`.
    ///
    /// - Parameter identifier: The `UUID` of the operation to return.
    /// - Returns: The enqueued `ImageDownsamplingOperation` or nil.
    private func operation(for identifier: UUID) -> ImageDownsamplingOperation? {
        for case let fetchOperation as ImageDownsamplingOperation in imageProcessingQueue.operations
            where !fetchOperation.isCancelled && fetchOperation.identifier == identifier {
                return fetchOperation
        }
        
        return nil
    }
    
    // MARK: Completion
    
    /// Invokes completion handlers by specified `UUID`.
    ///
    /// - Parameters:
    ///   - identifier:  The `UUID` of the completion handler.
    ///   - downsampledImage: The downsampled image to pass when calling a completion handler.
    private func invokeCompletionHandlers(for identifier: UUID, with downsampledImage: UIImage) {
        let completionHandlers = self.completionHandlers[identifier, default: []]
        self.completionHandlers[identifier] = nil
        
        for completionHandler in completionHandlers {
            completionHandler(downsampledImage)
        }
    }
}
