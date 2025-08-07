//
//  UIKit+Extension.swift
//  autodoc
//
//  Created by macbook pro max on 30/07/2025.
//

import UIKit

extension UIStoryboard {
    func instantiateViewController<T: UIViewController>(withIdentifier viewControllerName: ViewControllerNames) -> T {
        guard let viewController = instantiateViewController(withIdentifier: viewControllerName.identifier) as? T else {
            fatalError("Could not instantiate view controller with identifier \(viewControllerName.identifier)")
        }
        return viewController
    }
}

extension UIViewController {
    func showAlert(with message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension UICollectionViewCell {
    func animatePressScale(to scale: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: [.allowUserInteraction, .beginFromCurrentState],
                       animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            completion?()
        }
    }
}

extension UICollectionView {
    func dequeue<T: UICollectionViewCell>(cellForItemAt indexPath: IndexPath) -> T? {
        return self.dequeueReusableCell(withReuseIdentifier: "\(T.self)", for: indexPath) as? T
    }
}

extension UIImageView {
    func setImage(with url: URL?, placeholder: UIImage? = nil, showLoadingIndicator: Bool = false) async {
        let activityIndicator = UIActivityIndicatorView(frame: .init(origin: .zero, size: .init(width: 60, height: 60)))
        addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        defer {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
        
        self.image = placeholder
        
        guard let url = url else {
            return
        }
        
        do {
            let image = try await ImageLoader.shared.load(from: url)
            await MainActor.run {
                UIView.transition(with: self, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    self.image = image
                }, completion: nil)
            }
        } catch { }
    }
}
