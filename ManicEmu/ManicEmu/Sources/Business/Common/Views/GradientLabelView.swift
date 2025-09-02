//
//  GradientLabelView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/17.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class GradientLabelView: UILabel {
    private let gradientLayer = CAGradientLayer()
    private let maskLayer = CALayer()
    
    private var gradientColorChangeNotification: Any? = nil
    
    deinit {
        if let gradientColorChangeNotification = gradientColorChangeNotification {
            NotificationCenter.default.removeObserver(gradientColorChangeNotification)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = Constants.Color.Gradient.map({ $0.cgColor })
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.locations = Constants.Color.Gradient.gradientLocations().map({ NSNumber(floatLiteral: $0) })
        layer.addSublayer(gradientLayer)
        
        gradientColorChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.GradientColorChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.gradientLayer.colors = Constants.Color.Gradient.map({ $0.cgColor })
            self.gradientLayer.locations = Constants.Color.Gradient.gradientLocations().map({ NSNumber(floatLiteral: $0) })
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { context in
            self.layer.render(in: context.cgContext)
        }
        maskLayer.contents = image.withRenderingMode(.alwaysTemplate).cgImage
        gradientLayer.frame = bounds
        maskLayer.frame = gradientLayer.frame
        gradientLayer.mask = maskLayer
        textColor = .clear
    }
}
