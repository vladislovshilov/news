//
//  NetworkError.swift
//  autodoc
//
//  Created by macbook pro max on 31/07/2025.
//

import Foundation

enum NetworkError: Error {
    case badURL
    case requestFailed(Error)
    case invalidResponse
    case statusCode(Int)
    case noData
    case decodingFailed(Error)
    case timeout
    case unauthorized
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The URL is invalid."
        case .requestFailed(let error):
            return "Request failed with error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from the server."
        case .statusCode(let code):
            if code == 429 {
                return "Ooops...to much requests. Wait a bit..."
            }
            return "Something went wrong. Unexpected status code: \(code)."
        case .noData:
            return "No data was returned from the server."
        case .decodingFailed(let error):
            return "Failed to decode the data: \(error.localizedDescription)"
        case .timeout:
            return "The request timed out."
        case .unauthorized:
            return "You are not authorized to perform this request."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

extension NetworkError {
    init(statusCode: Int) {
        switch statusCode {
        case 401:
            self = .unauthorized
        case 408:
            self = .timeout
        case 400..<500:
            self = .statusCode(statusCode)
        case 500..<600:
            self = .statusCode(statusCode)
        default:
            self = .unknown
        }
    }
}
