//
//  News.swift
//  autodoc
//
//  Created by macbook pro max on 30/07/2025.
//

import UIKit

struct NewsResponse: Decodable {
    let news: [News]
    let totalCount: Int
}

struct News: Decodable, Equatable {
    let id: Int
    let title: String
    let description: String
    let publishedDate: String
    let url: String
    let fullUrl: String
    let titleImageUrl: String? // TODO: - Handle the case when backend doesn't sned this field
    let categoryType: String
}
