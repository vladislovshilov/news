//
//  NewsCell.swift
//  autodoc
//
//  Created by macbook pro max on 30/07/2025.
//

import UIKit

final class NewsCell: UICollectionViewCell {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleContainerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    private var url: URL?
    private var task: Task<Void, Never>?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.masksToBounds = false
        
        transform = .identity
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        animatePressScale(to: 0.8)
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        animatePressScale(to: 1.0)
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        animatePressScale(to: 1.0)
        super.touchesCancelled(touches, with: event)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if let url {
            ImageLoader.shared.cancelLoad(for: url)
        }
        imageView.image = nil
        task?.cancel()
        task = nil
    }

    func configure(with news: NewsItem) {
        url = news.imageUrl
        titleLabel?.text = news.title
        task = Task {
            await imageView.setImage(with: news.imageUrl, placeholder: UIImage(named: "placeholder"))
        }
    }
}
