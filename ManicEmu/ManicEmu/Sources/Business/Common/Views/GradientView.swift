//
//  GradientView.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2023/5/11.
//  Copyright © 2023 Aoshuang Lee. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    func setupGradient(colors: [SFColor], locations: [CGFloat] = [0.0, 1.0], direction: GradientDirection) {
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.locations = locations.map { NSNumber(value: $0) }
        gradientLayer.startPoint = direction.startPoint
        gradientLayer.endPoint = direction.endPoint
        if let _ = gradientLayer.superlayer { } else {
            layer.addSublayer(gradientLayer)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
