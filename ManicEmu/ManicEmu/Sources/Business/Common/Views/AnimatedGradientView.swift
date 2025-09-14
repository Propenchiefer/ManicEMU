//
//  AnimatedGradientView.swift
//  ManicEmu
//
//  Created by Max on 2025/1/1.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
// really shitty  metal HUD solution half made with chatgpt half made with pain and suffering

final class AnimatedGradientView: UIView {
    var transitionSpeed: Double = 10
    var bias: CGFloat = 0.0025
    var renderScale: CGFloat = 2

    // MARK: Animation
    private let gradient = CAGradientLayer()
    private var gradientAnimationKey = "manic.gradient.locations"
    private var gradientColors: [CGColor] = []
    
    var speed: Double = 10 {
        didSet { restartIfNeeded() }
    }

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(gradient)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.locations  = [0.0, 0.5, 1.0] as [NSNumber]

        NotificationCenter.default.addObserver(self, selector: #selector(pause),
                                               name: Constants.NotificationName.StartPlayGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resume),
                                               name: Constants.NotificationName.StopPlayGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFromTheme),
                                               name: Constants.NotificationName.GradientColorChange, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    deinit { NotificationCenter.default.removeObserver(self) }
    convenience init(notifiedUpadate: Bool = false, alphaComponent: CGFloat = 1.0) {
        self.init(frame: .zero)
        let base = Constants.Color.Gradient
        let colors = (alphaComponent > 0 && alphaComponent < 1)
            ? base.map { $0.withAlphaComponent(alphaComponent) }
            : base
        setColors(colors, animated: false)

        if notifiedUpadate {
        }
    }

    convenience init(colors: [UIColor], notifiedUpadate: Bool = false, alphaComponent: CGFloat = 1.0) {
        self.init(frame: .zero)
        let c = (alphaComponent > 0 && alphaComponent < 1)
            ? colors.map { $0.withAlphaComponent(alphaComponent) }
            : colors
        setColors(c, animated: false)

        if notifiedUpadate {
        }
    }

    func setColors(_ colors: [UIColor]) {
        setColors(colors, animated: false)
    }

    func setColors(_ colors: [UIColor], animated: Bool = false) {
        let new = colors.map { $0.cgColor }
        if animated, !gradientColors.isEmpty {
            let anim = CABasicAnimation(keyPath: "colors")
            anim.fromValue = gradientColors
            anim.toValue = new
            anim.duration = 0.3
            anim.fillMode = .forwards
            anim.isRemovedOnCompletion = false
            gradient.add(anim, forKey: "manic.gradient.colors.crossfade")
        }
        gradientColors = new
        gradient.colors = new
        restartIfNeeded()
    }
    
    @objc private func updateFromTheme() {
    }

    private func restartIfNeeded() {
        gradient.removeAnimation(forKey: gradientAnimationKey)
        guard speed > 0, gradientColors.count >= 2 else { return }
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [-1.0, -0.5, 0.0].map { NSNumber(value: $0) }
        anim.toValue   = [1.0, 1.5, 2.0].map { NSNumber(value: $0) }
        anim.duration = speed
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        gradient.add(anim, forKey: gradientAnimationKey)
    }

    @objc private func pause()  { pauseLayer(gradient) }
    @objc private func resume() { resumeLayer(gradient) }

    private func pauseLayer(_ layer: CALayer) {
        let t = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = t
    }

    private func resumeLayer(_ layer: CALayer) {
        let paused = layer.timeOffset
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        let sincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - paused
        layer.beginTime = sincePause
    }
}
