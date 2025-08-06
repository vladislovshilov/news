//
//  NewsService.swift
//  autodoc
//
//  Created by macbook pro max on 31/07/2025.
//

import Foundation

protocol NewsServicing {
    func load(count: Int, page: Int) async throws -> [News]
}

final class NewsService: NewsServicing {
    
    private let networkManager: NetworkManaging
    private let baseURL = "https://webapi.autodoc.ru/api/news/"
    
    init(networkManager: NetworkManaging) {
        self.networkManager = networkManager
    }
    
    func load(count: Int, page: Int) async throws -> [News] {
        guard let url = URL(string: "\(baseURL)\(page)/\(count)") else {
            throw NetworkError.badURL
        }
        
        let request = URLRequest(url: url)
        let newsResponse: NewsResponse = try await networkManager.fetch(request)

        return newsResponse.news
    }
}
