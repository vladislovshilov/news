//
//  ImageDownloader.swift
//  autodoc
//
//  Created by macbook pro max on 01/08/2025.
//

import UIKit

protocol ImageLoading {
    func load(from urls: [URL]) async throws -> [UIImage]
    func load(from url: URL, priority: TaskPriority) async throws -> UIImage
    func cancel(for url: URL)
    func cancelAll()
}

final class ImageLoader: ImageLoading {
    
    static let shared = ImageLoader()
    
    private let cache: ImageCaching = ImageCache.shared
    private let imageStore: ImageStoring = ImageStore.shared
    private let loadRegistry = ImageLoadRegistry.shared
    
    private init() {}
    
    func load(from urls: [URL]) async throws -> [UIImage] {
        let images = await withTaskGroup(of: UIImage?.self, returning: Array<UIImage>.self) { group in
            for url in urls {
                group.addTask {
                    try? await self.load(from: url, priority: .medium)
                }
            }
            
            return await group
              .compactMap { $0 }
              .reduce(into: Array<UIImage>()) { $0.append($1) }
        }
        
        guard !images.isEmpty else { throw NetworkError.noData }
        return images
    }
    
    func load(from url: URL, priority: TaskPriority = .userInitiated) async throws -> UIImage {
        let cacheKey = url.absoluteString.sha256()
        
        if let cachedImage = cache.get(for: cacheKey) {
            return cachedImage
        }
        
        try Task.checkCancellation()
        
        if let cachedImage = await imageStore.load(for: cacheKey) {
            cache.set(cachedImage, for: cacheKey)
            return cachedImage
        }
        
        try Task.checkCancellation()
        
        return try await loadRegistry.image(for: url, priority: priority) { [weak self] in
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                throw URLError(.badServerResponse)
            }
            
            self?.cache.set(image, for: cacheKey)
            
            return image
        }
    }
    
    func cancel(for url: URL) {
        Task {
            await loadRegistry.cancel(for: url)
        }
    }
    
    func cancelAll() {
        Task {
            await loadRegistry.cancelAll()
        }
    }
}
