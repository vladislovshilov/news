//
//  Foundation+Extension.swift
//  autodoc
//
//  Created by macbook pro max on 01/08/2025.
//

import Foundation
import UIKit
import CommonCrypto

extension Dictionary where Value: Equatable {
    func someKey(for value: Value) -> Key? {
        return first(where: { $1 == value })?.key
    }
}

extension Notification.Name {
    static let cacheEvict = Notification.Name("CacheEvict")
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension String {
    func sha256() -> String {
        if let data = data(using: .utf8) {
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
            }
            return digest.map { String(format: "%02hhx", $0) }.joined()
        }
        return self
    }
}
