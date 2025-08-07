//
//  ImageLoadRegistry.swift
//  autodoc
//
//  Created by lil angee on 6.08.25.
//

import UIKit

actor ImageLoadRegistry {
    static let shared = ImageLoadRegistry()
    
    private var tasks: [URL: Task<UIImage, Error>] = [:]

    func image(for url: URL, priority: TaskPriority, loader: @escaping () async throws -> UIImage) async throws -> UIImage {
        if let existing = tasks[url] {
            return try await existing.value
        }
        
        let task = Task(priority: priority) {
            defer { self.remove(for: url) }
            return try await loader()
        }
        
        tasks[url] = task
        return try await task.value
    }

    func cancel(for url: URL) {
        tasks[url]?.cancel()
        tasks[url] = nil
    }
    
    func cancelAll() {
        tasks.forEach { $0.value.cancel() }
        tasks.removeAll()
    }

    func remove(for url: URL) {
        tasks[url] = nil
    }
}
