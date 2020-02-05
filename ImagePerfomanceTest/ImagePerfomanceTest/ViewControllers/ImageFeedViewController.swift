//
//  ImageFeedViewController.swift
//  ImagePerfomanceTest
//
//  Created by Kseniia Zozulia on 2/27/19.
//  Copyright © 2019 Sezorus. All rights reserved.
//

import UIKit

class ImageFeedViewController: UIViewController {
    
    // MARK: Properties

    /// The `UICollectionView` for display downsampled images
    @IBOutlet private weak var collectionView: UICollectionView!
    
    /// The `UICollectionView` datasource and prefetchDataSource
    private let dataSource = ImageFeedDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the collection data source.
        collectionView.dataSource = dataSource

        // Set the collection prefetching data source.
        collectionView.prefetchDataSource = dataSource
    }
}

extension ImageFeedViewController : UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewWidth = collectionView.bounds.width
        return CGSize(width: collectionViewWidth/3, height: collectionViewWidth/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}
