//
//  ImageCache.swift
//  autodoc
//
//  Created by macbook pro max on 01/08/2025.
//

import UIKit

protocol ImageCaching {
    func set(_ image: UIImage, for key: String)
    func get(for key: String) -> UIImage?
    func remove(for key: String)
}

final class ImageCache: NSObject, ImageCaching {
    
    private enum Constants {
        static let totalCostLimit = 100 * 1024 * 1024
    }
    
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, ImageCacheItem>()
    
    private override init() {
        super.init()
        cache.totalCostLimit = Constants.totalCostLimit
        cache.delegate = self
    }
    
    func get(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)?.image
    }
    
    func set(_ image: UIImage, for key: String) {
        guard get(for: key) == nil else { return }
        let item = ImageCacheItem(key: key, image: image)
        cache.setObject(item, forKey: key as NSString)
    }
    
    func remove(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }
}

extension ImageCache: NSCacheDelegate {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        if self.cache == cache, let item = obj as? ImageCacheItem {
            let userInfo: [String: ImageCacheItem] = [GlobalConstants.userInfoKey: item]
            NotificationCenter.default.post(name: .cacheEvict, object: nil, userInfo: userInfo)
        }
    }
}
