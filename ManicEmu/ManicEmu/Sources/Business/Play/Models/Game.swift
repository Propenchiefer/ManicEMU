//
//  Game.swift
//  ManicEmu
//
//  Created by Max on 2025/1/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import RealmSwift
import ManicEmuCore
import IceCream
#if !targetEnvironment(simulator)
import ThreeDS
#endif
import SmartCodable

enum ThreeDSMode: Int, PersistableEnum {
    case compatibility, performance, quality
}

extension Game: CKRecordConvertible & CKRecordRecoverable {}

class Game: Object, ObjectUpdatable {
    
    ///id 由文件的Hash值决定
    @Persisted(primaryKey: true) var id: String
    ///游戏名称 默认是文件名 不包含扩展名
    @Persisted var name: String
    ///别名 用户自行修改的名称
    @Persisted var aliasName: String? = nil
    ///文件名后缀
    @Persisted var fileExtension: String
    ///游戏类型
    @Persisted var gameType: GameType
    ///封面图片数据 可以用于生产UIImage
    @Persisted var gameCover: CreamAsset?
    ///作弊码列表
    @Persisted var gameCheats: List<GameCheat>
    ///指定竖屏皮肤
    @Persisted var portraitSkin: Skin?
    ///指定横屏皮肤
    @Persisted var landscapeSkin: Skin?
    ///导入时间
    @Persisted var importDate: Date
    ///最后一次游玩时间
    @Persisted var latestPlayDate: Date?
    ///总共游玩时长 ms
    @Persisted var totalPlayDuration: Double = 0
    ///上一次游玩时长 ms
    @Persisted var latestPlayDuration: Double = 0
    ///游戏模拟器存档
    @Persisted var gameSaveStates: List<GameSaveState>
    ///游戏音乐开关
    @Persisted var volume: Bool = true
    ///快进速度
    @Persisted var speed: GameSetting.FastForwardSpeed = .one
    ///分辨率
    @Persisted var resolution: GameSetting.Resolution = .one
    ///交换屏幕
    @Persisted var swapScreen: Bool = false
    ///游戏震感
    @Persisted var haptic: GameSetting.HapticType = .soft
    ///控制器方式
    @Persisted var controllerType: GameSetting.ControllerType = .dPad
    ///屏幕旋转方式
    @Persisted var orientation: GameSetting.OrientationType = .auto
    /// 使用的滤镜名称 nil则不使用滤镜
    @Persisted var filterName: String? = nil
    ///额外数据备用
    @Persisted var extras: Data?
    ///用于iCloud同步删除
    @Persisted var isDeleted: Bool = false
    ///jit是否开启
    @Persisted var jit: Bool = false
    ///精确贴图
    @Persisted var accurateShaders: Bool = false
    ///是否搜索过封面
    @Persisted var hasCoverMatch: Bool = false
    ///在线匹配的封面路径
    @Persisted var onlineCoverUrl: String? = nil
    ///机型语言或地区选项
    @Persisted var region: Int = 0
    ///是否允许渲染右眼
    @Persisted var renderRightEye: Bool = false
    ///默认核心 土星0:Beetle 1:Yabause
    @Persisted var defaultCore: Int = 0
    ///GBC调色板
    @Persisted var pallete: GameSetting.Palette = .None
    ///是否强制全屏 不进行同步
    var forceFullSkin: Bool = false
    ///当前光盘的index 多碟游戏才有效
    var currentDiskIndex: UInt = 0
    ///当前游戏总共有多少张光盘 多碟游戏才有效
    var totalDiskCount: UInt = 0
    static let DsHomeMenuPrimaryKey = "Home Menu"
    static let DsiHomeMenuPrimaryKey = "Home Menu (DSi)"
    
    ///文件是否存在
    var isRomExtsts: Bool {
        FileManager.default.fileExists(atPath: romUrl.path)
    }
    ///游戏自带存档是否存在
    var isSaveExtsts: Bool {
        FileManager.default.fileExists(atPath: gameSaveUrl.path)
    }
    
    /// 文件名 包含名称和扩展名
    var fileName: String {
        "\(name).\(fileExtension)"
    }
    
    //游戏文件路径
    var romUrl: URL {
        if isMultiFileGame {
            return URL(fileURLWithPath: Constants.Path.Data.appendingPathComponent(fileName.deletingPathExtension).appendingPathComponent(fileName))
        }
        
        var localUrl = URL(fileURLWithPath: Constants.Path.Data.appendingPathComponent(fileName))
#if !targetEnvironment(simulator)
        if gameType == ._3ds,
           fileExtension.lowercased() == "app", let ciaPath = ThreeDSCore.shared.getCIAContentPath(identifier: identifierFor3DS) {
            localUrl = URL(fileURLWithPath: ciaPath)
        }
#endif
        return localUrl
    }
    //游戏自带存档路径
    var gameSaveUrl: URL {
#if !targetEnvironment(simulator)
        if gameType == ._3ds {
            //存档 sdmc/Nintendo 3DS/000...0/000...0/title/[game-TID-high]/[game-TID-low]/data/00000001/
            if let titlePath = ThreeDSCore.shared.getTitlePath(identifier: self.identifierFor3DS) {
                return URL(fileURLWithPath: titlePath.appendingPathComponent("data/00000001/"))
            }
        }
#endif
        
        if gameType == .psp {
            if let code = self.gameCodeForPSP {
                if let path = try? FileManager.default.contentsOfDirectory(atPath: Constants.Path.PSPSave).first(where: { $0.hasPrefix(code) }) {
                    return URL(fileURLWithPath: Constants.Path.PSPSave.appendingPathComponent(path))
                }
            }
        } else if gameType == .nes {
            return URL(fileURLWithPath: Constants.Path.Nestopia.appendingPathComponent("\(name).srm"))
        } else if gameType == .snes {
            return URL(fileURLWithPath: Constants.Path.bsnes.appendingPathComponent("\(name).srm"))
        } else if isPicodriveCore {
            return URL(fileURLWithPath: Constants.Path.PicoDrive.appendingPathComponent("\(name).srm"))
        } else if gameType == .n64 {
            return URL(fileURLWithPath: Constants.Path.Mupen64PlushNext.appendingPathComponent("\(name).srm"))
        } else if gameType == .ss {
            if defaultCore == 0 {
                return URL(fileURLWithPath: Constants.Path.BeetleSaturn.appendingPathComponent("\(name).bkr"))
            } else {
                return URL(fileURLWithPath: Constants.Path.Yabause.appendingPathComponent("\(name).srm"))
            }
        } else if gameType == .ds {
            return URL(fileURLWithPath: Constants.Path.DSSavePath.appendingPathComponent("\(name).srm"))
        } else if gameType == .gba {
            return URL(fileURLWithPath: Constants.Path.GBASavePath.appendingPathComponent("\(name).sav"))
        } else if gameType == .gbc {
            return URL(fileURLWithPath: Constants.Path.GBCSavePath.appendingPathComponent("\(name).sav"))
        } else if gameType == .gb {
            return URL(fileURLWithPath: Constants.Path.GBSavePath.appendingPathComponent("\(name).sav"))
        } else if gameType == .vb {
            return URL(fileURLWithPath: Constants.Path.BeetleVB.appendingPathComponent("\(name).srm"))
        } else if gameType == .pm {
            return URL(fileURLWithPath: Constants.Path.PokeMini.appendingPathComponent("\(name).eep"))
        } else if gameType == .ps1 {
            return URL(fileURLWithPath: Constants.Path.BeetlePSXHW.appendingPathComponent("\(name).srm"))
        }
        
        let localUrl = URL(fileURLWithPath: Constants.Path.Data.appendingPathComponent("\(name).\(gameType.manicEmuCore?.gameSaveExtension ?? "")"))
        return localUrl
    }
    
    var identifierFor3DS: UInt64 {
        if gameType == ._3ds,
           let extras,
           let extraInfos = try? extras.jsonObject() as? [String: Any],
           let identifier = extraInfos["identifier"] as? UInt64 {
            return identifier
        } else {
#if !targetEnvironment(simulator)
            if let info = ThreeDSCore.shared.information(for: romUrl) {
                return info.identifier
            }
#endif
            return 0
        }
    }
    
    var gameCodeForPSP: String? {
        if gameType == .psp,
           let extras,
           let extraInfos = try? extras.jsonObject() as? [String: Any],
           let gameTitle = extraInfos["PSPGameCode"] as? String {
            return gameTitle
        } else {
            return nil
        }
    }
    
    var translatedName: String? {
        if let extras,
           let extraInfos = try? extras.jsonObject() as? [String: Any],
           let name = extraInfos["translatedName"] as? String {
            return name
        } else {
            return nil
        }
    }
    
    func setExtras(_ extras: [AnyHashable: Any]) {
        Game.change { realm in
            self.extras = extras.jsonData()
        }
    }
    
    var libretroShaderPath: String? {
        if let filterName {
            return Constants.Path.Shaders.appendingPathComponent(filterName)
        }
        return nil
    }
    
    func isBIOSMissing(required: Bool = true) -> Bool {
        let requireBIOS: [BIOSItem]
        if gameType == .mcd {
            requireBIOS = Constants.BIOS.MegaCDBios.filter({ required ? $0.required : true })
        } else if gameType == .ss {
            if defaultCore == 0 {
                requireBIOS = Array(Constants.BIOS.SaturnBios[1...2]).filter({ required ? $0.required : true })
            } else {
                requireBIOS = [Constants.BIOS.SaturnBios[0]].filter({ required ? $0.required : true })
            }
        } else if gameType == .ds {
            requireBIOS = Constants.BIOS.DSBios.filter({ required ? $0.required : true })
        } else if gameType == .ps1 {
            //PS1的BIOS必须确保至少拥有一个
            var isPS1BIOSMissing = true
            let fileManager = FileManager.default
            for bios in Constants.BIOS.PS1Bios {
                let biosInLib = Constants.Path.System.appendingPathComponent(bios.fileName)
                let biosInDoc = Constants.Path.BIOS.appendingPathComponent(bios.fileName)
                if fileManager.fileExists(atPath: biosInLib) {
                    isPS1BIOSMissing = false
                    break
                } else if fileManager.fileExists(atPath: biosInDoc) {
                    try? FileManager.safeCopyItem(at: URL(fileURLWithPath: biosInDoc), to: URL(fileURLWithPath: biosInLib))
                    isPS1BIOSMissing = false
                    break
                }
            }
            return isPS1BIOSMissing
        } else {
            return false
        }
        let fileManager = FileManager.default
        for bios in requireBIOS {
            var biosInLib = Constants.Path.System.appendingPathComponent(bios.fileName)
            if gameType == .dc {
          //      biosInLib = Constants.Path.Flycast.appendingPathComponent("dc/\(bios.fileName)")
            }
            let biosInDoc = Constants.Path.BIOS.appendingPathComponent(bios.fileName)
            if fileManager.fileExists(atPath: biosInLib) {
                continue
            } else if fileManager.fileExists(atPath: biosInDoc) {
                try? FileManager.safeCopyItem(at: URL(fileURLWithPath: biosInDoc), to: URL(fileURLWithPath: biosInLib))
                continue
            } else {
                return true
            }
        }
        return false
    }
    
    var ps1OverrideBIOSConfig: String {
        let regionFreeBios = ["ps1_rom.bin", "PSXONPSP660.bin"]
        let fileManager = FileManager.default
        for (index, bios) in regionFreeBios.enumerated() {
            let biosInLib = Constants.Path.System.appendingPathComponent(bios)
            let biosInDoc = Constants.Path.BIOS.appendingPathComponent(bios)
            if fileManager.fileExists(atPath: biosInLib) {
                return index == 0 ? "ps1_rom" : "psxonpsp"
            } else if fileManager.fileExists(atPath: biosInDoc) {
                try? FileManager.safeCopyItem(at: URL(fileURLWithPath: biosInDoc), to: URL(fileURLWithPath: biosInLib))
                return index == 0 ? "ps1_rom" : "psxonpsp"
            }
        }
        return "disabled"
    }
    
    var libretroCorePath: String? {
        if gameType == .psp {
            return Bundle.main.path(forResource: "ppsspp.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if gameType == .nes {
            return Bundle.main.path(forResource: "nestopia.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if gameType == .snes {
            return Bundle.main.path(forResource: "bsnes.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if isPicodriveCore {
            return Bundle.main.path(forResource: "picodrive.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if gameType == .ss {
            if self.fileExtension.lowercased() == "iso" || defaultCore == 1 {
                return Bundle.main.path(forResource: "yabause.libretro", ofType: "framework", inDirectory: "Frameworks")
            } else if defaultCore == 0 {
                return Bundle.main.path(forResource: "mednafen.saturn.libretro", ofType: "framework", inDirectory: "Frameworks")
            }
        } else if gameType == .n64 {
            return Bundle.main.path(forResource: "mupen64plus.next.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if gameType == .vb {
            return Bundle.main.path(forResource: "mednafen.vb.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if gameType == .pm {
            return Bundle.main.path(forResource: "pokemini.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if gameType == .ps1 {
            return Bundle.main.path(forResource: "mednafen.psx.hw.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if gameType == .gb || gameType == .gbc {
            return Bundle.main.path(forResource: "gambatte.libretro", ofType: "framework", inDirectory: "Frameworks")
        } else if gameType == .gba {
            if defaultCore == 0 {
                return Bundle.main.path(forResource: "mgba.libretro", ofType: "framework", inDirectory: "Frameworks")
            } else {
                return Bundle.main.path(forResource: "vbam.libretro", ofType: "framework", inDirectory: "Frameworks")
            }
        } else if gameType == .dc {
            if jit {
                return Bundle.main.path(forResource: "flycast.libretro", ofType: "framework", inDirectory: "Frameworks")
            } else {
                if defaultCore == 0 {
                    return Bundle.main.path(forResource: "flycast-jitless.libretro", ofType: "framework", inDirectory: "Frameworks")
                } else {
                    return Bundle.main.path(forResource: "flycast-jitless-wince.libretro", ofType: "framework", inDirectory: "Frameworks")
                }
            }
        }
        return nil
    }
    
    var isPicodriveCore: Bool {
        if gameType == .md || gameType == .mcd || gameType == ._32x || gameType == .sg1000 || gameType == .gg || gameType == .ms {
            return true
        }
        return false
    }
    
    var hasTransferPak: Bool {
        guard gameType == .n64 else { return false }
        let romPath = romUrl.path
        if FileManager.default.fileExists(atPath: romPath + ".gb"), FileManager.default.fileExists(atPath: romPath + ".sav") {
            return true
        }
        return false
    }
    
    var isNDSHomeMenuGame: Bool {
        guard gameType == .ds else { return false }
        if isDSHomeMenuGame || isDSiHomeMenuGame {
            return true
        }
        return false
    }
    
    var isDSHomeMenuGame: Bool {
        guard gameType == .ds else { return false }
        if id == Game.DsHomeMenuPrimaryKey {
            return true
        }
        return false
    }
    
    var isDSiHomeMenuGame: Bool {
        guard gameType == .ds else { return false }
        if id == Game.DsiHomeMenuPrimaryKey {
            return true
        }
        return false
    }
    
    func getExtra(key: String) -> Any? {
        if let extras {
            return Self.getExtra(extras: extras, key: key)
        }
        return nil
    }
    
    func updateExtra(key: String, value: Any) {
        if let extras, let data = Self.updateExtra(extras: extras, key: key, value: value) {
            Self.change { realm in
                self.extras = data
            }
        } else if let data = [key: value].jsonData() {
            Self.change { realm in
                self.extras = data
            }
        }
    }
    
    var hasGBASlotInsert: Bool {
        guard gameType == .ds else { return false }
        if FileManager.default.fileExists(atPath: romUrl.path + ".slot.gba") {
            return true
        }
        return false
    }
    
    var isN64ParaLLEl: Bool {
        return gameType == .n64 && !(getExtraBool(key: ExtraKey.rdpPlugin.rawValue) ?? true)
    }
    
    var is3DSHomeMenuGame: Bool {
        if Constants.Strings.ThreeDSHomeMenuIdentifier == "\(identifierFor3DS)" ||
            Constants.Strings.ThreeDSHomeMenuIdentifier2 == "\(identifierFor3DS)" {
            return true
        }
        return false
    }
    
    var supportRetroAchievements: Bool {
        if gameType == ._3ds || gameType == .ds {
            return false
        }
        return true
    }
    
    var supportSwapDisc: Bool {
        if fileExtension.lowercased() == "m3u" || fileExtension.lowercased() == "pbp" {
            return true
        }
        return false
    }
    
    func getAchievementProgress(id: Int) -> AchievementProgress? {
        if let jsonString = getExtraString(key: ExtraKey.achievementsProgress.rawValue) {
            if let progresses = [AchievementProgress].deserialize(from: jsonString) {
                return progresses.first(where: { $0.id == id })
            }
        }
        return nil
    }
    
    func updateAchievementProgress(_ progress: AchievementProgress) {
        if let jsonString = getExtraString(key: ExtraKey.achievementsProgress.rawValue) {
            if var progresses = [AchievementProgress].deserialize(from: jsonString) {
                progresses.removeAll(where: { $0.id == progress.id })
                progresses.append(progress)
                if let jsonString = progresses.toJSONString() {
                    updateExtra(key: ExtraKey.achievementsProgress.rawValue, value: jsonString)
                }
            }
        }
    }
    
    func removeAchievementProgress(id: Int) {
        if let jsonString = getExtraString(key: ExtraKey.achievementsProgress.rawValue) {
            if var progresses = [AchievementProgress].deserialize(from: jsonString) {
                var isRemoved = false
                progresses.removeAll(where: {
                    if $0.id == id {
                        isRemoved = true
                        return true
                    } else {
                        return false
                    }
                })
                if isRemoved, let jsonString = progresses.toJSONString() {
                    updateExtra(key: ExtraKey.achievementsProgress.rawValue, value: jsonString)
                }
            }
        }
    }
    
    var isMultiFileGame: Bool {
        return fileExtension.lowercased() == "m3u" || fileExtension.lowercased() == "cue" || fileExtension.lowercased() == "gdi" 
    }
    
}


struct AchievementProgress: SmartCodable {
    var id: Int = 0
    var measuredProgress: String = ""
    var measuredPercent: CGFloat = 0
    
    
    
}
