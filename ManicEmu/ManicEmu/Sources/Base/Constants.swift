//
//  Constants.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import RealmSwift
import KeychainAccess
import ManicEmuCore

struct Constants {
    struct Size {
        //系统常用尺寸
        static var WindowSize: CGSize { UIWindow.applicationWindow?.bounds.size ?? .zero }
        static var WindowWidth: CGFloat { WindowSize.width }
        static var WindowHeight: CGFloat { WindowSize.height }
        static var SafeAera: UIEdgeInsets { UIWindow.applicationWindow?.safeAreaInsets ?? .zero}
        
        //布局
        ///间距 24
        static let ContentSpaceHuge = 24.0
        ///间距 20
        static let ContentSpaceMax = 20.0
        ///间距 16
        static let ContentSpaceMid = 16.0
        ///间距 12
        static let ContentSpaceMin = 12.0
        ///间距 8
        static let ContentSpaceTiny = 8.0
        ///间距 4
        static let ContentSpaceUltraTiny = 4.0
        
        ///图标尺寸 76x76
        static let IconSizeHuge = CGSize(width: 76, height: 76)
        ///图标尺寸 36x36
        static let IconSizeMax = CGSize(width: 36, height: 36)
        ///图标尺寸 30x30
        static let IconSizeMid = CGSize(width: 30, height: 30)
        ///图标尺寸 24x24
        static let IconSizeMin = CGSize(width: 24, height: 24)
        ///图标尺寸 18x18
        static let IconSizeTiny = CGSize(width: 18, height: 18)
        
        /// 圆角半径 20
        static let CornerRadiusMax = 20.0
        /// 圆角半径 16
        static let CornerRadiusMid = 16.0
        /// 圆角半径 12
        static let CornerRadiusMin = 12.0
        /// 圆角半径 8
        static let CornerRadiusTiny = 8.0
        
        /// 条目高度 76
        static let ItemHeightHuge = 76.0
        /// 条目高度 60
        static let ItemHeightMax = 60.0
        /// 条目高度 50
        static let ItemHeightMid = 50.0
        /// 条目高度 44
        static let ItemHeightMin = 44.0
        /// 条目高度 36
        static let ItemHeightTiny = 36.0
        /// 条目高度 30
        static let ItemHeightUltraTiny = 30.0
        
        ///符号图标size 16
        static let SymbolSize = 18.0
        
        ///HomeTabBarSize 300x60
        static let HomeTabBarSize = CGSize(width: 300, height: ItemHeightMax)
        /// 侧边视图宽度
        static let SideMenuWidth = UIDevice.isPhone ? WindowSize.minDimension * 0.874 : 300
        ///分割线高度
        static let BorderLineHeight = 1.0
        /// 游戏封面宽高比 默认1:1
        static func GameCoverRatio(gameType: GameType) -> CGFloat {
            if GameCoverForceSquare {
                return 1.0
            }
            switch GameCoverStyle {
            case .style1:
                switch gameType {
                case ._3ds, .ds: return 1.13
                case .md, .gg: return 0.711
                case ._32x, .ms: return 0.706
                case .sg1000: return 0.735
                case .nes: return 0.7
                case .snes: return 1.4
                case .psp: return 0.57
                case .ss: return 0.638
                case .n64: return 1.369
                default: return 1.0
                }
            case .style2:
                return 1.0
            case .style3:
                return 1.0
            }
        }
        ///游戏列表选中状态外边缘 6.0
        static let GamesListSelectionEdge = 6.0
        ///游戏封面最大尺寸 300pt 可能是600px或者900px
        static let GameCoverMaxSize = 300.0
        ///游戏名称最大长度 255
        static let GameNameMaxCount = 255
        
        ///CollectionView的top缩进
        static var ContentInsetTop: CGFloat {
            let safeArea = Constants.Size.SafeAera
            return safeArea.top > 0 ? safeArea.top : Constants.Size.ContentSpaceMax
        }
        
        ///CollectionView的bottom缩进
        static var ContentInsetBottom: CGFloat {
            let safeArea = Constants.Size.SafeAera
            return safeArea.bottom > 0 ? safeArea.bottom : Constants.Size.ContentSpaceMax
        }
        
        ///游戏封面圆角样式
        static var GameCoverStyle = CoverStyle.style1
        static var GameCoverCornerRatio = GameCoverStyle.defaultCornerRadius()
        static var GameCoverForceSquare = false
        ///苹果图标默认尺寸
        static func AppleIconCornerRadius(height: CGFloat) -> CGFloat {
            return 10/57 * height
        }
        
        static var GamesPerRow = 2.0
        static var GamesHideScrollIndicator = false
        static var GamesHideTitle = false
        static var GamesHideGroupTitle = false
        static var GamesGroupTitleStyle: GroupTitleStyle = .abbr
    }
    
    struct Color {
        //文本
        static let LabelPrimary = UIColor(.dm,
                                          light: UIColor(hexString: "#ffffff")!,
                                          dark: UIColor(hexString: "#ffffff")!)
        static let LabelSecondary = UIColor(.dm,
                                            light: UIColor(hexString: "#8F8F92")!,
                                            dark: UIColor(hexString: "#8F8F92")!)
        static let LabelTertiary = UIColor(.dm,
                                           light: UIColor(hexString: "#403E46")!,
                                           dark: UIColor(hexString: "#403E46")!)
        static let LabelQuaternary = UIColor(.dm,
                                             light: UIColor(hexString: "#3f3f3f", transparency: 0.8)!,
                                             dark: UIColor(hexString: "#3f3f3f", transparency: 0.8)!)
        
        //分割线
        static let Border = UIColor(.dm,
                                    light: .white.withAlphaComponent(0.1),
                                    dark: .white.withAlphaComponent(0.1))
        
        //背景
        static let Background = UIColor(.dm,
                                              light: UIColor(hexString: "#17171D")!,
                                              dark: UIColor(hexString: "#17171D")!)
        
        static let BackgroundPrimary = UIColor(.dm,
                                              light: UIColor(hexString: "#1E1E24")!,
                                              dark: UIColor(hexString: "#1E1E24")!)
        
        static let BackgroundSecondary = UIColor(.dm,
                                           light: UIColor(hexString: "#26262E")!,
                                           dark: UIColor(hexString: "#26262E")!)
        
        static let BackgroundTertiary = UIColor(.dm,
                                           light: UIColor(hexString: "#464651")!,
                                           dark: UIColor(hexString: "#464651")!)
        
        static let Selection = UIColor(.dm,
                                       light: UIColor(hexString: "#2c2c30")!,
                                       dark: UIColor(hexString: "#2c2c30")!)
        
        //阴影
        static let Shadow = BackgroundPrimary
        
        //颜色
        static var Gradient = [UIColor(hexString: "#FF2442")!, UIColor(hexString: "#EB7500")!, UIColor(hexString: "#BB64FF")!, UIColor(hexString: "#0096FF")!]
        
        static var MainDynamicColor = UIColor(hexString: "#FF2442")!
        
        static let Main = UIColor(.dm) { traitCollection in
//            if (traitCollection.userInterfaceStyle == .light) {
//                return UIColor(hexString: "#FF2442")!
//            }
            return MainDynamicColor
        }
        
        static let Red = UIColor(.dm,
                                 light: UIColor(hexString: "#FF2442")!,
                                 dark: UIColor(hexString: "#FF2442")!)
        
        static let Green = UIColor(.dm,
                                   light: UIColor(hexString: "#06D58F")!,
                                   dark: UIColor(hexString: "#06D58F")!)
        
        static let Blue = UIColor(.dm,
                                  light: UIColor(hexString: "#7984FF")!,
                                  dark: UIColor(hexString: "#7984FF")!)
        
        static let Indigo = UIColor(.dm,
                                    light: UIColor(hexString: "#33A9FF")!,
                                    dark: UIColor(hexString: "#33A9FF")!)
        
        static let Purple = UIColor(.dm,
                                    light: UIColor(hexString: "#9390FF")!,
                                    dark: UIColor(hexString: "#9390FF")!)
        
        static let Yellow = UIColor(.dm,
                                    light: UIColor(hexString: "#FEC458")!,
                                    dark: UIColor(hexString: "#FEC458")!)

        
        static let Magenta = UIColor(.dm,
                                     light: UIColor(hexString: "#FF7B7F")!,
                                     dark: UIColor(hexString: "#FF7B7F")!)

        
        static let Orange = UIColor(.dm,
                                    light: UIColor(hexString: "#FF7A71")!,
                                    dark: UIColor(hexString: "#FF7A71")!)
        
        static let Pink = UIColor(.dm,
                                    light: UIColor(hexString: "#FB89DE")!,
                                    dark: UIColor(hexString: "#FB89DE")!)
    }
    
    struct Cipher {
        static let BaiduYunAppKey = ""
        static let BaiduYunSecretKey = ""
        static let DropboxAppKey = ""
        static let DropboxAppSecret = ""
        static let GoogleDriveAppId = ""
        static let OneDriveAppId = ""
        static let OneDriveSecrectKey = ""
        static let AliYunAppId = ""
        static let AliYunSecrectKey = ""
        static let UMAppKey = "6"._7.d.b._7.c._6.c._4._8.a.c._1.b._4.f._8._7.f._0._8.e._9.a
        static let CLoudflareAPIToken = ""
        static let UnzipKey = "123456"
        static let DeepSeek = ""
        static let RetroAPI = "blahblahblah"
    }
    
    struct Path {
        static let Document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        static var Data: String {
            let path = Document.appendingPathComponent("Datas")
            if !FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            }
            return path
        }
        static let Library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        static let Cache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        static let Temp = NSTemporaryDirectory()
        static let PasteWorkSpace = Temp.appendingPathComponent("PasteWorkSpace")
        static let UploadWorkSpace = Temp.appendingPathComponent("UploadWorkSpace")
        static let ShareWorkSpace = Temp.appendingPathComponent("ShareWorkSpace")
        static let DownloadWorkSpace = Cache.appendingPathComponent("DownloadWorkSpace")
        static let SMBWorkSpace = Temp.appendingPathComponent("SMBWorkSpace")
        static let DropWorkSpace = Temp.appendingPathComponent("DropWorkSpace")
        static let SaveStateWorkSpace = Temp.appendingPathComponent("SaveStateWorkSpace")
        static let ZipWorkSpace = Temp.appendingPathComponent("ZipWorkSpace")
        static let Realm = Library.appendingPathComponent("Realm")
        static let RealmFilePath = Realm.appendingPathComponent("default.realm")
        static let Resource = Library.appendingPathComponent("System.bundle")
        static let ThreeDS = Document.appendingPathComponent("3DS")
        static let ThreeDSSystemData = ThreeDS.appendingPathComponent("sysdata")
        static let ThreeDSStateLoad = ThreeDS.appendingPathComponent("states")
        static let ThreeDSConfig = ThreeDS.appendingPathComponent("config/config.ini")
        static let ThreeDSDefaultConfig = Resource.appendingPathComponent("3DS.ini")
        static let BoxArtsCache = Cache.appendingPathComponent("BoxArtsCache")
        static let Libretro = Library.appendingPathComponent("Libretro")
        static func PSPCheat(gameCode: String) -> String { Document.appendingPathComponent("PPSSPP/PSP/Cheats/\(gameCode).ini") }
        static let Shaders = Libretro.appendingPathComponent("shaders")
        static let Screenshot = Libretro.appendingPathComponent("screenshots")
        static let PSPSave = Document.appendingPathComponent("PPSSPP/PSP/SAVEDATA")
        static let Nestopia = Document.appendingPathComponent(LibretroCore.Cores.Nestopia.name)
        static let Snes9x = Document.appendingPathComponent(LibretroCore.Cores.Snes9x.name)
        static let PicoDrive = Document.appendingPathComponent(LibretroCore.Cores.PicoDrive.name)
        static let Yabause = Document.appendingPathComponent(LibretroCore.Cores.Yabause.name)
        static let BeetleSaturn = Document.appendingPathComponent(LibretroCore.Cores.BeetleSaturn.name)
        static let Mupen64PlushNext = Document.appendingPathComponent(LibretroCore.Cores.Mupen64PlushNext.name)
        static let BIOS = Document.appendingPathComponent("BIOS")
        static let System = Libretro.appendingPathComponent("system")
        static let DSSavePath = ThreeDS.appendingPathComponent("sdmc/saves/nds")
        static let GBASavePath = ThreeDS.appendingPathComponent("sdmc/saves/gba")
        static let GBCSavePath = ThreeDS.appendingPathComponent("sdmc/saves/gbc")
        static let GBSavePath = ThreeDS.appendingPathComponent("sdmc/saves/gb")
        static let BeetleVB = Document.appendingPathComponent(LibretroCore.Cores.BeetleVB.name)
        static let PokeMini = Document.appendingPathComponent(LibretroCore.Cores.PokeMini.name)
        static let BeetlePSXHW = Document.appendingPathComponent(LibretroCore.Cores.BeetlePSXHW.name)
        static let bsnes = Document.appendingPathComponent(LibretroCore.Cores.bsnes.name)
        static let LibretroSavePath = Document
        static let GamesDB = Resource.appendingPathComponent("Games.db")
    }
    
    struct DefaultKey {
        static let HasShowPrivacyAlert = "HasShowPrivacyAlert"
        static let AppGroupName = "group.aoshuang.ManicEmu"
        static let AppGroupIsPremiumKey = "AppGroupIsPremiumKey"
        static let HasShowCheatCodeWarning = "HasShowCheatCodeWarning"
        static let HadSavedSnapshot = "HadSavedSnapshot"
        static let ShowRequestReviewDate = "ShowRequestReviewDate"
        static let SystemCoreVersion = "SystemCoreVersion"
        static let HasShow3DSPlayAlert = "HasShow3DSPlayAlert"
        static let HasShow3DSNotSupportAlert = "HasShow3DSNotSupportAlert"
        static let FlexSkinFirstTimeGuide = "FlexSkinFirstTimeGuide"
        static let HasShowSSPlayAlert = "HasShowSSPlayAlert"
        static let HasShowPS1PlayAlert = "HasShowPS1PlayAlert"
        static let HasShowJumpGameInfoAlert = "HasShowJumpGameInfoAlert"
    }
    
    struct Font {
        enum Size { case s, m, l}
        
        /// title
        /// - Parameters:
        ///   - size: s: 17 m: 18 l: 24
        ///   - weight: 默认medium
        /// - Returns: UIFont
        static func title(size: Size = .l, weight: UIFont.Weight = .bold) -> UIFont {
            switch size {
            case .s:
                UIFont.systemFont(ofSize: 17, weight: weight)
            case .m:
                UIFont.systemFont(ofSize: 18, weight: weight)
            case .l:
                UIFont.systemFont(ofSize: 24, weight: weight)
            }
        }
        
        /// body
        /// - Parameters:
        ///   - size: s: 13 m: 14 l: 15
        ///   - weight: 默认regular
        /// - Returns: UIFont
        static func body(size: Size = .s, weight: UIFont.Weight = .regular) -> UIFont {
            switch size {
            case .s:
                UIFont.systemFont(ofSize: 13, weight: weight)
            case .m:
                UIFont.systemFont(ofSize: 14, weight: weight)
            case .l:
                UIFont.systemFont(ofSize: 15, weight: weight)
            }
        }
        
        /// caption
        /// - Parameters:
        ///   - size: s: 8 m: 10 l: 12
        ///   - weight: 默认regular
        /// - Returns: UIFont
        static func caption(size: Size = .m, weight: UIFont.Weight = .regular) -> UIFont {
            switch size {
            case .s:
                UIFont.systemFont(ofSize: 8, weight: weight)
            case .m:
                UIFont.systemFont(ofSize: 10, weight: weight)
            case .l:
                UIFont.systemFont(ofSize: 12, weight: weight)
            }
        }
    }
    
    struct Strings {
        static let SupportEmail = "support@manicemu.site"
        static let MemberKeyChainKey = "MemberKeyChainKey"
        static let OAuthCallbackHost = "manicemu-oauth"
        static let OAuthGoogleDriveCallbackHost = "com.googleusercontent.apps.177622908853-bkjvno7a5v14obn3rn70s264afrll6p7"
        static let OAuthOneDriveCallbackHost = "msauth.com.aoshuang.manicemu"
        static let TimeFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        static let FileNameTimeFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        static let PlayPurchaseAlertIdentifier = "PlayPurchaseAlertIdentifier"
        static let ThreeDSHomeMenuIdentifier = "1126106065309442"
        static let ThreeDSHomeMenuIdentifier2 = "1126106065311746"
        static let PSPConsoleLanguage = ["Automatic", "English", "日本語", "Français", "Español", "Deutsch", "Italiano", "Nederlands", "Português", "Русский", "한국어", "繁體中文", "简体中文"]
        static let ThreeDSConsoleLanguage = ["Automatic", "Japan", "USA" , "Europe", "Australia", "China", "Korea", "Taiwan"]
        static let SaturnConsoleLanguage = ["Auto Detect", "Japan", "North America", "Europe", "South Korea", "Asia (NTSC)", "Asia (PAL)", "Brazil", "Latin America"]
        static let DSConsoleLanguage = ["Automatic", "Japanese", "English", "French", "German", "Italian", "Spanish"]
        static let DCConsoleLanguage = ["Default", "Japanese", "English", "German",  "French",  "Spanish", "Italian"]
        static let ManicScheme = "manicemu"
        static var PSXController = "PlayStation Controller"
        static var PSXDualShock = "DualShock"
    }
    
    enum Config {
        static let AppName: String = value(forKey: "CFBundleDisplayName")
        static let AppVersion: String = value(forKey: "CFBundleShortVersionString")
        static let AppIdentifier: String = value(forKey: "CFBundleIdentifier")
        static func value<T>(forKey key: String) -> T {
            guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? T else {
                fatalError("Invalid value or undefined key")
            }
            return value
        }
        static var PlatformOrder: [String]? = nil
        static var DefaultOrientation: UIInterfaceOrientationMask {
            UIDevice.isPad ? .all : .allButUpsideDown
        }
    }
    
    struct Numbers {
        /// 游戏页面功能按钮个数
        static let GameFunctionButtonCount = 4
        /// 游戏截图发大倍数
        static let GameSnapshotScaleRatio = 5.0
        /// 自动存档间隔 秒
        static let AutoSaveGameDuration = 60
        /// 自动存档最大个数
        static var AutoSaveGameCount: Int {
            PurchaseManager.isMember ? 50 : 3
        }
        /// 非会员手动存档最大个数
        static var NonMemberManualSaveGameCount = 3
        /// 随机游戏功能最少需要多少个游戏
        static let RandomGameLimit = 10
        ///非会员最大金手指数量
        static let NonMemberCheatCodeCount = 3
        /// 动画执行时间
        static let LongAnimationDuration = 1.0
        ///主题颜色最大数量
        static let ThemeColorMaxCount = 5
    }
    
    struct NotificationName {
        ///购买成功
        static let PurchaseSuccess = NSNotification.Name(rawValue: "PurchaseSuccess")
        ///切换homeBar object是BarSelection
        static let HomeSelectionChange = NSNotification.Name(rawValue: "HomeSelectionChange")
        ///会员资格变化
        static let MembershipChange = NSNotification.Name(rawValue: "MembershipChange")
        ///商品更新成功
        static let ProductsUpdate = NSNotification.Name(rawValue: "ProductsUpdate")
        ///开始游戏
        static let StartPlayGame = NSNotification.Name(rawValue: "StartPlayGame")
        ///结束游戏
        static let StopPlayGame = NSNotification.Name(rawValue: "StopPlayGame")
        ///控制器映射更新
        static let ControllerMapping = NSNotification.Name(rawValue: "ControllerMapping")
        ///下载状态通知
        static let BeginDownload = NSNotification.Name(rawValue: "BeginDownload")
        static let StopDownload = NSNotification.Name(rawValue: "StopDownload")
        ///主题颜色变更
        static let GradientColorChange = NSNotification.Name(rawValue: "GradientColorChange")
        static let MainColorChange = NSNotification.Name(rawValue: "MainColorChange")
        ///游戏封面样式变更
        static let GameCoverChange = NSNotification.Name(rawValue: "GameCoverChange")
        ///游戏平台顺序更新
        static let PlatformOrderChange = NSNotification.Name(rawValue: "PlatformOrderChange")
        //游戏平台切换更新
        static let PlatformSelectionChange = NSNotification.Name(rawValue: "PlatformSelectionChange")
        ///游戏列表变更
        static let GameListStyleChange = NSNotification.Name(rawValue: "GameListStyleChange")
        ///shake
        static let MotionShake = NSNotification.Name(rawValue: "MotionShake")
        ///退出游戏
        static let QuitGaming = NSNotification.Name(rawValue: "QuitGaming")
        ///关闭硬核模式
        static let TurnOffHardcore = NSNotification.Name(rawValue: "TurnOffHardcore")
        ///游戏排序更新
        static let GameSortChange = NSNotification.Name(rawValue: "GameSortChange")
        ///成就解锁进度常驻关闭
        static let TurnOffAlwaysShowProgress = NSNotification.Name(rawValue: "TurnOffAlwaysShowProgress")
    }
    
    struct URLs {
        #if DEBUG
        static let ManicEMU = "http://10.10.10.20:4000/"
        #else
        static let ManicEMU = "https://manicemu.site/"
        #endif
        static let AppReview = URL(string: "itms-apps://itunes.apple.com/app/id6743335790?action=write-review")!
        static let AppStoreUrl = URL(string: "https://apps.apple.com/app/id6743335790")!
        static let TermsOfUse = URL(string: ManicEMU + "terms-of-use")!
        static let PrivacyPolicy = URL(string: ManicEMU + "privacy-policy")!
        static let PaymentTerms = URL(string: ManicEMU + "Payment-Terms")!
        static var FAQ: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "FAQ-CN")! : URL(string: ManicEMU + "FAQ-EN")!
        }
        static var GameImportGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "Game-Import-Guide-CN")! : URL(string: ManicEMU + "Game-Import-Guide-EN")!
        }
        static var SkinUsageGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "Skin-Usage-Guide-CN")! : URL(string: ManicEMU + "Skin-Usage-Guide-EN")!
        }
        static var ControllerUsageGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "Controller-Usage-Guide-CN")! : URL(string: ManicEMU + "Controller-Usage-Guide-EN")!
        }
        static var CheatCodesGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "Cheat-Codes-Guide-CN")! : URL(string: ManicEMU + "Cheat-Codes-Guide-EN")!
        }
        static var AirPlayUsageGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "AirPlay-Usage-Guide-CN")! : URL(string: ManicEMU + "AirPlay-Usage-Guide-EN")!
        }
        static var JoinQQ: URL {
            URL(string: "https://pd.qq.com/s/7i1g6jf5k")!
        }
//        static var JoinTelegram: URL {
//            URL(string: "https://t.me/+R56rb3Sa9hM0YjEx")!
//        }
        static var JoinDiscord: URL {
            URL(string: "https://discord.gg/qsaTHzknAZ")!
        }
        static func DeltaStyles(gameType: GameType) -> URL {
            switch gameType {
            case .nes: return URL(string: "https://deltastyles.com/systems/nes")!
            case .snes: return URL(string: "https://deltastyles.com/systems/snes")!
            case .gbc: return URL(string: "https://deltastyles.com/systems/gbc")!
            case .gb: return URL(string: "https://deltastyles.com/systems/gbc")!
            case .gba: return URL(string: "https://deltastyles.com/systems/gba")!
            case .ds: return URL(string: "https://deltastyles.com/systems/nds")!
            case ._3ds: return URL(string: "https://deltastyles.com/systems/3ds")!
            case .n64: return URL(string: "https://deltastyles.com/systems/n64")!
            case .psp: return URL(string: "https://deltastyles.com/systems/psp")!
            case .md: return URL(string: "https://deltastyles.com/systems/genesis")!
            case .mcd: return URL(string: "https://deltastyles.com/systems/cd")!
            case ._32x: return URL(string: "https://deltastyles.com/systems/32x")!
            case .sg1000: return URL(string: "https://deltastyles.com/systems/sg1000")!
            case .gg: return URL(string: "https://deltastyles.com/systems/gamegear")!
            case .ms: return URL(string: "https://deltastyles.com/systems/ms")!
            case .ss: return URL(string: "https://deltastyles.com/systems/saturn")!
            case .vb: return URL(string: "https://deltastyles.com/systems/virtualboy")!
            case .ps1: return URL(string: "https://deltastyles.com/systems/ps1")!
            default: return URL(string: "https://deltastyles.com")!
            }
        }
        static func History(gameType: GameType) -> URL {
            return URL(string: ManicEMU + "History-" + (gameType == .gb ? GameType.gbc.localizedShortName : gameType.localizedShortName) + "-EN")!
        }
        static let WFC = URL(string: "https://cdn.altstore.io/file/deltaemulator/delta/wfc-servers.json")!
        #if SIDE_LOAD
        static let Donate = URL(string: "https://ko-fi.com/maftymanicemu")!
        #endif
        static let AboutUS = URL(string: ManicEMU + "About-US")!
        static let RetroSignUp = URL(string: "https://retroachievements.org/createaccount.php")!
        static func RetroProfile(username: String) -> URL {
            return URL(string: "https://retroachievements.org/user/\(username)")!
        }
        static let Retro = URL(string: "https://retroachievements.org")!
        static let MobyGames = URL(string: "https://www.mobygames.com")!
    }
    
    struct BIOS {
        static let MegaCDBios = [
            BIOSItem(fileName: "bios_CD_E.bin", imported: false, desc: "MegaCD EU BIOS", required: true),
            BIOSItem(fileName: "bios_CD_U.bin", imported: false, desc: "SegaCD US BIOS", required: true),
            BIOSItem(fileName: "bios_CD_J.bin", imported: false, desc: "MegaCD JP BIOS", required: true)
        ]
        
        static let SaturnBios = [
            BIOSItem(fileName: "saturn_bios.bin", imported: false, desc: "Yabause Saturn BIOS", required: false),
            BIOSItem(fileName: "sega_101.bin", imported: false, desc: "Beetle Saturn JP BIOS for JP games", required: true),
            BIOSItem(fileName: "mpr-17933.bin", imported: false, desc: "Beetle Saturn US.mdEU BIOS for US/EU games", required: true),
            BIOSItem(fileName: "mpr-18811-mx.ic1", imported: false, desc: "The King of Fighters '95 ROM Cartridge", required: false),
            BIOSItem(fileName: "mpr-19367-mx.ic1", imported: false, desc: "Ultraman: Hikari no Kyojin Densetsu ROM Cartridge", required: false),
        ]
        
        static let DSBios = [
            BIOSItem(fileName: "bios7.bin", imported: false, desc: "NDS ARM7 BIOS", required: false),
            BIOSItem(fileName: "bios9.bin", imported: false, desc: "NDS ARM9 BIOS", required: false),
            BIOSItem(fileName: "firmware.bin", imported: false, desc: "NDS Firmware", required: false),
            BIOSItem(fileName: "dsi_bios7.bin", imported: false, desc: "DSi ARM7 BIOS - Required in DSi mode", required: false),
            BIOSItem(fileName: "dsi_bios9.bin", imported: false, desc: "DSi ARM9 BIOS - Required in DSi mode", required: false),
            BIOSItem(fileName: "dsi_firmware.bin", imported: false, desc: "DSi Firmware - Required in DSi mode", required: false),
            BIOSItem(fileName: "dsi_nand.bin", imported: false, desc: "DSi NAND - Required in DSi mode", required: false)
        ]
        
        static let PS1Bios = [
            BIOSItem(fileName: "ps1_rom.bin", imported: false, desc: "Comes from the PS3, region-free", required: false),
            BIOSItem(fileName: "PSXONPSP660.bin", imported: false, desc: "Comes from the PSP, region-free", required: false),
            BIOSItem(fileName: "scph5500.bin", imported: false, desc: "PS1 JP BIOS - Required for JP games", required: false),
            BIOSItem(fileName: "scph5501.bin", imported: false, desc: "PS1 US BIOS - Required for US games", required: false),
            BIOSItem(fileName: "scph5502.bin", imported: false, desc: "PS1 EU BIOS - Required for EU games", required: false)
        ]
        
        static let DCBios = [
            BIOSItem(fileName: "dc_boot.bin", imported: false, desc: "Required for Dreamcast", required: false)
        ]

    }
}
