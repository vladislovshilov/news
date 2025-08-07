//
//  ImageStore.swift
//  autodoc
//
//  Created by lil angee on 7.08.25.
//

import UIKit
import Combine

protocol ImageStoring {
    func load(for key: String) async -> UIImage?
    func store(_ image: UIImage, for key: String) async
    func cleanUp() async
}

actor ImageStore: ImageStoring {
    
    private enum Constants {
        static let directory = "ImageCache"
        static let diskSize = 100 * 1024 * 1024
        static let fileAge: TimeInterval = 7 * 24 * 60 * 60
    }
    
    static let shared = ImageStore()
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    private var cancellable: AnyCancellable?
    
    private init() {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        cacheDirectory = URL(fileURLWithPath: cachePath).appendingPathComponent(Constants.directory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        setupNotificationObservation()
    }

    nonisolated private func setupNotificationObservation() {
        Task { [weak self] in
            guard let self else { return }
            await _setupNotificationObservation()
        }
    }

    private func _setupNotificationObservation() {
        self.cancellable = NotificationCenter.default.publisher(for: .cacheEvict)
            .sink { [weak self] notification in
                guard let item = notification.userInfo?[GlobalConstants.userInfoKey] as? ImageCacheItem else { return }
                Task {
                    await self?.store(item.image, for: item.key)
                }
            }
    }
    
    func load(for key: String) async -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256())
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    func store(_ image: UIImage, for key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256())
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write image: \(error)")
        }
    }
    
    func cleanUp() async {
        Task(priority: .background) {
            do {
                let files = try fileManager.contentsOfDirectory(
                    at: cacheDirectory,
                    includingPropertiesForKeys: [.contentModificationDateKey, .totalFileAllocatedSizeKey]
                )
                
                var totalSize = 0
                var fileInfo: [(url: URL, size: Int, date: Date)] = []
                
                for file in files {
                    let values = try file.resourceValues(forKeys: [.contentModificationDateKey, .totalFileAllocatedSizeKey])
                    let date = values.contentModificationDate ?? .distantPast
                    let size = values.totalFileAllocatedSize ?? 0
                    totalSize += size
                    fileInfo.append((file, size, date))
                }
                
                let now = Date()
                for file in fileInfo where now.timeIntervalSince(file.date) > Constants.fileAge {
                    try? fileManager.removeItem(at: file.url)
                    totalSize -= file.size
                }
                
                let sorted = fileInfo.sorted { $0.date < $1.date }
                for file in sorted {
                    if totalSize <= Constants.diskSize { break }
                    try? fileManager.removeItem(at: file.url)
                    totalSize -= file.size
                }
                
            } catch {
                print("Failed to clean up cache: \(error)")
            }
        }
    }
}
