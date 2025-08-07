//
//  DiskCache.swift
//  autodoc
//
//  Created by macbook pro max on 01/08/2025.
//

import UIKit

protocol DiskCaching {
    func load(for key: String, completion: @escaping (UIImage?) -> Void)
    func load(for key: String) async -> UIImage?
    func store(_ image: UIImage, for key: String)
    func cleanUp()
}

final class DiskCache: DiskCaching {
    
    private enum Constants {
        static let queueLabel = "com.imageLoader.diskCache"
        static let directory = "ImageCache"
        static let diskSize = 100 * 1024 * 1024
        static let fileAge: TimeInterval = 7 * 24 * 60 * 60
    }
    
    static let shared = DiskCache()
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: Constants.queueLabel, attributes: .concurrent)
    let a = DispatchSource.makeReadSource(fileDescriptor: 32)
    
    private init() {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        cacheDirectory = URL(fileURLWithPath: cachePath).appendingPathComponent(Constants.directory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCacheEvictNotification(_:)), name: .cacheEvict, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func load(for key: String) async -> UIImage? {
        await withCheckedContinuation { continuation in
            load(for: key) { image in
                continuation.resume(returning: image)
            }
        }
    }
    
    func load(for key: String, completion: @escaping (UIImage?) -> Void) {
        queue.async {
            let fileURL = self.cacheDirectory.appendingPathComponent(key.sha256())
            guard let data = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            completion(image)
        }
    }
    
    func store(_ image: UIImage, for key: String) {
        queue.async(flags: .barrier) {
            let fileURL = self.cacheDirectory.appendingPathComponent(key.sha256())
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }
    
    func cleanUp() {
        queue.async(flags: .barrier) {
            guard let files = try? self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .totalFileAllocatedSizeKey]) else {
                return
            }
            
            var totalSize = 0
            var fileInfo: [(url: URL, size: Int, date: Date)] = []
            
            for file in files {
                let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .totalFileAllocatedSizeKey])
                let date = values?.contentModificationDate ?? .distantPast
                let size = values?.totalFileAllocatedSize ?? 0
                totalSize += size
                fileInfo.append((file, size, date))
            }
            
            let now = Date()
            for file in fileInfo where now.timeIntervalSince(file.date) > Constants.fileAge {
                try? self.fileManager.removeItem(at: file.url)
                totalSize -= file.size
            }
            
            let sorted = fileInfo.sorted { $0.date < $1.date }
            for file in sorted {
                if totalSize <= Constants.diskSize { break }
                try? self.fileManager.removeItem(at: file.url)
                totalSize -= file.size
            }
        }
    }
    
    @objc private func handleCacheEvictNotification(_ notification: Notification) {
//        if let item = notification.userInfo?[GlobalConstants.userInfoKey] as? ImageCacheItem {
//            store(item.image, for: item.key)
//        }
    }
}
