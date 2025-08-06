//
//  NetworkManager.swift
//  autodoc
//
//  Created by macbook pro max on 31/07/2025.
//

import Foundation

protocol NetworkManaging {
    func fetch<T: Decodable>(_ urlRequest: URLRequest) async throws -> T
}

final class NetworkManager: NetworkManaging {
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetch<T: Decodable>(_ urlRequest: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
            }

            let parsedResponse = try decoder.decode(T.self, from: data)
            return parsedResponse
        } catch let error as DecodingError {
            throw NetworkError.decodingFailed(error)
        } catch let error as URLError {
            throw NetworkError(statusCode: error.code.rawValue)
        }
    }
}
