//
//  Database.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import RealmSwift
import ManicEmuCore
import IceCream

struct Database {
    static func setup(completion: (()->Void)? = nil) {
        do {
            let realm = Database.realm
            //如果setting已经初始化过 则不再初始化
            let oldSettings = realm.object(ofType: Settings.self, forPrimaryKey: Settings.defaultName)
            if oldSettings == nil {
                Log.debug("设置不存在 初始化设置")
                let settings = Settings()
                //添加默认皮肤
                let genDefaultSkins = generateDefaultSkins()
                settings.skinConfig = genDefaultSkins.defaultSkinMap
                
                //添加游戏菜单默认排序
                let functionList =  GameSetting.ItemType.allCases.reduce(List<Int>()) { partialResult, type in
                    partialResult.append(type.rawValue)
                    return partialResult
                }
                
                //将quit放置到最后
                for (index, function) in functionList.enumerated() {
                    if function == GameSetting.ItemType.quit {
                        functionList.remove(at: index)
                        break
                    }
                }
                functionList.append(GameSetting.ItemType.quit.rawValue)
                settings.gameFunctionList = functionList
                
                try realm.write {
                    realm.add(genDefaultSkins.defaultSkins)
                    realm.add(settings)
                }
            } else if let oldSettings = oldSettings {
                //设置已经存在，检查一下皮肤数量是否和模拟器数量一致，不一致的话 需要更新默认皮肤
                let defaultSkins = realm.objects(Skin.self).where { $0.skinType == .default }
                let defaultSkinsCount = defaultSkins.count
                if defaultSkinsCount != System.allCases.count {
                    Log.debug("更新设置 新增皮肤")
                    //默认皮肤数量不正确 可能新增了核心 需要重置皮肤
                    try? realm.write {
                        realm.delete(defaultSkins)
                    }
                    //添加默认皮肤
                    let genDefaultSkins = generateDefaultSkins()
                    
                    var newSkinConfig: String? = nil
                    if let oldSkinConfigs = SkinConfig.deserialize(from: oldSettings.skinConfig),
                       var newSkinConfigs = SkinConfig.deserialize(from: genDefaultSkins.defaultSkinMap) {
                        newSkinConfigs.portraitSkins.forEach { key, newValue in
                            if let oldValue = oldSkinConfigs.portraitSkins[key], oldValue != newValue {
                                Log.debug("保留竖屏旧皮肤默认设置:\(key)")
                                newSkinConfigs.portraitSkins[key] = oldValue
                            }
                        }
                        newSkinConfigs.landscapeSkins.forEach { key, newValue in
                            if let oldValue = oldSkinConfigs.landscapeSkins[key], oldValue != newValue {
                                Log.debug("保留横屏旧皮肤默认设置:\(key)")
                                newSkinConfigs.landscapeSkins[key] = oldValue
                            }
                        }
                        newSkinConfig = newSkinConfigs.toJSONString()
                    }
                    
                    
                    try? realm.write {
                        realm.add(genDefaultSkins.defaultSkins)
                        oldSettings.skinConfig = newSkinConfig ?? genDefaultSkins.defaultSkinMap
                    }
                }
                
                //检查一下是否新增了GameSetting 如果新增了需要加上
                if oldSettings.gameFunctionList.count != GameSetting.ItemType.allCases.count {
                    //数量不一致 需要进行新增
                    Log.debug("更新设置 新增游戏选项")
                    //找出缺失的GameSetting
                    var missItems = [Int]()
                    for item in GameSetting.ItemType.allCases {
                        if !oldSettings.gameFunctionList.contains([item.rawValue]) {
                            missItems.append(item.rawValue)
                        }
                    }
                    if missItems.count > 0 {
                        Log.debug("缺失的游戏选项:\(missItems)")
                        //先看看退出选项是否在最后一个
                        if let last = oldSettings.gameFunctionList.last, let lastItem = GameSetting.ItemType(rawValue: last), lastItem == .quit {
                            //最后一个选项是退出，则将新增的选项添加到退出前
                            let insertIndex = oldSettings.gameFunctionList.count - 1
                            try? realm.write({
                                oldSettings.gameFunctionList.insert(contentsOf: missItems, at: insertIndex)
                            })
                            Log.debug("插入缺失选项到退出前:\(oldSettings.gameFunctionList)")
                        } else {
                            //用户已经自定义过设置了，就不乱搞了 直接插到后面
                            try? realm.write({
                                oldSettings.gameFunctionList.append(objectsIn: missItems)
                            })
                            Log.debug("插入缺失选项到末尾:\(oldSettings.gameFunctionList)")
                        }
                    }
                }
            }
            //新增其他皮肤
            addEmbedSkins()
            
            //处理主题
            let theme = realm.object(ofType: Theme.self, forPrimaryKey: Theme.defaultName)
            if theme == nil {
                //初始化主题
                let newTheme = Theme()
                try? realm.write({
                    realm.add(newTheme)
                })
            } else if let theme {
                //检查是否新增了平台
                let platformOrder = theme.platformOrder
                let allPlatforms = System.allCases.map { $0.gameType.localizedShortName }
                var needToAdd = [String]()
                if platformOrder.count != allPlatforms.count {
                    //需要新增平台
                    for platform in allPlatforms {
                        if !(platformOrder.contains(where: { $0 == platform })) {
                            needToAdd.append(platform)
                        }
                    }
                    try? realm.write({
                        theme.platformOrder.insert(contentsOf: needToAdd, at: 0)
                    })
                }
                if theme.gamesPerRow == 0 {
                    try? realm.write({
                        theme.gamesPerRow = 2
                    })
                }
            }
            
            //检查是否有游戏的封面还没有匹配
            let games = realm.objects(Game.self).where { !$0.isDeleted && $0.gameCover == nil && !$0.hasCoverMatch }
            games.forEach { game in
                OnlineCoverManager.shared.addCoverMatch(OnlineCoverManager.CoverMatch(game: game))
            }
            
            if let systemCoreVersion = UserDefaults.standard.string(forKey: Constants.DefaultKey.SystemCoreVersion) {
                //如果存在版本记录，说明是旧版本升级到新版本，需要处理一下
                let systemCoreVersionNumber = UInt64(systemCoreVersion.replacingOccurrences(ofPattern: "\\.", withTemplate: ""))!
                
                if systemCoreVersionNumber < 141 {
                    //调整1.4.0的gameType问题
                    let mds = realm.objects(Game.self).where { $0.gameType == .md && ($0.fileExtension.equals("chd", options: .caseInsensitive) || $0.fileExtension.equals("32x", options: .caseInsensitive)) }
                    if mds.count > 0 {
                        try? realm.write {
                            for md in mds {
                                if md.fileExtension.lowercased() == "chd" {
                                    md.gameType = .mcd
                                } else if md.fileExtension.lowercased() == "32x" {
                                    md.gameType = ._32x
                                }
                            }
                        }
                    }
                }
                
                
                if systemCoreVersionNumber < 142 {
                    //调整土星的默认使用核心
                    //只有1.4.2之前的版本需要处理 将所有已经导入的SS核心默认使用Yabause
                    let games = realm.objects(Game.self).where({ $0.gameType == .ss })
                    if games.count > 0 {
                        try? realm.write({
                            for ss in games {
                                ss.defaultCore = 1
                            }
                        })
                    }
                }
                
                if systemCoreVersionNumber < 150 {
                    //1.5.0版本前的MD滤镜全部取消
                    let mds = realm.objects(Game.self).where({ $0.gameType == .md })
                    if mds.count > 0 {
                        try? realm.write({
                            for md in mds {
                                md.filterName = nil
                            }
                        })
                    }
                    
                    //将所有GB和GBC进行分离
                    let gbcs = realm.objects(Game.self).where({ $0.gameType == .gbc }).filter({ $0.fileExtension.lowercased() == "gb" })
                    if gbcs.count > 0 {
                        try? realm.write({
                            for gbc in gbcs {
                                gbc.gameType = .gb
                            }
                        })
                    }
                }
                
                if systemCoreVersionNumber < 155 {
                    let allSkins = realm.objects(Skin.self)
                    //调整skinType
                    //.buildIn的值等于原来的.manic .import等于原来的.delta
                    let oldSkins = allSkins.where({ $0.skinType == .buildIn || $0.skinType == .import })
                    try? realm.write({
                        for oldSkin in oldSkins {
                            if !oldSkin.fileName.contains("_FLEX.manicskin") {
                                oldSkin.skinType = .import
                            }
                        }
                    })
                    
                    //修复可能皮肤的identifier相同的错误
                    let defaultSkins = allSkins.where({ $0.skinType == .default })
                    for defaultSkin in defaultSkins {
                        let otherSkins = allSkins.where({ $0.identifier == defaultSkin.identifier && $0.skinType != .default && $0.gameType == defaultSkin.gameType })
                        if otherSkins.count > 0 {
                            for (index, otherSkin) in otherSkins.enumerated() {
                                try? realm.write {
                                    otherSkin.identifier = otherSkin.identifier + "_\(index)"
                                }
                            }
                        }
                    }
                }
                
                if systemCoreVersionNumber < 170 {
                    //调整snes gba的默认核心
                    let games = realm.objects(Game.self).where({ $0.gameType == .snes || $0.gameType == .gba })
                    if games.count > 0 {
                        try? realm.write({
                            for g in games {
                                if g.gameType == .gba, g.gameSaveStates.count > 0 {
                                    g.defaultCore = 1
                                } else if g.gameType == .snes {
                                    //如果将snes游戏迁移至bsnes 则将存档文件从Snes9x迁移到bsnes
                                    let oldSaveUrl = URL(fileURLWithPath: Constants.Path.Snes9x.appendingPathComponent("\(g.name).srm"))
                                    if FileManager.default.fileExists(atPath: oldSaveUrl.path) {
                                        try? FileManager.safeMoveItem(at: oldSaveUrl, to: URL(fileURLWithPath: Constants.Path.bsnes.appendingPathComponent("\(g.name).srm")), shouldReplace: true)
                                    }
                                }
                            }
                        })
                        
                        //将GBA即时存档文件都进行核心标记
                        for g in games {
                            if g.gameType == .gba, g.gameSaveStates.count > 0 {
                                for s in g.gameSaveStates {
                                    s.updateExtra(key: ExtraKey.saveStateCore.rawValue, value: 1)
                                }
                            }
                        }
                    }
#if SIDE_LOAD
                    //Sideload版本默认使用Picodrive
                    let picodriveGames = realm.objects(Game.self).where({ $0.gameType == .md || $0.gameType == .ms || $0.gameType == .gg || $0.gameType == .sg1000 })
                    if picodriveGames.count > 0 {
                        try? realm.write({
                            for g in picodriveGames {
                                g.defaultCore = 1
                            }
                        })
                        for g in picodriveGames {
                            if g.gameSaveStates.count > 0 {
                                for s in g.gameSaveStates {
                                    s.updateExtra(key: ExtraKey.saveStateCore.rawValue, value: 1)
                                }
                            }
                        }
                    }
#else
                    let picodriveGames = realm.objects(Game.self).where({ $0.gameType == .md || $0.gameType == .ms || $0.gameType == .gg || $0.gameType == .sg1000 })
                    if picodriveGames.count > 0 {
                        for g in picodriveGames {
                            //将picodrive的存档转移到Gearsystem或ClownMDEmu的目录
                            let oldSaveUrl = URL(fileURLWithPath: Constants.Path.PicoDrive.appendingPathComponent("\(g.name).srm"))
                            if FileManager.default.fileExists(atPath: oldSaveUrl.path) {
                                try? FileManager.safeMoveItem(at: oldSaveUrl, to: g.gameSaveUrl, shouldReplace: true)
                            }
                            //将旧的即时存档全部编辑Picodrive生成
                            if g.gameSaveStates.count > 0 {
                                for s in g.gameSaveStates {
                                    s.updateExtra(key: ExtraKey.saveStateCore.rawValue, value: 1)
                                }
                            }
                        }
                    }
#endif
                }
            }
        } catch {
            Log.error("初始化数据错误 \(error)")
        }
        completion?()
    }
    
    static var realm: Realm {
        do {
            return try Realm(configuration: defaultConfig)
        } catch {
            Log.error("生成数据库失败")
        }
        return try! Realm()
    }
    
    private static var defaultConfig: Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration
        //配置数据库路径
        if !FileManager.default.fileExists(atPath: Constants.Path.Realm) {
            try? FileManager.default.createDirectory(atPath: Constants.Path.Realm, withIntermediateDirectories: true)
        }
        config.fileURL = URL(fileURLWithPath: Constants.Path.RealmFilePath)
        //配置数据库版本 使用App版本来做控制
        config.schemaVersion = UInt64(Constants.Config.AppVersion.replacingOccurrences(ofPattern: "\\.", withTemplate: ""))!
        return config
    }
    
    private static func generateDefaultSkins() -> (defaultSkins: [Skin], defaultSkinMap: String) {
        //添加默认皮肤
        var defaultSkins = [Skin]()
        var defaultSkinMap = [String: String]()
        System.allCores.forEach { core in
            let gameType = core.gameType
            if let controllerSkin = ControllerSkin.standardControllerSkin(for: gameType),
                let hash = FileHashUtil.truncatedHash(url: controllerSkin.fileURL) {
                if let skin = realm.object(ofType: Skin.self, forPrimaryKey: hash) {
                    //这种情况 可能Settings被删除了
                    Log.error("Settings被误删除了!!!")
                    defaultSkins.append(skin)
                    defaultSkinMap[gameType.rawValue] = skin.id
                } else {
                    let skin = Skin()
                    skin.id = hash
                    skin.identifier = controllerSkin.identifier
                    skin.name = controllerSkin.name
                    skin.fileName = controllerSkin.fileURL.lastPathComponent
                    skin.gameType = controllerSkin.gameType
                    skin.skinType = .default
                    defaultSkins.append(skin)
                    defaultSkinMap[gameType.rawValue] = skin.id
                }
            }
        }
        if let jsonString = SkinConfig(portraitSkins: defaultSkinMap, landscapeSkins: defaultSkinMap).jsonString {
            return (defaultSkins, jsonString)
        }
        return (defaultSkins, "")
    }
    
    private static func addEmbedSkins() {
        DispatchQueue.global().async {
            let realm = Database.realm
            let fileManager = FileManager.default
            let resourcePath = Constants.Path.Resource
            if let contents = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                let skinNames = contents.filter { $0.hasSuffix(".manicskin") }
                var embedSkins = [Skin]()
                for skinName in skinNames {
                    if let controllerSkin = ControllerSkin(fileURL: URL(fileURLWithPath: resourcePath.appendingPathComponent(skinName))),
                       let hash = FileHashUtil.truncatedHash(url: controllerSkin.fileURL) {
                        if let skin = realm.object(ofType: Skin.self, forPrimaryKey: hash) {
                            Log.debug("皮肤:\(skin.name)已存在")
                        } else {
                            //有可能是更新了皮肤
                            var newSkinType = SkinType.buildIn
                            let oldSkins = realm.objects(Skin.self).where { $0.identifier == controllerSkin.identifier }
                            if oldSkins.count > 0 {
                                newSkinType = oldSkins.first!.skinType
                                Log.debug("\(controllerSkin.name) 皮肤进行了更新，移除旧的皮肤")
                                oldSkins.forEach {
                                    if let filePath = $0.skinData?.filePath {
                                        try? FileManager.safeRemoveItem(at: filePath)
                                    }
                                }
                                let assets = oldSkins.compactMap({ $0.skinData })
                                try? realm.write {
                                    if assets.count > 0 {
                                        realm.delete(assets)
                                    }
                                    realm.delete(oldSkins)
                                }
                            }
                            
                            let skin = Skin()
                            skin.id = hash
                            skin.identifier = controllerSkin.identifier
                            skin.name = controllerSkin.name
                            skin.fileName = controllerSkin.fileURL.lastPathComponent
                            skin.gameType = controllerSkin.gameType
                            skin.skinType = newSkinType
                            if newSkinType != .default {
                                skin.skinData = CreamAsset.create(objectID: skin.id, propName: "skinData", url: controllerSkin.fileURL)
                            }
                            embedSkins.append(skin)
                        }
                    }
                }
                if embedSkins.count > 0 {
                    try? realm.write({
                        realm.add(embedSkins)
                    })
                }
            }
        }
    }
}
