//
//  NewsViewModel.swift
//  autodoc
//
//  Created by macbook pro max on 31/07/2025.
//

import Foundation
import Combine

final class NewsViewModel {
    
    @Published private(set) var items = [NewsItem]()
    @Published private(set) var selectedItem: NewsItem?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let newsService: NewsServicing
    private let loadNextSubject = PassthroughSubject<Void, Never>()
    
    private let fetchCount = 15
    private var currentPage = 1
    private var hasMore = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init(newsService: NewsServicing = NewsService(networkManager: NetworkManager())) {
        self.newsService = newsService
        
        loadNextSubject
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                Task { await self?.fetchNextPage() }
            }
            .store(in: &cancellables)
    }
    
    func loadInitial() {
        reset()
        Task { await fetchNextPage() }
    }
    
    func loadNextIfNeeded(currentItem: NewsItem?) {
        guard let currentItem, hasMore else { return }
        
        let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0.id == currentItem.id }) == thresholdIndex {
            loadNextSubject.send()
        }
    }
    
    func selectItem(at indexPath: IndexPath) {
        guard let selectedItem = items[safe: indexPath.row] else {
            errorMessage = "Can not select item"
            return
        }
        self.selectedItem = selectedItem
    }
}

// MARK: - Helpers

extension NewsViewModel {
    private func reset() {
        items = []
        currentPage = 1
        hasMore = true
        errorMessage = nil
    }
    
    private func fetchNextPage() async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            let newItems = try await newsService.load(count: fetchCount, page: currentPage).map(NewsItem.init)
            currentPage += 1
            hasMore = !newItems.isEmpty
            errorMessage = nil
            
            await MainActor.run {
                self.items.append(contentsOf: newItems)
            }
        } catch let error as NetworkError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}
