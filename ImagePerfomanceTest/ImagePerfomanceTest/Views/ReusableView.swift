//
//  ReusableView.swift
//  ImagePerfomanceTest
//
//  Created by Kseniia Zozulia on 3/4/19.
//  Copyright © 2019 Sezorus. All rights reserved.
//


import UIKit

/// Protocol for views which may be reusable.
protocol ReusableView: class {
    
    /// A string used to identify a `ReusableView` that is reusable.
    static var defaultReuseIdentifier: String { get }
}

extension ReusableView where Self: UIView {
    static var defaultReuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T where T: ReusableView {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        
        return cell
    }
}
