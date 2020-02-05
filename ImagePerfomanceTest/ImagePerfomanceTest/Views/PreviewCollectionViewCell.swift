//
//  PreviewCollectionViewCell.swift
//  ImagePerfomanceTest
//
//  Created by Kseniia Zozulia on 3/4/19.
//  Copyright © 2019 Sezorus. All rights reserved.
//

import UIKit

class PreviewCollectionViewCell: UICollectionViewCell, ReusableView {
    
    // MARK: Properties

    /// `UIImageView` to display an image.
    @IBOutlet weak var previewImageView: UIImageView!
    
    /// The `UUID` for connect with async processings.
    var representedId: UUID?
    
    /// Configures the cell for display the `UIImage`.
    ///
    /// - Parameter image: The `UIImage` to display or nil.
    func update(with image: UIImage?) {
        previewImageView.image = image
    }
}
