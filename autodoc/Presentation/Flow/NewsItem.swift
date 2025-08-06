//
//  NewsItem.swift
//  autodoc
//
//  Created by macbook pro max on 31/07/2025.
//

import Foundation

struct NewsItem: Hashable, Identifiable {
    let id: Int
    let title: String
    let imageUrl: URL?
    let category: String
    let fullUrl: String
}

extension NewsItem {
    init(from news: News) {
        self.id = news.id
        self.title = news.title
        self.category = news.categoryType
        self.fullUrl = news.fullUrl
        if let path = news.titleImageUrl {
            self.imageUrl = URL(string: path)
        } else {
            self.imageUrl = nil
        }
    }
}
