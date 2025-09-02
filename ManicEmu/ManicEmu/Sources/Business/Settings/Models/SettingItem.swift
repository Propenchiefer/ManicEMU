//
//  SettingItem.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/28.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

struct SettingItem {
    
    enum ItemType: String {
        case theme, quickGame, airPlay, iCloud, fullScreenWhenConnectController, FAQ, feedback, shareApp, qq, telegram, discord, clearCache, language, userAgreement, privacyPolicy, autoSaveState, bios, respectSilentMode, onlinePlay, about, retro, rumble
    }
    
    var type: ItemType
    var isOn: Bool? = false
    var arrowDetail: String? = nil
    
    var backgroundColor: UIColor {
        switch type {
        case .theme:
            return Constants.Color.Magenta
        case .quickGame, .respectSilentMode, .privacyPolicy:
            return Constants.Color.Yellow
        case .autoSaveState, .onlinePlay, .feedback, .clearCache:
            return Constants.Color.Green
        case .airPlay, .FAQ, .about, .rumble:
            return Constants.Color.Indigo
        case .iCloud, .userAgreement:
            return Constants.Color.Blue
        case .fullScreenWhenConnectController, .shareApp:
            return Constants.Color.Orange
        case .bios, .language:
            return Constants.Color.Pink
        case .qq, .telegram, .discord, .retro:
            return .clear
        }
    }
    
    var icon: UIImage {
        switch type {
        case .theme:
            UIImage(symbol: .paintpaletteFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .quickGame:
            UIImage(symbol: .hareFill, font: Constants.Font.caption(size: .m, weight: .medium))
        case .airPlay:
            UIImage(symbol: .airplayvideo, font: Constants.Font.body(size: .s, weight: .medium))
        case .iCloud:
            if #available(iOS 17.0, *) {
                UIImage(symbol: .arrowTriangle2CirclepathIcloudFill, font: Constants.Font.body(size: .s, weight: .medium))
            } else {
                UIImage(symbol: .cloudFill, font: Constants.Font.body(size: .s, weight: .medium))
            }
        case .FAQ:
            UIImage(symbol: .questionmarkAppFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .feedback:
            UIImage(symbol: .exclamationmarkBubbleFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .shareApp:
            UIImage(symbol: .arrowshapeTurnUpForwardFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .qq:
            R.image.settings_qq()!
        case .telegram:
            R.image.settings_telegram()!
        case .discord:
            R.image.settings_discord()!
        case .clearCache:
            UIImage(symbol: .trashFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .language:
            UIImage(symbol: .globeAmericasFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .userAgreement:
            UIImage(symbol: .docTextFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .privacyPolicy:
            UIImage(symbol: .shieldLefthalfFilled, font: Constants.Font.body(size: .s, weight: .medium))
        case .fullScreenWhenConnectController:
            R.image.customArrowDownLeftAndArrowUpRightRectangleFill()!.applySymbolConfig(font: Constants.Font.body(size: .s, weight: .medium))
        case .autoSaveState:
            UIImage(symbol: .arrowDownDocFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .bios:
            UIImage(symbol: .cpuFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .respectSilentMode:
            UIImage(symbol: .bellFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .onlinePlay:
            UIImage(symbol: .person2Wave2Fill, font: Constants.Font.body(size: .s, weight: .medium))
        case .about:
            UIImage(symbol: .person3SequenceFill, font: Constants.Font.caption(size: .m, weight: .medium))
        case .retro:
            R.image.settings_retro()!
        case .rumble:
            UIImage(symbol: .iphoneRadiowavesLeftAndRightCircleFill, font: Constants.Font.body(size: .l, weight: .medium))
        }
    }
    
    var title: String {
        switch type {
        case .theme:
            R.string.localizable.themeSettingTitle()
        case .quickGame:
            R.string.localizable.quickGameTitle()
        case .airPlay:
            R.string.localizable.airPlayTitle()
        case .iCloud:
            R.string.localizable.iCloudTitle()
        case .FAQ:
            R.string.localizable.qaTitle()
        case .feedback:
            R.string.localizable.feedbackTitle()
        case .shareApp:
            R.string.localizable.shareAppTitle()
        case .qq:
            R.string.localizable.joinQQTitle()
        case .telegram:
            R.string.localizable.joinTelegramTitle()
        case .discord:
            R.string.localizable.joinDiscordTitle()
        case .clearCache:
            R.string.localizable.clearCacheTitle()
        case .language:
            R.string.localizable.languageTitle()
        case .userAgreement:
            R.string.localizable.userAgreementTitle()
        case .privacyPolicy:
            R.string.localizable.privacyPolicyTitle()
        case .fullScreenWhenConnectController:
            R.string.localizable.fullScreenWhenConnectControllerTitle()
        case .autoSaveState:
            R.string.localizable.autoSaveStateTitle()
        case .bios:
            "BIOS"
        case .respectSilentMode:
            R.string.localizable.respectSilentMode()
        case .onlinePlay:
            R.string.localizable.onlinePlaySetting()
        case .about:
            "About Us"
        case .retro:
            "RetroAchievements"
        case .rumble:
            "Rumble"
        }
    }
    
    var detail: String? {
        if type == .quickGame {
            return R.string.localizable.quickGameDetail()
        } else if type == .airPlay {
            return R.string.localizable.airPlayDetail()
        } else if type == .iCloud {
            return R.string.localizable.iCloudDetail()
        } else if type == .fullScreenWhenConnectController {
            return R.string.localizable.fullScreenWhenConnectControllerDetail()
        } else if type == .theme {
            return R.string.localizable.themeSettingDetail()
        } else if type == .bios {
            return R.string.localizable.biosDesc()
        } else if type == .respectSilentMode {
            return R.string.localizable.respectSilentModeDesc()
        } else if type == .rumble {
            return R.string.localizable.rumbleDetail()
        }
        return nil
    }
}
