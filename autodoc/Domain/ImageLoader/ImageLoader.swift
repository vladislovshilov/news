//
//  ImageDownloader.swift
//  autodoc
//
//  Created by macbook pro max on 01/08/2025.
//

import UIKit

class ImageLoader {
    static let shared = ImageLoader()
    
    private let cache: ImageCaching = ImageCache.shared
    private let diskCache: DiskCaching = DiskCache.shared
    private let loadRegistry = ImageLoadRegistry.shared
    
    private init() {}
    
    func loadImage(from url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString.sha256()
        
        if let cachedImage = cache.get(for: cacheKey) {
            return cachedImage
        }
        
        if let cachedImage = await diskCache.getImage(for: cacheKey) {
            cache.set(cachedImage, for: cacheKey)
            return cachedImage
        }
        
        return try await loadRegistry.image(for: url) { [weak self] in
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                throw URLError(.badServerResponse)
            }
            
            self?.cache.set(image, for: cacheKey)
//            self?.diskCache.storeImage(image, for: cacheKey)
            
            return image
        }
    }
    
    func cancelLoad(for url: URL) {
        Task {
            await loadRegistry.cancel(for: url)
        }
    }
}
