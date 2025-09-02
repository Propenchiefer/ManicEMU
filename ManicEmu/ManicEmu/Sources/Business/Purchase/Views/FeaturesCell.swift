//
//  FeaturesCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/15.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import Device

class FeaturesCell: UICollectionViewCell {
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.title(size: .s, weight: .semibold)
        view.textColor = Constants.Color.LabelPrimary
        return view
    }()
    
    var questionButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .questionmarkCircleFill, size: 12))
        view.delayInteractiveTouchEnd = true
        view.backgroundColor = .clear
        return view
    }()
    
    private var iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        if Device.size().rawValue < Size.screen5_8Inch.rawValue {
            view.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }
        return view
    }()
    
    private var advanceDescriptionView: UIView = {
        let view = UIView()
        view.isHidden = true
        func makeLabel(string: String, x: CGFloat, y: CGFloat) {
            let label = UILabel()
            label.text = string
            label.font = Constants.Font.caption(size: .l)
            label.textColor = Constants.Color.LabelPrimary
            label.adjustsFontSizeToFitWidth = true
            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(x)
                make.top.equalToSuperview().offset(y)
                make.width.lessThanOrEqualTo(120*(Device.size().rawValue < Size.screen5_8Inch.rawValue ? 0.6 : 1))
            }
        }
        makeLabel(string: R.string.localizable.advanceFeatureDescLabel1(), x: 14, y: 51)
        makeLabel(string: R.string.localizable.advanceFeatureDescLabel2(), x: 174, y: 51)
        makeLabel(string: R.string.localizable.advanceFeatureDescLabel3(), x: 338, y: 51)
        makeLabel(string: R.string.localizable.advanceFeatureDescLabel4(), x: 93, y: 143)
        makeLabel(string: R.string.localizable.advanceFeatureDescLabel5(), x: 257, y: 143)
        return view
    }()
    
    private var serviceListView: UIImageView = {
        let view = UIImageView(image: R.image.service_list_bg())
        view.isHidden = true
        return view
    }()
    
    private var gradientMaskLayer = CAGradientLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientMaskLayer.frame = self.bounds
        if enableAnimation {
            startAnimation()
        } else {
            stopAnimation()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        gradientMaskLayer.colors = [UIColor.clear, UIColor.black, UIColor.black, UIColor.clear].map({ $0.cgColor })
        gradientMaskLayer.locations = [0, 0.25, 0.75, 1]
        gradientMaskLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientMaskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.mask = gradientMaskLayer
            
        let titleContainer = UIView()
        addSubview(titleContainer)
        titleContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(Constants.Size.IconSizeMin.height)
        }
        
        let titleLeftView = UIImageView(image: R.image.customLaurelLeading()?.applySymbolConfig(font: UIFont.systemFont(ofSize: 16, weight: .bold)))
        if Locale.isRTLLanguage {
            titleLeftView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        titleLeftView.contentMode = .center
        titleContainer.addSubview(titleLeftView)
        titleLeftView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        titleContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLeftView.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalToSuperview()
        }
        
        let titleRightView = UIImageView(image: R.image.customLaurelLeading()?.applySymbolConfig(font: UIFont.systemFont(ofSize: 16, weight: .bold)))
        titleRightView.semanticContentAttribute = .forceLeftToRight
        if !Locale.isRTLLanguage {
            titleRightView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        titleRightView.contentMode = .center
        titleContainer.addSubview(titleRightView)
        titleRightView.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
        }
        
        addSubview(questionButton)
        questionButton.snp.makeConstraints { make in
            make.leading.equalTo(titleContainer.snp.trailing)
            make.centerY.equalTo(titleContainer)
            make.size.equalTo(Constants.Size.IconSizeMid)
        }
        
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        iconImageView.addSubview(advanceDescriptionView)
        advanceDescriptionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(serviceListView)
        serviceListView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Constants.Size.ItemHeightUltraTiny)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(type: FeaturesType) {
        titleLabel.text = type.title
        iconImageView.image = type.image
        if type == .advance {
            advanceDescriptionView.isHidden = false
            enableAnimation = true
            if Device.size().rawValue < Size.screen5_8Inch.rawValue {
                iconImageView.snp.updateConstraints { make in
                    make.centerY.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
                }
            }
        } else {
            advanceDescriptionView.isHidden = true
            enableAnimation = false
            if Device.size().rawValue < Size.screen5_8Inch.rawValue {
                iconImageView.snp.updateConstraints { make in
                    make.centerY.equalToSuperview()
                }
            }
        }
        if type == .import {
            serviceListView.isHidden = false
        } else {
            serviceListView.isHidden = true
        }
        questionButton.addTapGesture { gesture in
            switch type {
            case .advance:
                UIView.makeAlert(title: R.string.localizable.purchaseAdcancedFeaturesTitle(),
                                 detail: R.string.localizable.adcancedFeaturesDetail(),
                                 detailAlignment: .left,
                                 cancelTitle: R.string.localizable.confirmTitle())
            case .import:
                UIView.makeAlert(title: R.string.localizable.purchaseImportFeaturesTitle(),
                                 detail: R.string.localizable.importFeaturesDetail(),
                                 detailAlignment: .left,
                                 cancelTitle: R.string.localizable.confirmTitle())
            case .controler:
                UIView.makeAlert(title: R.string.localizable.purchaseControllerFeaturesTitle(),
                                 detail: R.string.localizable.controllerFeaturesDetail(),
                                 detailAlignment: .left,
                                 cancelTitle: R.string.localizable.confirmTitle())
            case .airplay:
                UIView.makeAlert(title: R.string.localizable.purchaseAirPlayFeaturesTitle(),
                                 detail: R.string.localizable.airPlayFeaturesDetail(),
                                 detailAlignment: .left,
                                 cancelTitle: R.string.localizable.confirmTitle())
            case .iCloud:
                UIView.makeAlert(title: R.string.localizable.purchaseiCloudFeaturesTitle(),
                                 detail: R.string.localizable.iCloudFeaturesDetail(),
                                 detailAlignment: .left,
                                 cancelTitle: R.string.localizable.confirmTitle())
            }
        }
        if Device.size().rawValue < Size.screen5_8Inch.rawValue {
            serviceListView.isHidden = true
        }
    }
    
    private var enableAnimation = false
    private func startAnimation(toRight: Bool = true) {
        stopAnimation()
        var offset: CGFloat
        let animation = CABasicAnimation(keyPath: "position.x")
        if UIDevice.isPad {
            offset = (UIDevice.isLandscape ? Constants.Size.WindowHeight * 0.9 * 9 / 16 : Constants.Size.WindowWidth * 0.6)  - iconImageView.width
        } else {
            offset = Constants.Size.WindowWidth - iconImageView.width
        }
        
        let defaultDistance = Device.size().rawValue < Size.screen5_8Inch.rawValue ? 80.0 : 50.0
        let distance = offset < defaultDistance ? defaultDistance : offset
        let currentPosition = iconImageView.center.x - distance
        animation.fromValue = currentPosition
        animation.toValue = distance + currentPosition + distance
        animation.duration = 15
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.autoreverses = true
        animation.repeatCount = .infinity
        iconImageView.layer.add(animation, forKey: "positionAnimation")
    }

    // 复位方法
    private func stopAnimation() {
        iconImageView.snp.updateConstraints { make in
            make.centerX.equalToSuperview()
        }
        layoutIfNeeded()
        iconImageView.layer.removeAnimation(forKey: "positionAnimation")
    }
}
