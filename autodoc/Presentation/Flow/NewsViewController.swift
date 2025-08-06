//
//  ViewController.swift
//  autodoc
//
//  Created by lil angee on 28.07.25.
//

import UIKit
import Combine

final class NewsViewController: UIViewController {
    
    enum Section {
        case main
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, NewsItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, NewsItem>
    
    var viewModel: NewsViewModel!
    var itemSelectionCallback: ((_ link: URL) -> Void)?

    @IBOutlet private var collectionView: UICollectionView!
    private let refreshControl = UIRefreshControl()
    private let emptyStateView: UILabel = {
        let label = UILabel()
        label.text = "No items to show/Pull to refresh"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 18)
        label.isHidden = true
        return label
    }()
    
    private lazy var dataSource = makeDataSource()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
       
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        
        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyStateView.widthAnchor.constraint(lessThanOrEqualTo: collectionView.widthAnchor, multiplier: 0.9)
        ])
        
        viewModel.loadInitial()
    }
    
    private func bindViewModel() {
        viewModel.$items
            .receive(on: RunLoop.main)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] items in
                self?.refreshControl.endRefreshing()
                self?.applySnapshot(with: items)
            }
            .store(in: &cancellables)
        
        viewModel.$selectedItem
            .receive(on: RunLoop.main)
            .compactMap { $0?.fullUrl }
            .compactMap(URL.init)
            .sink { [weak self] url in
                self?.itemSelectionCallback?(url)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.refreshControl.endRefreshing()
                self?.showAlert(with: error)
            }
            .store(in: &cancellables)
    }


    private func applySnapshot(with items: [NewsItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, NewsItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        
        UIView.transition(with: emptyStateView, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.emptyStateView.isHidden = !items.isEmpty
        }, completion: nil)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, item) ->
                UICollectionViewCell? in
                guard let cell: NewsCell = collectionView.dequeue(cellForItemAt: indexPath) else {
                    return UICollectionViewCell()
                }
                cell.configure(with: item)
                return cell
            })
        
        return dataSource
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalWidth(0.5)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(0.5)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item, item]
        )

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func animateCellTransition(from cell: UICollectionViewCell, indexPath: IndexPath) {
        guard let window = view.window else { return }

        let cellFrameInSuperview = cell.convert(cell.bounds, to: window)

        guard let snapshot = cell.snapshotView(afterScreenUpdates: true) else { return }
        snapshot.frame = cellFrameInSuperview
        window.addSubview(snapshot)

        cell.isHidden = true

        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseInOut],
                       animations: {
            snapshot.frame = window.bounds
        }, completion: { [weak self] _ in
            cell.isHidden = false
            cell.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            snapshot.removeFromSuperview()
            
            self?.viewModel.selectItem(at: indexPath)
        })
    }
    
    @objc private func refreshData() {
        viewModel.loadInitial()
    }
}

extension NewsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? NewsCell else { return }
        
        cell.animatePressScale(to: 0.8) {
            self.animateCellTransition(from: cell, indexPath: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let item = dataSource.itemIdentifier(for: indexPath)
        viewModel.loadNextIfNeeded(currentItem: item)
    }
}
