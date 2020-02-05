//
//  ImageFeedDataSource.swift
//  ImagePerfomanceTest
//
//  Created by Kseniia Zozulia on 3/4/19.
//  Copyright © 2019 Sezorus. All rights reserved.
//

import UIKit

class ImageFeedDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
   
    // MARK: Properties
    
    /// An `AsyncImageProcessor` for asynchronously image downsampling.
    private let imageProcessor = AsyncImageProcessor()
    
    /// An array of local images URLs
    private lazy var models: [FeedModel] = {
        var models: [FeedModel] = []
        for i in 0...32 {
            let path = Bundle.main.path(forResource: "img_" + "\(i)", ofType: "jpg")!
            let fileURL = URL(fileURLWithPath: path)
            models.append(FeedModel(id: UUID.init(), url: fileURL))
        }
        return models
    }()
    
    // MARK: Helpers
    
    private func getMaxDimentionInPixelsFrom(_ cell: PreviewCollectionViewCell, scale: CGFloat) -> CGFloat {
        let imageViewSize        = cell.previewImageView.bounds.size
        return max(imageViewSize.width, imageViewSize.height) * scale
    }
    
    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PreviewCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)

        let model   = models[indexPath.row]
        let fileURL = model.url
        let maxDimentionInPixels = getMaxDimentionInPixelsFrom(cell, scale: collectionView.traitCollection.displayScale)

        cell.representedId = model.id

        if let downsampledImage = imageProcessor.downsampledImage(for: model.id) {
            cell.update(with: downsampledImage)
            return cell
        }
        
        cell.update(with: nil)
        
        imageProcessor.downsampleAsync(model.id, imageURL: fileURL, maxDimentionInPixels: maxDimentionInPixels) { image in
            DispatchQueue.main.async {
                guard cell.representedId == model.id else { return }
                cell.update(with: image)
            }
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let model = models[indexPath.row]
            let cell: PreviewCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            let maxDimentionInPixels = getMaxDimentionInPixelsFrom(cell, scale: collectionView.traitCollection.displayScale)
            imageProcessor.downsampleAsync(model.id, imageURL: model.url, maxDimentionInPixels: maxDimentionInPixels)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let model = models[indexPath.row]
            imageProcessor.cancelDownsampling(model.id)
        }
    }
}
