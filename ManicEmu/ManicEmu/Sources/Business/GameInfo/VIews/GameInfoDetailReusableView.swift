//
//  GameInfoDetailReusableView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/14.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import BetterSegmentedControl
import RealmSwift
import UniformTypeIdentifiers

class GameInfoDetailReusableView: UICollectionReusableView {
    let backgroundBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        view.alpha = 0
        return view
    }()
    
    lazy var titleTextField: UITextField = {
        let textField = UITextField()
        textField.textColor = Constants.Color.LabelPrimary
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.clearButtonMode = .never
        textField.returnKeyType = .done
        textField.onReturnKeyPress { [weak self, weak textField] in
            guard let self = self else { return }
            textField?.resignFirstResponder()
            if let game = self.game, let text = textField?.text?.trimmed {
                if text.isEmpty {
                    textField?.text = game.aliasName ?? game.name
                    UIView.makeToast(message: R.string.localizable.readyEditTitleFailed())
                } else if text != game.aliasName {
                    Game.change { realm in
                        game.aliasName = text
                    }
                }
            }
        }
        textField.onChange { [weak textField] text in
            if text.count > Constants.Size.GameNameMaxCount {
                if let markRange = textField?.markedTextRange, let _ = textField?.position(from: markRange.start, offset: 0) { } else {
                    textField?.text = String(text.prefix(Constants.Size.GameNameMaxCount))
                }
            }
        }
        return textField
    }()
    
    private lazy var editTitleButton: SymbolButton = {
        let view = SymbolButton(image: R.image.customPencilLine()?.applySymbolConfig(size: Constants.Size.IconSizeMin.height))
        view.backgroundColor = .clear
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if !self.titleTextField.isFirstResponder {
                self.titleTextField.becomeFirstResponder()
            }
        }
        return view
    }()
    
    private let subtitleIcon: UIImageView = {
        let view = UIImageView()
        view.image = .symbolImage(.starCircleFill).applySymbolConfig(color: Constants.Color.LabelSecondary)
        return view
    }()
    
    private let subtitleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.body()
        return view
    }()
    
    private let functionButtonContainerView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceHorizontal = true
        if Locale.isRTLLanguage {
            view.semanticContentAttribute = .forceLeftToRight
        }
        return view
    }()
    
    private lazy var retroButton: SymbolButton = {
        let view = SymbolButton(image: R.image.customTrophy()?.applySymbolConfig(), title: R.string.localizable.retroAchievements2())
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self, let game else { return }
            if !game.supportRetroAchievements {
                UIView.makeToast(message: R.string.localizable.achievementsNotSupport(game.gameType.localizedShortName))
                return
            }
            if let _ = AchievementsUser.getUser() {
                topViewController()?.present(RetroAchievementsListViewController(game: game), animated: true)
            } else {
                //先进行登录
                let vc = RetroAchievementsViewController()
                vc.dismissAfterLoginSuccess = { [weak self] in
                    topViewController()?.present(RetroAchievementsListViewController(game: game), animated: true)
                }
                topViewController()?.present(vc, animated: true)
            }
        }
        return view
    }()

    private lazy var skinButton: SymbolButton = {
        let view = SymbolButton(symbol: .tshirt, title: R.string.localizable.gamesSpecifySkin())
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if let game = self.game {
                topViewController()?.present(SkinSettingsViewController(game: game), animated: true)
            }
        }
        return view
    }()
    
    private lazy var cheatCodeButton: SymbolButton = {
        let view = SymbolButton(image: R.image.customAppleTerminal()?.applySymbolConfig(), title: R.string.localizable.gamesCheatCode())
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if let game = self.game {
                topViewController()?.present(CheatCodeViewController(game: game), animated: true)
            }
        }
        return view
    }()
    
    private lazy var threeDSAdvancedModeButton: SymbolButton = {
        let title = Settings.defalut.threeDSAdvancedSettingMode ? R.string.localizable.threeDSBasicSettingMode() : R.string.localizable.threeDSAdvanceSettingMode()
        let view = SymbolButton(symbol: .sliderHorizontal3, title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            Settings.change { realm in
                Settings.defalut.threeDSAdvancedSettingMode.toggle()
            }
            self.threeDSAdvancedModeButton.titleLabel.text = Settings.defalut.threeDSAdvancedSettingMode ? R.string.localizable.threeDSBasicSettingMode() : R.string.localizable.threeDSAdvanceSettingMode()
            self.update3DSFunctionButton()
        }
        return view
    }()
    
    private lazy var threeDSModecontextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.threeDSModePerformance()) { [weak self] _ in
            guard let self = self else { return }
            self.threeDSModeButton.titleLabel.text = R.string.localizable.threeDSModePerformance()
            Settings.change { realm in
                Settings.defalut.threeDSMode = .performance
            }
        }))
        actions.append(UIAction(title: R.string.localizable.threeDSModeCompatibility()) { [weak self] _ in
            guard let self = self else { return }
            self.threeDSModeButton.titleLabel.text = R.string.localizable.threeDSModeCompatibility()
            Settings.change { realm in
                Settings.defalut.threeDSMode = .compatibility
            }
        })
        actions.append((UIAction(title: R.string.localizable.threeDSModeQuality()) { [weak self] _ in
            guard let self = self else { return }
            self.threeDSModeButton.titleLabel.text = R.string.localizable.threeDSModeQuality()
            Settings.change { realm in
                Settings.defalut.threeDSMode = .quality
            }
        }))
        let view = ContextMenuButton(image: nil, menu: UIMenu(children: actions))
        return view
    }()
    
    private lazy var threeDSModeButton: SymbolButton = {
        let title: String
        switch Settings.defalut.threeDSMode {
        case .performance:
            title = R.string.localizable.threeDSModePerformance()
        case .compatibility:
            title = R.string.localizable.threeDSModeCompatibility()
        case .quality:
            title = R.string.localizable.threeDSModeQuality()
        }
        let view = SymbolButton(symbol: .gearshape2, title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.threeDSModecontextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var jitContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.on()) { [weak self] _ in
            guard let self = self else { return }
            self.jitButton.titleLabel.text = "JIT \(R.string.localizable.on())"
            if let game {
                Game.change { _ in
                    game.jit = true
                }
            }
        }))
        actions.append(UIAction(title: R.string.localizable.off()) { [weak self] _ in
            guard let self = self else { return }
            self.jitButton.titleLabel.text = "JIT \(R.string.localizable.off())"
            if let game {
                Game.change { _ in
                    game.jit = false
                }
            }
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.jitMenuDesc(), children: actions))
        return view
    }()
    
    private lazy var jitButton: SymbolButton = {
        let title: String
        let jitAvailable = LibretroCore.jitAvailable()
        if jitAvailable {
            if game?.jit ?? false {
                title = "JIT \(R.string.localizable.on())"
            } else {
                title = "JIT \(R.string.localizable.off())"
            }
        } else {
            title = "JIT \(R.string.localizable.off())"
        }
        
        let view = SymbolButton(symbol: .bolt, title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if jitAvailable {
                self.jitContextMenuButton.triggerTapGesture()
            } else {
                UIView.makeToast(message: R.string.localizable.jitNoSupportDesc())
            }
        }
        return view
    }()
    
    private lazy var shaderContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.on()) { [weak self] _ in
            guard let self = self else { return }
            self.shaderButton.titleLabel.text = "\(R.string.localizable.shaderModeTitle())\n\(R.string.localizable.on())"
            if let game {
                Game.change { _ in
                    game.accurateShaders = true
                }
            }
        }))
        actions.append(UIAction(title: R.string.localizable.off()) { [weak self] _ in
            guard let self = self else { return }
            self.shaderButton.titleLabel.text = "\(R.string.localizable.shaderModeTitle())\n\(R.string.localizable.off())"
            if let game {
                Game.change { _ in
                    game.accurateShaders = false
                }
            }
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.shaderModeDesc(), children: actions))
        return view
    }()
    
    private lazy var shaderButton: SymbolButton = {
        let title: String
        if game?.accurateShaders ?? false {
            title = "\(R.string.localizable.shaderModeTitle())\n\(R.string.localizable.on())"
        } else {
            title = "\(R.string.localizable.shaderModeTitle())\n\(R.string.localizable.off())"
        }
        let view = SymbolButton(image: R.image.customLightspectrumHorizontal()?.applySymbolConfig(color: Constants.Color.LabelPrimary), title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.shaderContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var languageContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        var languages = [String]()
        if let game {
            if game.gameType == ._3ds {
                languages = Constants.Strings.ThreeDSConsoleLanguage
            } else if game.gameType == .psp {
                languages = Constants.Strings.PSPConsoleLanguage
            } else if game.gameType == .ss {
                languages = Constants.Strings.SaturnConsoleLanguage
            } else if game.gameType == .ds {
                languages = Constants.Strings.DSConsoleLanguage
            } else if game.gameType == .dc {
                languages = Constants.Strings.DCConsoleLanguage
            }
        }
        for (index, language) in languages.enumerated() {
            actions.append((UIAction(title: language) { [weak self] _ in
                guard let self = self else { return }
                self.languageButton.titleLabel.text = language
                if let game {
                    Game.change { _ in
                        game.region = index
                    }
                }
            }))
        }
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.consoleLanguageDesc(), children: actions))
        return view
    }()
    
    private lazy var languageButton: SymbolButton = {
        var title: String = ""
        if let game {
            var languages = [String]()
            if game.gameType == ._3ds {
                languages = Constants.Strings.ThreeDSConsoleLanguage
            } else if game.gameType == .psp {
                languages = Constants.Strings.PSPConsoleLanguage
            } else if game.gameType == .ss {
                languages = Constants.Strings.SaturnConsoleLanguage
            } else if game.gameType == .ds {
                languages = Constants.Strings.DSConsoleLanguage
            } else if game.gameType == .dc {
                languages = Constants.Strings.DCConsoleLanguage
            }
            if game.region < languages.count {
                title = languages[game.region]
            }
        }
        let view = SymbolButton(symbol: .characterBubble, title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.languageContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var rightEyeRenderMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.disableTitle()) { [weak self] _ in
            guard let self = self else { return }
            self.rightEyeRenderButton.titleLabel.text = R.string.localizable.disableTitle() + R.string.localizable.renderRightEyeTitle()
            self.rightEyeRenderButton.imageView.image = .symbolImage(.eyeSlash)
            if let game {
                Game.change { _ in
                    game.renderRightEye = false
                }
            }
        }))
        actions.append(UIAction(title: R.string.localizable.enableTitle()) { [weak self] _ in
            guard let self = self else { return }
            self.rightEyeRenderButton.titleLabel.text = R.string.localizable.enableTitle() + R.string.localizable.renderRightEyeTitle()
            self.rightEyeRenderButton.imageView.image = .symbolImage(.eye)
            if let game {
                Game.change { _ in
                    game.renderRightEye = true
                }
            }
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.renderRightEyeDesc(), children: actions))
        return view
    }()
    
    private lazy var rightEyeRenderButton: SymbolButton = {
        var title: String = R.string.localizable.renderRightEyeTitle()
        let enableRightEyeRender = game?.renderRightEye ?? false
        if enableRightEyeRender {
            title = R.string.localizable.enableTitle() + title
        } else {
            title = R.string.localizable.disableTitle() + title
        }
        let view = SymbolButton(symbol: enableRightEyeRender ? .eye : .eyeSlash, title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.rightEyeRenderMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var threeDSAdvancedSettingButton: SymbolButton = {
        let view = SymbolButton(symbol: .gear, title: R.string.localizable.threeDSAdvanceSettingTitle(), horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { gesture in
            topViewController()?.present(ThreeDSAdvancedSettingViewController(), animated: true)
        }
        return view
    }()
    
    private lazy var transferPakContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append(UIAction(title: R.string.localizable.transferPakFromLibrary()) { [weak self] _ in
            guard let self = self else { return }
            //从游戏库导入
            let realm = Database.realm
            let objects = realm.objects(Game.self).where({ !$0.isDeleted && ($0.gameType == .gbc || $0.gameType == .gb) }).filter({ $0.isSaveExtsts })
            var games = [Game]()
            games.append(contentsOf: objects)
            if games.count > 0 {
                GameSaveMatchGameView.show(showGames: games, title: "Transfer Pak", detail: R.string.localizable.transferPakFromLibraryDesc(), cancelTitle: R.string.localizable.cancelTitle()) { [weak self] selectedGame in
                    guard let self = self else { return }
                    if let game = self.game, let selectedGame, selectedGame.isRomExtsts, selectedGame.isSaveExtsts {
                        try? FileManager.safeCopyItem(at: selectedGame.romUrl, to: URL(fileURLWithPath: game.romUrl.path + ".gb"), shouldReplace: true)
                        try? FileManager.safeCopyItem(at: selectedGame.gameSaveUrl, to: URL(fileURLWithPath: game.romUrl.path + ".sav"), shouldReplace: true)
                        self.transferPakButton.titleLabel.text = "Transfer Pak\n\(R.string.localizable.transferPakOn())"
                        UIView.makeToast(message: R.string.localizable.alertImportFilesSuccess())
                    }
                }
            } else {
                UIView.makeToast(message: R.string.localizable.transferPakNoGames())
            }
        })
        actions.append(UIAction(title: R.string.localizable.transferPakFromFiles()) { [weak self] _ in
            guard let self = self else { return }
            //从文件导入
            if let gb = UTType(filenameExtension: "gb"), let gbc = UTType(filenameExtension: "gbc"), let sav = UTType(filenameExtension: "sav") {
                FilesImporter.shared.presentImportController(supportedTypes: [gb, gbc, sav]) { [weak self] urls in
                    guard let self = self else { return }
                    guard urls.count == 2 else {
                        UIView.makeToast(message: R.string.localizable.transferPakImportError())
                        return
                    }
                    
                    var romPath = ""
                    var savePath = ""
                    let firstPath = urls.first!.path
                    let firstPathExtension = firstPath.pathExtension.lowercased()
                    if firstPathExtension == "gb" || firstPathExtension == "gbc" {
                        romPath = firstPath
                    } else if firstPathExtension == "sav" {
                        savePath = firstPath
                    } else {
                        UIView.makeToast(message: R.string.localizable.transferPakImportError())
                        return
                    }
                    
                    let lastPath = urls.last!.path
                    let lastPathExtension = lastPath.pathExtension.lowercased()
                    if romPath.isEmpty {
                        if lastPathExtension == "gb" || lastPathExtension == "gbc" {
                            romPath = lastPath
                        } else {
                            UIView.makeToast(message: R.string.localizable.transferPakImportError())
                            return
                        }
                    } else {
                        if lastPathExtension == "sav" {
                            savePath = lastPath
                        } else {
                            UIView.makeToast(message: R.string.localizable.transferPakImportError())
                            return
                        }
                    }
                    
                    if let game = self.game {
                        try? FileManager.safeCopyItem(at: URL(fileURLWithPath: romPath), to: URL(fileURLWithPath: game.romUrl.path + ".gb"), shouldReplace: true)
                        try? FileManager.safeCopyItem(at: URL(fileURLWithPath: savePath), to: URL(fileURLWithPath: game.romUrl.path + ".sav"), shouldReplace: true)
                        self.transferPakButton.titleLabel.text = "Transfer Pak\n\(R.string.localizable.transferPakOn())"
                        UIView.makeToast(message: R.string.localizable.alertImportFilesSuccess())
                    }
                    
                }
            }
        })
        actions.append(UIAction(title: R.string.localizable.off()) { [weak self] _ in
            guard let self = self else { return }
            //关闭Transfer Pak
            if let game = self.game {
                try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: game.romUrl.path + ".gb"))
                try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: game.romUrl.path + ".sav"))
                self.transferPakButton.titleLabel.text = "Transfer Pak\n\(R.string.localizable.transferPakOff())"
            }
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.transferPakDesc(), children: actions))
        return view
    }()
    
    private lazy var transferPakButton: SymbolButton = {
        var state = "\n" + R.string.localizable.transferPakOff()
        if let game = self.game, game.hasTransferPak {
            state = "\n" + R.string.localizable.transferPakOn()
        }
        let view = SymbolButton(symbol: .arrowshapeZigzagForward, title: "Transfer Pak\(state)", horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.transferPakContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var rdpPluginContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append(UIAction(title: "GLideN64") { [weak self] _ in
            guard let self = self else { return }
            self.rdpPluginButton.titleLabel.text = "RDP Plugin\nGLideN64"
            if let game = self.game {
                Game.change { realm in
                    game.resolution = .one
                }
                game.updateExtra(key: ExtraKey.rdpPlugin.rawValue, value: true)
            }
        })
        actions.append(UIAction(title: "ParaLLEl-RDP") { [weak self] _ in
            guard let self = self else { return }
            self.rdpPluginButton.titleLabel.text = "RDP Plugin\nParaLLEl-RDP"
            if let game = self.game {
                Game.change { realm in
                    game.resolution = .one
                }
                game.updateExtra(key: ExtraKey.rdpPlugin.rawValue, value: false)
            }
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.n64RDPDesc(), children: actions))
        return view
    }()
    
    private lazy var rdpPluginButton: SymbolButton = {
        let title = "RDP Plugin\n" + ((self.game?.isN64ParaLLEl ?? false) ? "ParaLLEl-RDP" : "GLideN64")
        let view = SymbolButton(image: R.image.customLightspectrumHorizontal()?.applySymbolConfig(color: Constants.Color.LabelPrimary), title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.rdpPluginContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var ndsSystemTypeContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append(UIAction(title: "DS") { [weak self] _ in
            guard let self = self else { return }
            self.ndsSystemTypeButton.titleLabel.text = R.string.localizable.ndsSystemTypeTitle() + "\nDS"
            self.game?.updateExtra(key: ExtraKey.ndsSystemMode.rawValue, value: "DS")
            self.updateDSFunctionButton()
        })
        actions.append(UIAction(title: "DSi") { [weak self] _ in
            guard let self = self else { return }
            self.ndsSystemTypeButton.titleLabel.text = R.string.localizable.ndsSystemTypeTitle() + "\nDSi"
            self.game?.updateExtra(key: ExtraKey.ndsSystemMode.rawValue, value: "DSi")
            self.updateDSFunctionButton()
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.ndsSystemTypeDesc(), children: actions))
        return view
    }()
    
    private lazy var ndsSystemTypeButton: SymbolButton = {
        var type = "\n" + (self.game?.getExtraString(key: ExtraKey.ndsSystemMode.rawValue) ?? "DS")
        let view = SymbolButton(symbol: .squareSplit1x2, title: R.string.localizable.ndsSystemTypeTitle() + type, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.ndsSystemTypeContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var gbaSlotContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append(UIAction(title: R.string.localizable.transferPakFromLibrary()) { [weak self] _ in
            guard let self = self else { return }
            //从游戏库导入
            let realm = Database.realm
            let objects = realm.objects(Game.self).where({ !$0.isDeleted && $0.gameType == .gba })
            var games = [Game]()
            games.append(contentsOf: objects)
            if games.count > 0 {
                GameSaveMatchGameView.show(showGames: games, title: "GBA Slot", detail: R.string.localizable.transferPakFromLibraryDesc(), cancelTitle: R.string.localizable.cancelTitle()) { [weak self] selectedGame in
                    guard let self = self else { return }
                    if let game = self.game, let selectedGame, selectedGame.isRomExtsts {
                        try? FileManager.safeCopyItem(at: selectedGame.romUrl, to: URL(fileURLWithPath: game.romUrl.path + ".slot.gba"), shouldReplace: true)
                        try? FileManager.safeCopyItem(at: selectedGame.gameSaveUrl, to: URL(fileURLWithPath: game.romUrl.path + ".slot.sav"), shouldReplace: true)
                        self.gbaSlotButton.titleLabel.text = "GBA Slot\n\(R.string.localizable.gbaSlotInsert())"
                        self.gbaSlotButton.imageView.image = .symbolImage(.externaldriveBadgeCheckmark)
                        UIView.makeToast(message: R.string.localizable.alertImportFilesSuccess())
                    }
                }
            } else {
                UIView.makeToast(message: R.string.localizable.transferPakNoGames())
            }
        })
        actions.append(UIAction(title: R.string.localizable.transferPakFromFiles()) { [weak self] _ in
            guard let self = self else { return }
            //从文件导入
            if let gba = UTType(filenameExtension: "gba"), let sav = UTType(filenameExtension: "sav") {
                FilesImporter.shared.presentImportController(supportedTypes: [gba, sav]) { [weak self] urls in
                    guard let self = self else { return }
                    guard urls.count == 1 || urls.count == 2 else {
                        UIView.makeToast(message: R.string.localizable.gbaSlotImportError())
                        return
                    }
                    
                    var romPath = ""
                    var savePath = ""
                    let firstPath = urls.first!.path
                    let firstPathExtension = firstPath.pathExtension.lowercased()
                    if firstPathExtension == "gba" {
                        romPath = firstPath
                    } else if firstPathExtension == "sav" {
                        savePath = firstPath
                    } else {
                        UIView.makeToast(message: R.string.localizable.gbaSlotImportError())
                        return
                    }
                    
                    if urls.count == 1, romPath.isEmpty {
                        UIView.makeToast(message: R.string.localizable.gbaSlotImportError())
                        return
                    }
                    
                    if urls.count == 2 {
                        let lastPath = urls.last!.path
                        let lastPathExtension = lastPath.pathExtension.lowercased()
                        if romPath.isEmpty {
                            if lastPathExtension == "gba" {
                                romPath = lastPath
                            } else {
                                UIView.makeToast(message: R.string.localizable.gbaSlotImportError())
                                return
                            }
                        } else {
                            if lastPathExtension == "sav" {
                                savePath = lastPath
                            } else {
                                UIView.makeToast(message: R.string.localizable.gbaSlotImportError())
                                return
                            }
                        }
                    }
                    
                    if let game = self.game {
                        try? FileManager.safeCopyItem(at: URL(fileURLWithPath: romPath), to: URL(fileURLWithPath: game.romUrl.path + ".slot.gba"), shouldReplace: true)
                        if !savePath.isEmpty {
                            try? FileManager.safeCopyItem(at: URL(fileURLWithPath: savePath), to: URL(fileURLWithPath: game.romUrl.path + ".slot.sav"), shouldReplace: true)
                        }
                        self.gbaSlotButton.titleLabel.text = "GBA Slot\n\(R.string.localizable.gbaSlotInsert())"
                        self.gbaSlotButton.imageView.image = .symbolImage(.externaldriveBadgeCheckmark)
                        UIView.makeToast(message: R.string.localizable.alertImportFilesSuccess())
                    }
                    
                }
            }
        })
        actions.append(UIAction(title: R.string.localizable.off()) { [weak self] _ in
            guard let self = self else { return }
            //关闭Transfer Pak
            if let game = self.game {
                try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: game.romUrl.path + ".slot.gba"))
                try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: game.romUrl.path + ".slot.sav"))
                self.gbaSlotButton.titleLabel.text = "GBA Slot\n\(R.string.localizable.gbaSlotUnInsert())"
                self.gbaSlotButton.imageView.image = .symbolImage(.externaldriveBadgeXmark)
            }
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.gbaSlotDesc(), children: actions))
        return view
    }()
    
    private lazy var gbaSlotButton: SymbolButton = {
        var state = "\n" + R.string.localizable.gbaSlotUnInsert()
        var symbol = SFSymbol.externaldriveBadgeXmark
        if let game = self.game, game.hasGBASlotInsert {
            state = "\n" + R.string.localizable.gbaSlotInsert()
            symbol = SFSymbol.externaldriveBadgeCheckmark
        }
        let view = SymbolButton(symbol: symbol, title: "GBA Slot\(state)", horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if let game = self.game {
                if game.gameType.isNDSBiosComplete().isDSComplete {
                    self.gbaSlotContextMenuButton.triggerTapGesture()
                } else {
                    topViewController(appController: true)?.present(BIOSSelectionViewController(gameType: game.gameType), animated: true)
                }
            }
        }
        return view
    }()
    
    private lazy var psxModeContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append(UIAction(title: Constants.Strings.PSXController) { [weak self] _ in
            guard let self = self else { return }
            self.psxModeButton.titleLabel.text = Constants.Strings.PSXController
            self.game?.updateExtra(key: ExtraKey.isAnalog.rawValue, value: false)
        })
        actions.append(UIAction(title: Constants.Strings.PSXDualShock) { [weak self] _ in
            guard let self = self else { return }
            self.psxModeButton.titleLabel.text = Constants.Strings.PSXDualShock
            self.game?.updateExtra(key: ExtraKey.isAnalog.rawValue, value: true)
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.analogModeDesc(), children: actions))
        return view
    }()
    
    private lazy var psxModeButton: SymbolButton = {
        let title = (self.game?.getExtraBool(key: ExtraKey.isAnalog.rawValue) ?? true) ? Constants.Strings.PSXDualShock : Constants.Strings.PSXController
        let view = SymbolButton(symbol: .gamecontroller, title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.psxModeContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var psxImportSbiButton: SymbolButton = {
        let view = SymbolButton(symbol: .lockRectangleStack, title: R.string.localizable.sbiImport(), horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            if let game = self.game {
                topViewController()?.present(PSXSBIImportViewController(game: game), animated: true)
            }
        }
        return view
    }()
    
    private lazy var psxRendererContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append(UIAction(title: "Hardware") { [weak self] _ in
            guard let self = self else { return }
            self.psxRendererButton.titleLabel.text = "\(R.string.localizable.rendererTitle())\nHardware"
            self.game?.updateExtra(key: ExtraKey.psxRenderer.rawValue, value: true)
        })
        actions.append(UIAction(title: "Software") { [weak self] _ in
            guard let self = self else { return }
            self.psxRendererButton.titleLabel.text = "\(R.string.localizable.rendererTitle())\nSoftware"
            self.game?.updateExtra(key: ExtraKey.psxRenderer.rawValue, value: false)
        })
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.rendererDesc(), children: actions))
        return view
    }()
    
    private lazy var psxRendererButton: SymbolButton = {
        let title = "\(R.string.localizable.rendererTitle())\n" + ((self.game?.getExtraBool(key: ExtraKey.psxRenderer.rawValue) ?? true) ? "Hardware" : "Software")
        let view = SymbolButton(image: R.image.customLightspectrumHorizontal()?.applySymbolConfig(color: Constants.Color.LabelPrimary), title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.psxRendererContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var startGameButton: SymbolButton = {
        let view = SymbolButton(symbol: .playFill)
        view.backgroundColor = Constants.Color.Main
        view.layerCornerRadius = Constants.Size.ItemHeightMid/2
        view.addTapGesture { [weak self] gesture in
            guard let self = self, let game = self.game else { return }
            PlayViewController.startGame(game: game)
        }
        return view
    }()
    
    private lazy var dcCoreContextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: "JITLess Ver: Defalut") { [weak self] _ in
            guard let self = self else { return }
            self.dcCoreButton.titleLabel.text = "JITLess Ver: Defalut"
            if let game {
                Game.change { _ in
                    game.defaultCore = 0
                }
            }
        }))
        actions.append((UIAction(title: "JITLess Ver: WinCE") { [weak self] _ in
            guard let self = self else { return }
            self.dcCoreButton.titleLabel.text = "JITLess Ver: WinCE"
            if let game {
                Game.change { _ in
                    game.defaultCore = 1
                }
            }
        }))
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.dcjitLessVer(), children: actions))
        return view
    }()
    
    private lazy var dcCoreButton: SymbolButton = {
        let ver = (game?.defaultCore ?? 0) == 0 ? "Defalut" : "WinCE"
        let view = SymbolButton(symbol: .boltSlash, title: "JITLess Ver: \(ver)", horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.dcCoreContextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var tvStandardMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: "NTSC (59.94HZ)") { [weak self] _ in
            guard let self = self else { return }
            self.tVStandardButton.titleLabel.text = "NTSC (59.94HZ)"
            if let game {
                game.updateExtra(key: ExtraKey.tvStandard.rawValue, value: 0)
            }
        }))
        actions.append((UIAction(title: "PAL (50HZ)") { [weak self] _ in
            guard let self = self else { return }
            self.tVStandardButton.titleLabel.text = "PAL (50HZ)"
            if let game {
                game.updateExtra(key: ExtraKey.tvStandard.rawValue, value: 1)
            }
        }))
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.tvStandard(), children: actions))
        return view
    }()
    
    private lazy var tVStandardButton: SymbolButton = {
        let standard = (game?.getExtraInt(key: ExtraKey.tvStandard.rawValue) ?? 0) == 0 ? "NTSC (59.94HZ)" : "PAL (50HZ)"
        let view = SymbolButton(symbol: .tv, title: standard, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.tvStandardMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var snesVRAMMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.enableTitle()) { [weak self] _ in
            guard let self = self else { return }
            self.snesVRAMButton.titleLabel.text = "VRAM: " + R.string.localizable.enableTitle()
            if let game {
                game.updateExtra(key: ExtraKey.snesVRAM.rawValue, value: true)
            }
        }))
        actions.append((UIAction(title: R.string.localizable.disableTitle()) { [weak self] _ in
            guard let self = self else { return }
            self.snesVRAMButton.titleLabel.text = "VRAM: " + R.string.localizable.disableTitle()
            if let game {
                game.updateExtra(key: ExtraKey.snesVRAM.rawValue, value: false)
            }
        }))
        let view = ContextMenuButton(image: nil, menu: UIMenu(title: R.string.localizable.snesvramEnable(), children: actions))
        return view
    }()
    
    private lazy var snesVRAMButton: SymbolButton = {
        let title = "VRAM: " + ((game?.getExtraBool(key: ExtraKey.snesVRAM.rawValue) ?? false) ? R.string.localizable.enableTitle() : R.string.localizable.disableTitle())
        let view = SymbolButton(symbol: .memorychip, title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.snesVRAMMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    var didSegmentChange: ((_ index: Int)->Void)?
    lazy var segmentView: BetterSegmentedControl = {
        let titles = [R.string.localizable.readySegmentManualSave(), R.string.localizable.readySegmentAutoSave()]
        let segments = LabelSegment.segments(withTitles: titles,
                                             normalFont: Constants.Font.body(),
                                             normalTextColor: Constants.Color.LabelSecondary,
                                            selectedTextColor: Constants.Color.LabelPrimary)
        let options: [BetterSegmentedControl.Option] = [
            .backgroundColor(Constants.Color.BackgroundSecondary),
            .indicatorViewInset(5),
            .indicatorViewBackgroundColor(Constants.Color.BackgroundTertiary),
            .cornerRadius(16)
        ]
        let view = BetterSegmentedControl(frame: .zero,
                                          segments: segments,
                                          options: options)
        
        view.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self = self, let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            self.didSegmentChange?(index)
        }
        
        return view
    }()
    
    private class GameInfoSymbolButton: SymbolButton {}
    var didDeleteSaveState: (()->Void)?
    private lazy var deleteSaveStateButton: GameInfoSymbolButton = {
        let view = GameInfoSymbolButton(image: .symbolImage(.trash).applySymbolConfig(color: Constants.Color.Red))
        view.layerCornerRadius = Constants.Size.CornerRadiusMid
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.didDeleteSaveState?()
        }
        return view
    }()
    
    
    
    var game: Game? = nil {
        didSet {
            if let game = game {
                titleTextField.text = game.aliasName ?? game.name
                if let timeAgo = game.latestPlayDate?.timeAgo() {
                    subtitleLabel.text = R.string.localizable.readyGameInfoSubTitle(timeAgo, Date.timeDuration(milliseconds: Int(game.totalPlayDuration)))
                } else {
                    subtitleLabel.text = R.string.localizable.readyGameInfoNeverPlayed()
                }
                if game.gameType == ._3ds {
                    update3DSFunctionButton()
                } else if game.gameType == .psp {
                    updatePSPFunctionButton()
                } else if game.gameType == .ss {
                    updateSaturnFunctionButton()
                } else if game.gameType == .ds {
                    updateDSFunctionButton()
                } else if game.gameType == .n64 {
                    updateN64FunctionButton()
                } else if game.gameType == .vb || game.gameType == .pm {
                    updateVBOrPMFunctionButton()
                } else if game.gameType == .ps1 {
                    updatePS1FunctionButton()
                } else if game.gameType == .dc {
                    updateDCFunctionButton()
                } else if game.gameType == .md {
                    updateMDFunctionButton()
                } else if game.gameType == .snes {
                    updateSNESFunctionButton()
                }
            }
        }
    }
    
    func resetForGamingUsing() {
        subviews.forEach {
            if $0 is BetterSegmentedControl {
                $0.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(10)
                    make.height.equalTo(50)
                    make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                    make.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                }
            } else if $0 is GameInfoSymbolButton {
                $0.snp.remakeConstraints { make in
                    make.centerY.equalTo(segmentView)
                    make.size.equalTo(Constants.Size.ItemHeightMid)
                    make.leading.equalTo(segmentView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                }
            } else {
                $0.isHidden = true
            }
        }
        backgroundBlurView.isHidden = false
        backgroundBlurView.alpha = 1
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backgroundBlurView)
        backgroundBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(titleTextField)
        titleTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
            make.top.equalToSuperview()
        }
        
        addSubview(editTitleButton)
        editTitleButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.top.equalTo(titleTextField)
            make.leading.equalTo(titleTextField.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        
        addSubview(subtitleIcon)
        subtitleIcon.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeTiny)
            make.leading.equalTo(titleTextField)
            make.top.equalTo(titleTextField.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
        }
        
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(subtitleIcon)
            make.leading.equalTo(subtitleIcon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        
        addSubview(functionButtonContainerView)
        functionButtonContainerView.snp.makeConstraints { make in
            make.top.equalTo(subtitleIcon.snp.bottom).offset(Constants.Size.ContentSpaceMid)
            make.leading.equalTo(titleTextField)
            make.height.equalTo(Constants.Size.IconSizeHuge.height)
        }
        
        functionButtonContainerView.addSubview(retroButton)
        retroButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeHuge)
        }
        
        functionButtonContainerView.addSubview(skinButton)
        skinButton.snp.makeConstraints { make in
            make.leading.equalTo(retroButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.size.equalTo(Constants.Size.IconSizeHuge)
        }
        
        functionButtonContainerView.addSubview(cheatCodeButton)
        cheatCodeButton.snp.makeConstraints { make in
            make.leading.equalTo(skinButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeHuge)
        }
        
        addSubview(startGameButton)
        startGameButton.snp.makeConstraints { make in
            make.centerY.equalTo(functionButtonContainerView)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.ItemHeightMid)
            make.leading.equalTo(functionButtonContainerView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.top.equalTo(functionButtonContainerView.snp.bottom).offset(29)
            make.height.equalTo(50)
            make.leading.equalTo(functionButtonContainerView)
            make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        
        addSubview(deleteSaveStateButton)
        deleteSaveStateButton.snp.makeConstraints { make in
            make.centerY.equalTo(segmentView)
            make.size.equalTo(Constants.Size.ItemHeightMid)
            make.leading.equalTo(segmentView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalTo(startGameButton)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func update3DSFunctionButton() {
        threeDSAdvancedModeButton.removeFromSuperview()
        jitContextMenuButton.removeFromSuperview()
        jitButton.removeFromSuperview()
        threeDSModecontextMenuButton.removeFromSuperview()
        threeDSModeButton.removeFromSuperview()
        shaderContextMenuButton.removeFromSuperview()
        shaderButton.removeFromSuperview()
        languageContextMenuButton.removeFromSuperview()
        languageButton.removeFromSuperview()
        rightEyeRenderMenuButton.removeFromSuperview()
        rightEyeRenderButton.removeFromSuperview()
        threeDSAdvancedSettingButton.removeFromSuperview()
        if let lastView = functionButtonContainerView.subviews.last {
            functionButtonContainerView.addSubview(threeDSAdvancedModeButton)
            threeDSAdvancedModeButton.snp.makeConstraints { make in
                make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
            }
            
            
            if Settings.defalut.threeDSAdvancedSettingMode {
                functionButtonContainerView.addSubview(threeDSAdvancedSettingButton)
                threeDSAdvancedSettingButton.snp.makeConstraints { make in
                    make.leading.equalTo(threeDSAdvancedModeButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(Constants.Size.IconSizeHuge)
                    make.trailing.equalToSuperview()
                }
            } else {
                //JIT按钮
                functionButtonContainerView.addSubview(jitContextMenuButton)
                functionButtonContainerView.addSubview(jitButton)
                jitButton.snp.makeConstraints { make in
                    make.leading.equalTo(threeDSAdvancedModeButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(Constants.Size.IconSizeHuge)
                }
                jitContextMenuButton.snp.makeConstraints { make in
                    make.edges.equalTo(jitButton)
                }
                
                //模式选择按钮
                functionButtonContainerView.addSubview(threeDSModecontextMenuButton)
                functionButtonContainerView.addSubview(threeDSModeButton)
                threeDSModeButton.snp.makeConstraints { make in
                    make.leading.equalTo(jitButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(Constants.Size.IconSizeHuge)
                }
                threeDSModecontextMenuButton.snp.makeConstraints { make in
                    make.edges.equalTo(threeDSModeButton)
                }
                
                //着色器选择按钮
                functionButtonContainerView.addSubview(shaderContextMenuButton)
                functionButtonContainerView.addSubview(shaderButton)
                shaderButton.snp.makeConstraints { make in
                    make.leading.equalTo(threeDSModeButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(Constants.Size.IconSizeHuge)
                }
                shaderContextMenuButton.snp.makeConstraints { make in
                    make.edges.equalTo(shaderButton)
                }
                
                //语言选择按钮
                functionButtonContainerView.addSubview(languageContextMenuButton)
                functionButtonContainerView.addSubview(languageButton)
                languageButton.snp.makeConstraints { make in
                    make.leading.equalTo(shaderButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(Constants.Size.IconSizeHuge)
                }
                languageContextMenuButton.snp.makeConstraints { make in
                    make.edges.equalTo(languageButton)
                }
                
                //右眼渲染按钮
                functionButtonContainerView.addSubview(rightEyeRenderMenuButton)
                functionButtonContainerView.addSubview(rightEyeRenderButton)
                rightEyeRenderButton.snp.makeConstraints { make in
                    make.leading.equalTo(languageButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(Constants.Size.IconSizeHuge)
                    make.trailing.equalToSuperview()
                }
                rightEyeRenderMenuButton.snp.makeConstraints { make in
                    make.edges.equalTo(rightEyeRenderButton)
                }
            }
        }
    }
    
    private func updatePSPFunctionButton() {
        if let lastView = functionButtonContainerView.subviews.last {
            //语言选择按钮
            functionButtonContainerView.addSubview(languageContextMenuButton)
            functionButtonContainerView.addSubview(languageButton)
            languageButton.snp.makeConstraints { make in
                make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
                make.trailing.equalToSuperview()
            }
            languageContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(languageButton)
            }
        }
    }
    
    private func updateSaturnFunctionButton() {
        guard let game else { return }
        if game.defaultCore == 0 {
            cheatCodeButton.removeFromSuperview()
        }
        if game.defaultCore == 0, let lastView = functionButtonContainerView.subviews.last {
            //语言选择按钮
            functionButtonContainerView.addSubview(languageContextMenuButton)
            functionButtonContainerView.addSubview(languageButton)
            languageButton.snp.makeConstraints { make in
                make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
                make.trailing.equalToSuperview()
            }
            languageContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(languageButton)
            }
        }
    }
    
    private func updateDSFunctionButton() {
        languageContextMenuButton.removeFromSuperview()
        languageButton.removeFromSuperview()
        ndsSystemTypeContextMenuButton.removeFromSuperview()
        ndsSystemTypeButton.removeFromSuperview()
        gbaSlotContextMenuButton.removeFromSuperview()
        gbaSlotButton.removeFromSuperview()
        if let lastView = functionButtonContainerView.subviews.last {
            //语言选择按钮
            functionButtonContainerView.addSubview(languageContextMenuButton)
            functionButtonContainerView.addSubview(languageButton)
            languageButton.snp.makeConstraints { make in
                make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
            }
            languageContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(languageButton)
            }
            
            var enableGBASlot = true
            if let game, let mode = game.getExtraString(key: ExtraKey.ndsSystemMode.rawValue), mode == "DSi" {
                enableGBASlot = false
            }
            
            //系统类型
            functionButtonContainerView.addSubview(ndsSystemTypeContextMenuButton)
            functionButtonContainerView.addSubview(ndsSystemTypeButton)
            ndsSystemTypeButton.snp.makeConstraints { make in
                make.leading.equalTo(languageButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
                if !enableGBASlot {
                    make.trailing.equalToSuperview()
                }
            }
            ndsSystemTypeContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(ndsSystemTypeButton)
            }
            
            if enableGBASlot {
                //GBA Slot
                functionButtonContainerView.addSubview(gbaSlotContextMenuButton)
                functionButtonContainerView.addSubview(gbaSlotButton)
                gbaSlotButton.snp.makeConstraints { make in
                    make.leading.equalTo(ndsSystemTypeButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(Constants.Size.IconSizeHuge)
                    make.trailing.equalToSuperview()
                }
                gbaSlotContextMenuButton.snp.makeConstraints { make in
                    make.edges.equalTo(gbaSlotButton)
                }
            }
        }
    }
    
    private func updateN64FunctionButton() {
        if let lastView = functionButtonContainerView.subviews.last {
            //transferPak
            functionButtonContainerView.addSubview(transferPakContextMenuButton)
            functionButtonContainerView.addSubview(transferPakButton)
            transferPakButton.snp.makeConstraints { make in
                make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
            }
            transferPakContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(transferPakButton)
            }
            
            //RDP
            functionButtonContainerView.addSubview(rdpPluginContextMenuButton)
            functionButtonContainerView.addSubview(rdpPluginButton)
            rdpPluginButton.snp.makeConstraints { make in
                make.leading.equalTo(transferPakButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
                make.trailing.equalToSuperview()
            }
            rdpPluginContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(rdpPluginButton)
            }
        }
    }
    
    private func updateVBOrPMFunctionButton() {
        cheatCodeButton.removeFromSuperview()
        
        retroButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeHuge)
        }
        
        skinButton.snp.makeConstraints { make in
            make.leading.equalTo(retroButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.size.equalTo(Constants.Size.IconSizeHuge)
            make.trailing.equalToSuperview()
        }
    }
    
    private func updatePS1FunctionButton() {
        if let lastView = functionButtonContainerView.subviews.last {
            //导入sbi文件
            functionButtonContainerView.addSubview(psxImportSbiButton)
            psxImportSbiButton.snp.makeConstraints { make in
                make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
            }
            
            //手柄模式
            functionButtonContainerView.addSubview(psxModeContextMenuButton)
            functionButtonContainerView.addSubview(psxModeButton)
            psxModeButton.snp.makeConstraints { make in
                make.leading.equalTo(psxImportSbiButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
            }
            psxModeContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(psxModeButton)
            }
            
            //Renderer
            functionButtonContainerView.addSubview(psxRendererContextMenuButton)
            functionButtonContainerView.addSubview(psxRendererButton)
            psxRendererButton.snp.makeConstraints { make in
                make.leading.equalTo(psxModeButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
                make.trailing.equalToSuperview()
            }
            psxRendererContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(psxRendererButton)
            }
            
        }
    }
    
    private func updateDCFunctionButton() {
        cheatCodeButton.removeFromSuperview()
        
        if let lastView = functionButtonContainerView.subviews.last {
            //jit
            functionButtonContainerView.addSubview(jitContextMenuButton)
            functionButtonContainerView.addSubview(jitButton)
            jitButton.snp.makeConstraints { make in
                make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
            }
            jitContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(jitButton)
            }
            
            //jitless core ver
            functionButtonContainerView.addSubview(dcCoreContextMenuButton)
            functionButtonContainerView.addSubview(dcCoreButton)
            dcCoreButton.snp.makeConstraints { make in
                make.leading.equalTo(jitButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
            }
            dcCoreContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(dcCoreButton)
            }
            
            //语言选择按钮
            functionButtonContainerView.addSubview(languageContextMenuButton)
            functionButtonContainerView.addSubview(languageButton)
            languageButton.snp.makeConstraints { make in
                make.leading.equalTo(dcCoreButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
                make.trailing.equalToSuperview()
            }
            languageContextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(languageButton)
            }
        }
    }
    
    private func updateMDFunctionButton() {
        if let game, game.defaultCore == 0 {
            cheatCodeButton.removeFromSuperview()
            if let lastView = functionButtonContainerView.subviews.last {
                //TV Standard
                functionButtonContainerView.addSubview(tvStandardMenuButton)
                functionButtonContainerView.addSubview(tVStandardButton)
                tVStandardButton.snp.makeConstraints { make in
                    make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(Constants.Size.IconSizeHuge)
                }
                tvStandardMenuButton.snp.makeConstraints { make in
                    make.edges.equalTo(tVStandardButton)
                }
            }
        }
    }
    
    private func updateSNESFunctionButton() {
        if let lastView = functionButtonContainerView.subviews.last {
            //VRAM
            functionButtonContainerView.addSubview(snesVRAMMenuButton)
            functionButtonContainerView.addSubview(snesVRAMButton)
            snesVRAMButton.snp.makeConstraints { make in
                make.leading.equalTo(lastView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.IconSizeHuge)
                make.trailing.equalToSuperview()
            }
            snesVRAMMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(snesVRAMButton)
            }
            
        }
    }
    
}
