//
//  SettingsViewController.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/29.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class SettingsViewController: BaseViewController {
    
    private lazy var cornerMaskViewForiPad: TransparentHoleView = {
        let view = TransparentHoleView()
        return view
    }()
    
    private lazy var detailMaskViewForiPad: TransparentHoleView = {
        let view = TransparentHoleView()
        return view
    }()

    private var settingsListView: SettingsListView = {
        let view = SettingsListView()
        return view
    }()
    
    private lazy var detailContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.isPhone {
            view.addSubview(settingsListView)
            settingsListView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            view.addSubview(settingsListView)
            view.backgroundColor = .black
            settingsListView.backgroundColor = Constants.Color.Background
            settingsListView.didTapDetail = { [weak self] vc in
                guard let self = self else { return }
                self.detailContentView.subviews.forEach { $0.removeFromSuperview() }
                self.detailContentView.addSubview(vc.view)
                vc.view.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
            settingsListView.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalTo(Constants.Size.SideMenuWidth*1.15)
            }
            
            view.addSubview(cornerMaskViewForiPad)
            cornerMaskViewForiPad.snp.makeConstraints { make in
                make.edges.equalTo(settingsListView)
            }
            
            view.addSubview(detailContentView)
            detailContentView.snp.makeConstraints { make in
                make.top.trailing.bottom.equalToSuperview()
                make.leading.equalTo(settingsListView.snp.trailing).offset(Constants.Size.ContentSpaceMid)
            }
            
            view.addSubview(detailMaskViewForiPad)
            detailMaskViewForiPad.snp.makeConstraints { make in
                make.edges.equalTo(detailContentView)
            }
            
            let vc = ThemeViewController()
            detailContentView.addSubview(vc.view)
            vc.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
