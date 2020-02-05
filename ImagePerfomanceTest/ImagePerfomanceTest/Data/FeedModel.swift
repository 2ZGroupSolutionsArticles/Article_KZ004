//
//  FeedModel.swift
//  ImagePerfomanceTest
//
//  Created by Kseniia on 3/12/19.
//  Copyright © 2019 Sezorus. All rights reserved.
//

import UIKit

/// The model to keep the information about downsampled image.
struct FeedModel {
    
    // MARK: Properties
    
    /// The downsampled image.
    var image: UIImage?
    
    /// The `URL` to local stored image file.
    var url: URL
    
    /// The model identifier.
    var id: UUID
    
    init(id: UUID, url: URL) {
        self.url = url
        self.id = id
    }
}
