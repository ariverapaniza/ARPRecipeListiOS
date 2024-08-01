//
//  LoadingView.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 28/6/2024.
//

import Foundation
import UIKit

class LoadingView: UIView {
    
    var show: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.25)
        addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if show {
            loadingIndicator.startAnimating()
            isHidden = false
        } else {
            loadingIndicator.stopAnimating()
            isHidden = true
        }
    }
}
