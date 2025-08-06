//
//  LoadingView.swift
//  autodoc
//
//  Created by macbook pro max on 01/08/2025.
//

import UIKit

final class LoadingCell: UICollectionViewCell {
    static let reuseIdentifier = "LoadingCell"
    
    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
        spinner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        spinner.startAnimating()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
