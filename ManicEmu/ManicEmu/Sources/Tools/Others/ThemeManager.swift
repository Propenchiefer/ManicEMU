//
//  ThemeManager.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import RealmSwift

class ThemeManager {
    static let shared = ThemeManager()
    private var themeUpdateToken: Any? = nil
    
    func setup() {
        themeUpdateToken = Theme.defalut.observe(keyPaths: [\Theme.icon, \Theme.colors, \Theme.coverStyle, \Theme.coverRadiusRatio, \Theme.platformOrder, \Theme.forceSquare, \Theme.gamesPerRow, \Theme.hideIndicator, \Theme.hideGameTitle, \Theme.hideGroupTitle, \Theme.groupTitleStyle]) { [weak self] change in
            switch change {
            case .change(_, let properties):
                for property in properties {
                    if property.name == "icon" {
                        //切换图标
                        self?.updateIcon()
                    } else if property.name == "coverStyle" || property.name == "coverRadiusRatio" || property.name == "forceSquare" {
                        //更新封面样式
                        self?.updateCoverStyle()
                    } else if property.name == "colors" {
                        //更新主题颜色
                        self?.updateThemeColor()
                    } else if property.name == "platformOrder" {
                        //更新平台顺序
                        self?.updatePlatformOrder()
                    } else if property.name == "gamesPerRow" || property.name == "hideIndicator" || property.name == "hideGroupTitle" || property.name == "hideGameTitle" || property.name == "groupTitleStyle" {
                        //更新游戏列表样式
                        self?.updateGamelist()
                    }
                    Log.debug("主题更新 Property '\(property.name)' changed from \(property.oldValue == nil ? "nil" : property.oldValue!) to '\(property.newValue!)'")
                }
            default:
                break
            }
        }
        
        updateIcon()
        updateThemeColor()
        updateCoverStyle()
        updatePlatformOrder()
        updateGamelist()
    }
    
    private func updateIcon() {
        Log.debug("开始更新图标")
        let theme = Theme.defalut
        Log.debug("主题图标:\(theme.icon)")
        if let alternateIconName = UIApplication.shared.alternateIconName {
            Log.debug("已设置图标:\(alternateIconName)")
            if alternateIconName == theme.icon {
                Log.debug("无需更新图标")
                return
            }
        } else {
            Log.debug("当前未设置图标 说明使用的是默认图标")
            if theme.icon == "AppIcon" {
                Log.debug("无需更新图标")
                return
            }
        }
        
        if theme.icon == "AppIcon" {
            Log.debug("恢复默认图标")
            UIApplication.shared.setAlternateIconName(nil)
        } else {
            Log.debug("设置图标:\(theme.icon)")
            UIApplication.shared.setAlternateIconName(theme.icon)
        }
        
    }
    
    private func updateThemeColor() {
        let theme = Theme.defalut
        if let themeColor = theme.getThemeColors().first(where: { $0.isSelect }),
            let mainColorHex = themeColor.colors.first,
            let mainColor = UIColor(hexString: mainColorHex) {
            let gradientColors = themeColor.colors.compactMap({ UIColor(hexString: $0) })
            if Constants.Color.MainDynamicColor.hexString != mainColor.hexString {
                Constants.Color.MainDynamicColor = mainColor
                ApplicationSceneDelegate.applicationWindow?.overrideUserInterfaceStyle = .light
                DispatchQueue.main.asyncAfter(delay: 0.01) {
                    ApplicationSceneDelegate.applicationWindow?.overrideUserInterfaceStyle = .dark
                    NotificationCenter.default.post(name: Constants.NotificationName.MainColorChange, object: nil)
                }
            }
            
            if Constants.Color.Gradient != gradientColors {
                Constants.Color.Gradient = gradientColors
                NotificationCenter.default.post(name: Constants.NotificationName.GradientColorChange, object: nil)
            }
        }
    }
    
    private func updateCoverStyle() {
        let theme = Theme.defalut
        Constants.Size.GameCoverForceSquare = theme.forceSquare
        Constants.Size.GameCoverStyle = theme.coverStyle
        Constants.Size.GameCoverCornerRatio = CGFloat(theme.coverRadiusRatio)
        NotificationCenter.default.post(name: Constants.NotificationName.GameCoverChange, object: nil)
    }
    
    private func updatePlatformOrder() {
        let theme = Theme.defalut
        Constants.Config.PlatformOrder = theme.platformOrder.map({ $0 })
        NotificationCenter.default.post(name: Constants.NotificationName.PlatformOrderChange, object: nil)
    }
    
    private func updateGamelist() {
        let theme = Theme.defalut
        if theme.gamesPerRow > 0 && theme.gamesPerRow <= 5 {
            Constants.Size.GamesPerRow = Double(theme.gamesPerRow)
            Constants.Size.GamesHideScrollIndicator = theme.hideIndicator
            Constants.Size.GamesHideTitle = theme.hideGameTitle
            Constants.Size.GamesHideGroupTitle = theme.hideGroupTitle
            Constants.Size.GamesGroupTitleStyle = theme.groupTitleStyle
            NotificationCenter.default.post(name: Constants.NotificationName.GameListStyleChange, object: nil)
        }
    }
}
