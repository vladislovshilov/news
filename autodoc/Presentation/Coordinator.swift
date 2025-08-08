//
//  Coordinator.swift
//  autodoc
//
//  Created by macbook pro max on 30/07/2025.
//

import UIKit
import SafariServices

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController? { get }
    
    func start()
}

final class MainCoordinator: Coordinator {
    
    var navigationController: UINavigationController?
    
    private let windows: [UIWindow?]
    private let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    private lazy var networkManager = NetworkManager()
    private lazy var newsService = NewsService(networkManager: networkManager)
    private let imageLoader: ImageLoading = ImageLoader.shared
    
    init(navigationController: UINavigationController?, windows: [UIWindow?]) {
        self.navigationController = navigationController
        self.windows = windows
    }
    
    func start() {
        Task.detached {
            await ImageStore.shared.cleanUp()
        }
        
        showNewsList()
    }
    
    private func showNewsList() {
        let viewModel = NewsViewModel(newsService: newsService, imageLoader: imageLoader)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: .news) as? NewsViewController else {
            return
        }
        
        viewController.viewModel = viewModel
        viewController.itemSelectionCallback = { [weak self] url in
            self?.showWebPage(with: url)
        }
        
        navigationController?.setViewControllers([viewController], animated: true)
    }
    
    private func showWebPage(with url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .fullScreen
        
        navigationController?.present(safariVC, animated: true)
    }
}
