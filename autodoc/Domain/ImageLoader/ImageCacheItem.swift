//
//  ImageCacheItem.swift
//  autodoc
//
//  Created by lil angee on 6.08.25.
//

import UIKit

class ImageCacheItem {
    var key: String
    var image: UIImage
    
    init(key: String, image: UIImage) {
        self.key = key
        self.image = image
    }
}
