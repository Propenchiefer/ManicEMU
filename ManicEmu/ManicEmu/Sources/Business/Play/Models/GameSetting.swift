//
//  GameSetting.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/5.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import RealmSwift
import ManicEmuCore

struct GameSetting: SettingCellItem {
    enum ControllerType: Int, PersistableEnum {
        case dPad, thumbStick
        
        var image: UIImage {
            switch self {
            case .dPad:
                UIImage(symbol: .dpad)
            case .thumbStick:
                R.image.customArcadeStick()!.applySymbolConfig()
            }
        }
        
        var title: String {
            switch self {
            case .dPad:
                R.string.localizable.gameSettingControllerTypeDPad()
            case .thumbStick:
                R.string.localizable.gameSettingControllerTypeStick()
            }
        }
        
        var next: ControllerType {
            return self == .dPad ? .thumbStick : .dPad
        }
    }
    
    enum HapticType: Int, PersistableEnum {
        case off, soft, light, medium, heavy, rigid
        
        var image: UIImage {
            switch self {
            case .off:
                UIImage(symbol: .iphoneSlash)
            default:
                UIImage(symbol: .iphoneRadiowavesLeftAndRight)
            }
        }
        
        var title: String {
            switch self {
            case .off:
                R.string.localizable.gameSettingHapticOff()
            case .soft:
                R.string.localizable.gameSettingHapticSoft()
            case .light:
                R.string.localizable.gameSettingHapticLight()
            case .medium:
                R.string.localizable.gameSettingHapticMedium()
            case .heavy:
                R.string.localizable.gameSettingHapticHeavy()
            case .rigid:
                R.string.localizable.gameSettingHapticRigid()
            }
        }
        
        var next: HapticType {
            if let type = HapticType(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .off
            }
        }
    }
    
    enum OrientationType: Int, PersistableEnum {
        case auto, portrait, landscape
        
        var title: String {
            switch self {
            case .auto:
                R.string.localizable.gameSettingOrientationAuto()
            case .portrait:
                R.string.localizable.gameSettingOrientationPortrait()
            case .landscape:
                R.string.localizable.gameSettingOrientationLandscape()
            }
        }
        
        var next: OrientationType {
            if let type = OrientationType(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .auto
            }
        }
    }
    
    enum FastForwardSpeed: Int, CaseIterable, PersistableEnum  {
        case one = 1, two, three, four, five
        
        var title: String {
            R.string.localizable.gameSettingFastForward(self == .one ? "" : " x\(self.rawValue)")
        }
        
        var next: FastForwardSpeed {
            if let speed = FastForwardSpeed(rawValue: self.rawValue + 1) {
                return speed
            } else {
                return .one
            }
        }
    }
    
    //undefine是为了realm迁移时不出问题
    enum Resolution: Int, CaseIterable, PersistableEnum  {
        case undefine, one, two, three, four, five, six, seven, eight, nine, ten
        
        var title: String {
            return R.string.localizable.gameSettingResolution(self == .undefine ? "x1" : "x\(self.rawValue)")
        }
        
        var next: Resolution {
            if let speed = Resolution(rawValue: self.rawValue + 1) {
                return speed
            } else {
                return .one
            }
        }
        
        //PS1
        static var ResolutionForPS1: [Resolution] { Array(Resolution.allCases[1..<5]) }
        
        static var AllResolutionTitleForPS1: [String] { ["1x", "2x", "4x", "8x"] }
        
        var resolutionTitleForPS1: String {
            let titles = Self.AllResolutionTitleForPS1
            if let index = Self.ResolutionForPS1.firstIndex(of: self), index < titles.count {
                return titles[index]
            }
            return "1x"
        }
        
        var nextForPS1: Resolution {
            if let p = Resolution(rawValue: self.rawValue + 1), Self.ResolutionForPS1.contains([p]) {
                return p
            } else {
                return .one
            }
        }
        
        //N64ParaLLEl
        static var ResolutionForN64ParaLLEl: [Resolution] { Array(Resolution.allCases[1..<4]) }
        
        static var AllResolutionTitleForN64ParaLLEl: [String] { ["1x", "2x", "4x"] }
        
        var resolutionTitleForN64ParaLLEl: String {
            let titles = Self.AllResolutionTitleForN64ParaLLEl
            if let index = Self.ResolutionForN64ParaLLEl.firstIndex(of: self), index < titles.count {
                return titles[index]
            }
            return "1x"
        }
        
        var nextForN64ParaLLEl: Resolution {
            if let p = Resolution(rawValue: self.rawValue + 1), Self.ResolutionForN64ParaLLEl.contains([p]) {
                return p
            } else {
                return .one
            }
        }
    }
    
    enum Palette: Int, CaseIterable, PersistableEnum {
        case None, DMG, Light, Pocket, Blue, Brown, DarkBlue, DarkBrown, DarkGreen, Grayscale, Green, Inverted, Orange, PastelMix, Red, Yellow
        
        var shortTitle: String {
            switch self {
            case .None: ""
            case .DMG: "DMG"
            case .Light: "Light"
            case .Pocket: "Pocket"
            case .Blue: "Blue"
            case .Brown: "Brown"
            case .DarkBlue: "Dark Blue"
            case .DarkBrown: "Dark Brown"
            case .DarkGreen: "Dark Green"
            case .Grayscale: "Grayscale"
            case .Green: "Green"
            case .Inverted: "Inverted"
            case .Orange: "Orange"
            case .PastelMix: "Pastel Mix"
            case .Red: "Red"
            case .Yellow: "Yellow"
            }
        }
        
        var option: String {
            switch self {
            case .None:
                ""
            case .DMG:
                "GB - DMG"
            case .Light:
                "GB - Light"
            case .Pocket:
                "GB - Pocket"
            case .Blue:
                "GBC - Blue"
            case .Brown:
                "GBC - Brown"
            case .DarkBlue:
                "GBC - Dark Blue"
            case .DarkBrown:
                "GBC - Dark Brown"
            case .DarkGreen:
                "GBC - Dark Green"
            case .Grayscale:
                "GBC - Grayscale"
            case .Green:
                "GBC - Green"
            case .Inverted:
                "GBC - Inverted"
            case .Orange:
                "GBC - Orange"
            case .PastelMix:
                "GBC - Pastel Mix"
            case .Red:
                "GBC - Red"
            case .Yellow:
                "GBC - Yellow"
            }
        }
        
        var title: String {
            return R.string.localizable.paletteTitle() +  (self == .None ? "" : "\n") + shortTitle
        }
        
        var next: Palette {
            if let p = Palette(rawValue: self.rawValue + 1) {
                return p
            } else {
                return .None
            }
        }
        
        //For VB
        static var PalettesForVB: [Palette] { Array(Palette.allCases[0..<8]) }
        
        static var AllPaletteTitleForVB: [String] { ["black & red", "black & white", "black & blue", "black & cyan", "black & electric cyan", "black & green", "black & magenta", "black & yellow"] }
        
        var paletteTitleForVB: String {
            let titles = Self.AllPaletteTitleForVB
            if let index = Self.PalettesForVB.firstIndex(of: self), index < titles.count {
                return titles[index]
            }
            return "black & red"
        }
        
        var nextForVB: Palette {
            if let p = Palette(rawValue: self.rawValue + 1), Self.PalettesForVB.contains([p]) {
                return p
            } else {
                return .None
            }
        }
        
        //For PM
        static var PalettesForPM: [Palette] { Array(Palette.allCases[0..<14]) }
        
        static var AllPaletteTitleForPM: [String] { ["Default", "Old", "Monochrome", "Green", "Green Vector", "Red", "Red Vector", "Blue LCD", "LEDBacklight", "Girl Power", "Blue", "Blue Vector", "Sepia", "Monochrome Vector"] }
        
        var paletteTitleForPM: String {
            let titles = Self.AllPaletteTitleForPM
            if let index = Self.PalettesForPM.firstIndex(of: self), index < titles.count {
                return titles[index]
            }
            return "Default"
        }
        
        var nextForPM: Palette {
            if let p = Palette(rawValue: self.rawValue + 1), Self.PalettesForPM.contains([p]) {
                return p
            } else {
                return .None
            }
        }
    }
    
    enum ItemType: Int, CaseIterable {
        //位置很重要 新增内容一定要接到最后面
        case saveState, quickLoadState, volume, fastForward, stateList, cheatCode, skins, filter, screenShot, haptic, airplay, controllerSetting, orientation, functionSort, reload, quit, swapScreen, resolution, consoleHome, amiibo, toggleFullscreen, simBlowing, palette, swapDisk, retro
    }
    
    var type: ItemType
    var loadState: GameSaveState? = nil
    var volumeOn: Bool = true
    var fastForwardSpeed: FastForwardSpeed = .one
    var resolution: Resolution = .one
    var hapticType: HapticType = .soft
    var controllerType: ControllerType = .dPad
    var orientation: OrientationType = .auto
    var isFullScreen: Bool = false
    var palette: Palette = .None
    var currentDiskIndex: UInt = 0
    
    var image: UIImage {
        switch type {
        case .saveState:
            R.image.customArrowDownDocument()!.applySymbolConfig()
        case .quickLoadState:
            R.image.customTextDocument()!.applySymbolConfig()
        case .stateList:
            UIImage(symbol: .listTriangle)
        case .volume:
            if volumeOn {
                UIImage(symbol: .speakerWave2)
            } else {
                UIImage(symbol: .speakerSlash)
            }
        case .fastForward:
            UIImage(symbol: .forward)
        case .cheatCode:
            R.image.customAppleTerminal()!.applySymbolConfig()
        case .skins:
            UIImage(symbol: .tshirt)
        case .filter:
            UIImage(symbol: .cameraFilters)
        case .screenShot:
            UIImage(symbol: .cameraViewfinder)
        case .haptic:
            hapticType.image
        case .airplay:
            UIImage(symbol: .airplayvideo)
        case .controllerSetting:
            R.image.customArcadeStickConsole()!.applySymbolConfig()
        case .orientation:
            R.image.customRectangleLandscapeRotate()!.applySymbolConfig()
        case .functionSort:
            UIImage(symbol: .sliderHorizontalBelowRectangle)
        case .reload:
            R.image.customArrowTriangleheadClockwise()!.applySymbolConfig()
        case .quit:
            UIImage(symbol: .rectanglePortraitAndArrowRight)
        case .swapScreen:
            UIImage(symbol: .rectangle2Swap)
        case .resolution:
            UIImage(symbol: .sparklesTv)
        case .consoleHome:
            UIImage(symbol: .house)
        case .amiibo:
            UIImage(symbol: .dotRadiowavesLeftAndRight)
        case .toggleFullscreen:
            UIImage(symbol: .lJoystickPressDown)
        case .simBlowing:
            UIImage(symbol: .wind)
        case .palette:
            UIImage(symbol: .paintpalette)
        case .swapDisk:
            UIImage(symbol: .opticaldisc)
        case .retro:
            R.image.customTrophy()!.applySymbolConfig()
        }
    }
    
    var title: String {
        switch type {
        case .saveState:
            R.string.localizable.gameSettingSaveState()
        case .quickLoadState:
            R.string.localizable.gameSettingQuickLoadState()
        case .volume:
            R.string.localizable.gameSettingVolume()
        case .fastForward:
            fastForwardSpeed.title
        case .stateList:
            R.string.localizable.gameSettingStateList()
        case .cheatCode:
            R.string.localizable.gamesCheatCode()
        case .skins:
            R.string.localizable.gameSettingSkins()
        case .filter:
            R.string.localizable.gameSettingFilter()
        case .screenShot:
            R.string.localizable.gameSettingScreenShot()
        case .haptic:
            hapticType.title
        case .airplay:
            R.string.localizable.gameSettingAirplay()
        case .controllerSetting:
            R.string.localizable.gameSettingControllerSetting()
        case .orientation:
            orientation.title
        case .functionSort:
            R.string.localizable.gameSettingFunctionSort()
        case .reload:
            R.string.localizable.gameSettingReload()
        case .quit:
            R.string.localizable.gameSettingQuit()
        case .swapScreen:
            R.string.localizable.gameSettingSwapScreen()
        case .resolution:
            resolution.title
        case .consoleHome:
            R.string.localizable.consoleHomeTitle()
        case .amiibo:
            R.string.localizable.amiiboTitle()
        case .toggleFullscreen:
            if isFullScreen {
                R.string.localizable.showControlsTitle()
            } else {
                R.string.localizable.hideControlsTitle()
            }
        case .simBlowing:
            R.string.localizable.simulateBlowingTitle()
        case .palette:
            palette.title
        case .swapDisk:
            R.string.localizable.swapDisk() + "\nDisc \(currentDiskIndex + 1)"
        case .retro:
            R.string.localizable.retroAchievements2()
        }
    }
    
    func enable(for gameType: GameType, defaultCore: Int) -> Bool {
        switch gameType {
        case ._3ds:
            if type == .fastForward || type == .filter || type == .palette || type == .swapDisk || type == .retro {
                return false
            }
            return true
        case .ds:
            if type == .resolution || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .swapDisk {
                return false
            }
            return true
        case .gba, .gbc, .gb, .nes, .snes, .md, .mcd, ._32x, .gg, .sg1000, .ms, .ss, .vb, .pm:
            if (gameType == .gb || gameType == .vb || gameType == .pm) && type == .palette {
                return true
            }
            
            if (gameType == .mcd || gameType == .ss) && type == .swapDisk {
                return true
            }
            
            if (gameType == .vb || gameType == .pm) && type == .cheatCode {
                return false
            }
            
            if gameType == .md , type == .cheatCode, defaultCore == 0 {
                return false
            }
            
            if type == .swapScreen || type == .resolution || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .swapDisk {
                return false
            }
            return true
        case .psp, .n64:
            if type == .swapScreen || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .swapDisk {
                return false
            }
            return true
        case .ps1:
            if type == .swapScreen || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette {
                return false
            }
            return true
        case .dc:
            if type == .swapScreen || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .cheatCode {
                return false
            }
            return true
        default:
            return false
        }
    }
    
    var enableLongPress: Bool {
        switch self.type {
        case .quickLoadState, .fastForward, .haptic, .orientation, .resolution, .palette, .swapDisk:
            return true
        default:
            return false
        }
    }
    
    var inputKey: String {
        switch self.type {
        case .saveState:
            "quickSave"
        case .quickLoadState:
            "quickLoad"
        case .volume:
            "volume"
        case .fastForward:
            "toggleFastForward"
        case .stateList:
            "saveStates"
        case .cheatCode:
            "cheatCodes"
        case .skins:
            "skins"
        case .filter:
            "filters"
        case .screenShot:
            "screenshot"
        case .haptic:
            "haptics"
        case .airplay:
            "airplay"
        case .controllerSetting:
            "controllers"
        case .orientation:
            "orientation"
        case .functionSort:
            "functionLayout"
        case .reload:
            "restart"
        case .quit:
            "quit"
        case .swapScreen:
            "reverseScreens"
        case .resolution:
            "resolution"
        case .consoleHome:
            "homeMenu"
        case .amiibo:
            "amiibo"
        case .toggleFullscreen:
            "toggleControlls"
        case .simBlowing:
            "blowing"
        case .palette:
            "palette"
        case .swapDisk:
            "swapDisk"
        case .retro:
            "retroAchievements"
        }
    }
    
    static func isValidInputKey(_ inputKey: String) -> Bool {
        return ["quickSave", "quickLoad", "volume", "toggleFastForward", "saveStates", "cheatCodes", "skins", "filters", "screenshot", "haptics", "airplay", "controllers", "orientation", "functionLayout", "restart", "quit", "reverseScreens", "resolution", "homeMenu", "amiibo", "toggleControlls", "blowing", "palette", "swapDisk", "retroAchievements"].contains([inputKey])
    }
}
