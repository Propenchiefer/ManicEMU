//
//  FilesImporter.swift
//  ManicEmu
//
//  Created by Max on 2025/1/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UniformTypeIdentifiers
import RealmSwift
import ManicEmuCore
import SSZipArchive
import ZIPFoundation
import IceCream
import SmartCodable
#if !targetEnvironment(simulator)
import ThreeDS
#endif
import PLzmaSDK

class FilesImporter: NSObject {
    static let shared = FilesImporter()
    private override init() {}
    private var manualHandle: (([URL])->Void)? = nil
    
    func presentImportController(supportedTypes: [UTType] = UTType.allTypes, allowsMultipleSelection: Bool = true, manualHandle: (([URL])->Void)? = nil, appControllerPresent: Bool = false) {
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPickerViewController.delegate = self
        documentPickerViewController.overrideUserInterfaceStyle = .dark
        documentPickerViewController.allowsMultipleSelection = allowsMultipleSelection
        documentPickerViewController.modalPresentationStyle = .formSheet
        documentPickerViewController.sheetPresentationController?.preferredCornerRadius = Constants.Size.CornerRadiusMax
        topViewController(appController: appControllerPresent)?.present(documentPickerViewController, animated: true)
        self.manualHandle = manualHandle
    }
}

extension FilesImporter: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if manualHandle != nil {
            manualHandle?(urls)
            manualHandle = nil
        } else {
            FilesImporter.importFiles(urls: urls)
        }
    }
}

extension FilesImporter {
    static func importFiles(urls: [URL],
                            preErrors: [Error] = [],
                            silentMode: Bool = PlayViewController.isGaming,
                            importCompletion: (()->Void)? = nil) {
        if urls.isEmpty {
            UIView.hideLoading()
            if preErrors.count > 0 {
                UIView.makeToast(message: String.errorMessage(from: preErrors))
            } else {
                UIView.makeToast(message: R.string.localizable.filesImporterErrorEmptyContent())
            }
            importCompletion?()
            return
        }
        
        if !silentMode {
            UIView.makeLoading()
        }
        
        //处理zip包
        handleZip(urls: urls, silentMode: silentMode) { unzipUrls in
            var urls = urls.filter({ !FileType.zip.extensions.contains($0.pathExtension) }) + unzipUrls
            
            //先处理cue和m3u
            let (multiFileResultUrls, multiFileResultError, multiFileResultItems) = handleMultiFiles(urls: urls)
            let (m3uResultUrls, m3uResultError, m3uResultM3uItems, m3uResultMultiFileItems) = handleM3uFiles(urls: multiFileResultUrls, multiFileItems: multiFileResultItems)
            
            urls = m3uResultUrls
            let group = DispatchGroup()
            var errors: [ImportError] = []
            var gameErrors = [ImportError]()
            gameErrors.append(contentsOf: m3uResultError)
            gameErrors.append(contentsOf: multiFileResultError)
            var skinErrors: [ImportError] = []
            var gameSaveErrors: [ImportError] = []
            var importGames: [String] = []
            var importSkins: [String] = []
            var importGameSaves: [String] = []
            for url in urls {
                if let fileType = FileType(fileExtension: url.pathExtension) {
                    //通过后缀名识别到了文件类型
                    switch fileType {
                    case .game:
                        group.enter()
                        let isCueOrGdi = url.pathExtension.lowercased() == "cue" || (url.pathExtension.lowercased() == "gdi")
                        let isMultiFiles = isCueOrGdi || (url.pathExtension.lowercased() == "m3u")
                        let multiFileRoms = (isCueOrGdi ? m3uResultMultiFileItems : m3uResultM3uItems)
                        let items = multiFileRoms.first(where: { $0.url == url })?.files ?? []
                        importGame(url: url, items: isMultiFiles ? items : []) { gameName, error in
                            if let error = error {
                                gameErrors.append(error)
                            }
                            if let gameName = gameName {
                                importGames.append(gameName)
                            }
                            group.leave()
                        }
                    case .gameSave:
                        //处理存档文件
                        group.enter()
                        importSave(url: url) { gameSaveName, error in
                            if let error = error {
                                gameSaveErrors.append(error)
                            }
                            if let gameSaveName = gameSaveName {
                                importGameSaves.append(gameSaveName)
                            }
                            group.leave()
                        }
                    case .skin:
                        group.enter()
                        importSkin(url: url) { skinName, error in
                            if let error = error {
                                skinErrors.append(error)
                            }
                            if let skinName = skinName {
                                importSkins.append(skinName)
                            }
                            group.leave()
                        }
                    default:
                        break
                    }
                } else {
                    //无法识别文件类型 基本不会发生，除非UIDocumentPickerViewController有bug
                    group.enter()
                    errors.append(.noPermission(fileUrl: url))
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                UIView.hideLoading()
                if silentMode {
                    importCompletion?()
                    return
                }
                //先处理gameSave的错误
                ErrorHandler.shared.handleErrors(gameSaveErrors) { error in
                    switch error {
                    case .saveNoMatchGames(_), .saveAlreadyExist(_, _), .saveMatchToMuch(_, _):
                        return true
                    default:
                        return false
                    }
                } handleAction: { error, actionCompletion in
                    if Database.realm.objects(Game.self).where({ !$0.isDeleted }).count == 0 {
                        //没有游戏
                        switch error {
                        case .saveNoMatchGames(let url), .saveMatchToMuch(let url, _):
                            UIView.makeAlert(title: R.string.localizable.importErrorTitle(),
                                             detail: R.string.localizable.importGameSaveFailedNoGameError(url.lastPathComponent), hideAction: {
                                actionCompletion()
                            })
                        default:
                            actionCompletion()
                        }
                    } else {
                        switch error {
                        case .saveNoMatchGames(let url):

                            GameSaveMatchGameView.show(gameSaveUrl: url,
                                                       title: R.string.localizable.gameSaveMatchTitle(),
                                                       detail: error.localizedDescription,
                                                       cancelTitle: R.string.localizable.cancelTitle()) {
                                actionCompletion()
                            }
                        case .saveAlreadyExist(let url, let game):
                            UIView.makeAlert(title: R.string.localizable.gameSaveAlreadyExistTitle(),
                                             detail: error.localizedDescription,
                                             confirmTitle: R.string.localizable.confirmTitle(),
                                             enableForceHide: false,
                                             confirmAction: {
                                try? FileManager.safeCopyItem(at: url, to: game.gameSaveUrl, shouldReplace: true)
                                SyncManager.upload(localFilePath: game.gameSaveUrl.path)
                                actionCompletion()
                            })
                        case .saveMatchToMuch(let url, let games):
                            GameSaveMatchGameView.show(gameSaveUrl: url,
                                                       showGames: games,
                                                       title: R.string.localizable.gameSaveMathToMuchTitle(),
                                                       detail: error.localizedDescription,
                                                       cancelTitle: R.string.localizable.cancelTitle()) {
                                actionCompletion()
                            }
                        default:
                            actionCompletion()
                        }
                    }
                } completion: { unhandledErrors in
                    func handleImportSuccess() {
                        if importGames.count > 0 && importSkins.count == 0 && importGameSaves.count == 0 {
                            //判断一下gameType是否是未知
                            let realm = Database.realm
                            let group = DispatchGroup()
                            for importGame in importGames {
                                if let game = realm.objects(Game.self).first(where: { ($0.aliasName == importGame || $0.name == importGame) && $0.gameType == .unknown }) {
                                    //弹窗要求用户进行平台选择
                                    group.enter()
                                    PlatformSelectionView.show(game: game, cancelEnable: false) {
                                        group.leave()
                                    }
                                }
                            }
                            
                            group.notify(queue: .main) {
                                //导入游戏成功
                                if let home = topViewController(appController: true) as? HomeViewController, home.homeTabBar.currentSelection == .games {
                                    UIView.makeToast(message: R.string.localizable.importGameSuccessTitle())
                                } else {
                                    let detail: String
                                    let confirmTitle: String
                                    if importGames.count == 1 {
                                        detail = R.string.localizable.importGameSuccessDetailForOne(String.successMessage(from: importGames))
                                        confirmTitle = R.string.localizable.startGameTitle()
                                    } else {
                                        detail = R.string.localizable.importGameSuccessDetail(String.successMessage(from: importGames))
                                        confirmTitle =  R.string.localizable.checkTitle()
                                    }
                                    
                                    UIView.makeAlert(title: R.string.localizable.importGameSuccessTitle(),
                                                     detail: detail,
                                                     confirmTitle: confirmTitle,
                                                     confirmAction: {
                                        UIView.hideAllAlert {
                                            if importGames.count == 1 {
                                                startGame(gameName: importGames.first!)
                                            } else {
                                                NotificationCenter.default.post(name: Constants.NotificationName.HomeSelectionChange, object: HomeTabBar.BarSelection.games)
                                            }
                                        }
                                    })
                                }
                            }

                            
                        } else if importSkins.count > 0 && importGames.count == 0 && importGameSaves.count == 0 {
                            if let topVC = topViewController(appController: true), (topVC is SkinSettingsViewController || topVC is WebViewController) {
                                UIView.makeToast(message: R.string.localizable.importSkinSuccessTitle())
                            } else {
                                //导入皮肤成功
                                UIView.makeAlert(title: R.string.localizable.importSkinSuccessTitle(),
                                                 detail: R.string.localizable.importSkinSuccessDetail(String.successMessage(from: importSkins)),
                                                 confirmTitle: R.string.localizable.checkTitle(),
                                                 confirmAction: {
                                    UIView.hideAllAlert {
                                        let vc: SkinSettingsViewController
                                        if importSkins.count == 1 {
                                            let skinName = importSkins.first!
                                            if let gameType = Database.realm.objects(Skin.self).first(where: { $0.name == skinName })?.gameType {
                                                vc = SkinSettingsViewController(gameType: gameType)
                                            } else {
                                                vc = SkinSettingsViewController()
                                            }
                                        } else {
                                            vc = SkinSettingsViewController()
                                        }
                                        //可能alert还没完全隐藏 会导致异常
                                        DispatchQueue.main.asyncAfter(delay: 0.15) {
                                            topViewController()?.present(vc, animated: true)
                                        }
                                    }
                                })
                            }
                        } else if importGameSaves.count > 0 && importGames.count == 0 && importSkins.count == 0 {
                            //导入存档成功
                            let detail: String
                            var confirmTitle: String? = nil
                            if importGameSaves.count == 1 {
                                detail = R.string.localizable.importGameSaveSuccessForOne(String.successMessage(from: importGameSaves))
                                confirmTitle = R.string.localizable.startGameTitle()
                            } else {
                                detail = R.string.localizable.importGameSaveSuccessDetail(String.successMessage(from: importGameSaves))
                            }
                            UIView.makeAlert(title: R.string.localizable.importGameSaveSuccessTitle(),
                                             detail: detail,
                                             confirmTitle: confirmTitle,
                                             confirmAction: {
                                UIView.hideAllAlert {
                                    startGame(gameName: importGameSaves.first!)
                                }
                            })
                        } else if importGameSaves.count > 0 || importGames.count > 0 || importSkins.count > 0 {
                            //导入多种资源成功
                            UIView.makeToast(message: R.string.localizable.alertImportFilesSuccess())
                        }
                    }
                    
                    errors.append(contentsOf: unhandledErrors)
                    errors.append(contentsOf: gameErrors)
                    errors.append(contentsOf: skinErrors)
                    if errors.count > 0 {
                        UIView.makeAlert(title: R.string.localizable.importErrorTitle(),
                                         detail: String.errorMessage(from: errors),
                                         cancelTitle: R.string.localizable.confirmTitle(),
                                         hideAction: {
                            handleImportSuccess()
                        })
                    } else {
                        handleImportSuccess()
                    }
                    importCompletion?()
                }
            }
        }
    }
    
    private static func startGame(gameName: String) {
        let realm = Database.realm
        if let game = realm.objects(Game.self).first(where: {
            if $0.gameType == ._3ds {
                return $0.aliasName == gameName
            } else {
                return $0.name == gameName
            }
        }) {
            if Settings.defalut.quickGame {
                PlayViewController.startGame(game: game)
            } else {
                topViewController(appController: true)?.present(GameInfoViewController(game: game), animated: true)
            }
        }
    }
    
    class ErrorHandler {
        static let shared = ErrorHandler()
        // 处理错误主方法
        func handleErrors(_ errors: [ImportError],
                          shouldHandle: @escaping (_ error: ImportError)->Bool,
                          handleAction: @escaping (_ error: ImportError, _ actionCompletion: @escaping ()->Void)->Void,
                          completion: @escaping (_ unhandledErrors: [ImportError]) -> Void) {
            var unhandledErrors = [ImportError]()
            var currentIndex = 0
            
            // 递归处理方法
            func processNext() {
                guard currentIndex < errors.count else {
                    completion(unhandledErrors)
                    return
                }
                
                let error = errors[currentIndex]
                currentIndex += 1
                
                if shouldHandle(error) {
                    // 需要处理的错误
                    handleAction(error) {
                        // 继续处理下一个
                        processNext()
                    }
                } else {
                    // 直接收集不需要处理的错误
                    unhandledErrors.append(error)
                    processNext()
                }
            }
            
            processNext()
        }
    }
    
    private static func importGame(url: URL, items: [URL] = [], completion: ((_ gameName: String?, _ error: ImportError?)->Void)?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let realm = Database.realm
            var ciaTitleUrl: URL? = nil
            let originalUrl = url
#if !targetEnvironment(simulator)
            var url = url
            var threeDSGameInfo: ThreeDSGameInformation? = nil
            if FileType.get3DSExtensions().contains([url.pathExtension]) {
                if url.pathExtension.lowercased() == "cia" {
                    Log.debug("开始安装")
                    let status = ThreeDSCore.shared.importGame(at: url)
                    let ciaInfo = ThreeDSCore.shared.getCIAInfo(url: url)
                    if let titlePath = ciaInfo.titlePath {
                        ciaTitleUrl = URL(fileURLWithPath: titlePath)
                    }
                    guard let ciaPath = ciaInfo.contentPath else {
                        Log.debug("安装CIA出错，无法获取CIA的安装路径")
                        Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                        completion?(nil, .badFile(fileName: url.lastPathComponent.deletingPathExtension))
                        return
                    }
                    
                    switch status {
                    case .success:
                        Log.debug("游戏安装目录:\(ciaPath)")
                        if ciaPath.contains("/00040000/") {
                            //游戏本体
                            url = URL(fileURLWithPath: ciaPath)
                        } else {
                            UIView.makeToast(message: R.string.localizable.threeDSUpdateInstallSuccess(), identifier: "threeDSUpdateInstallSuccess")
                            completion?(nil, nil)
                            return
                        }
                    case .errorEncrypted:
                        Log.debug("CIA加密了")
                        Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                        completion?(nil, .decryptFailed(fileName: url.lastPathComponent))
                        return
                    default:
                        Log.debug("CIA安装失败")
                        Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                        completion?(nil, .badFile(fileName: url.lastPathComponent))
                        return
                    }
                }
                if let gameInfo = ThreeDSCore.shared.information(for: url) {
                    Log.debug("获取游戏信息 identifier:\(gameInfo.identifier) title:\(gameInfo.title)")
                    threeDSGameInfo = gameInfo
                } else {
                    Log.debug("无法获取3DS ROM信息")
                    Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                    completion?(nil, .badFile(fileName: url.lastPathComponent))
                    return
                }
            }
#endif
            
            if let hash = FileHashUtil.truncatedHash(url: url) {
                if let game = realm.object(ofType: Game.self, forPrimaryKey: hash) {
                    //游戏已经存在于数据库中
                    if game.isRomExtsts {
                        //游戏文件也存在
                        Log.debug("导入游戏失败，游戏已经存在数据库")
                        completion?(nil, .fileExist(fileName: url.lastPathComponent))
                        return
                    } else {
                        do {
                            if items.count > 0 {
                                //可能是m3u或者cue或者gdi
                                let romUrl = game.romUrl
                                let romParentPath = romUrl.path.deletingLastPathComponent
                                try FileManager.safeCopyItem(at: url, to: romUrl, shouldReplace: true)
                                for item in items {
                                    try FileManager.safeCopyItem(at: item, to: URL(fileURLWithPath: romParentPath.appendingPathComponent(item.lastPathComponent)), shouldReplace: true)
                                }
                            } else {
                                try FileManager.safeCopyItem(at: url, to: game.romUrl, shouldReplace: true)
                                //文件复制成功
                                completion?(game.name, nil)
                                return
                            }
                        } catch {
                            //复制文件出错
                            Log.debug("导入游戏失败，数据库存在 但是文件不存在 复制失败:\(error)")
                            completion?(nil, .badCopy(fileName: game.name))
                            return
                        }
                    }
                } else {
                    //游戏不存在 创建游戏
                    let game = Game()
                    game.id = hash
                    game.name = originalUrl.deletingPathExtension().lastPathComponent
                    game.fileExtension = url.pathExtension
                    
#if !targetEnvironment(simulator)
                    if let threeDSGameInfo {
                        //读取3DS信息
                        game.extras = ["identifier": threeDSGameInfo.identifier, "regions": threeDSGameInfo.regions].jsonData()
                        if !threeDSGameInfo.title.isEmpty {
                            game.aliasName = threeDSGameInfo.title
                        }
                    }
#endif
                    let gameType = GameType(fileExtension: game.fileExtension)
                    if gameType != .notSupport {
                        game.gameType = gameType
                        game.importDate = Date()
                        do {
                            if ciaTitleUrl == nil {
                                //cia格式的3DS不需要拷贝了 因为已经安装进游戏目录了
                                if items.count > 0 {
                                    //可能是m3u或者cue或者gdi
                                    let romUrl = game.romUrl
                                    let romParentPath = romUrl.path.deletingLastPathComponent
                                    try FileManager.safeCopyItem(at: url, to: romUrl, shouldReplace: true)
                                    for item in items {
                                        try FileManager.safeCopyItem(at: item, to: URL(fileURLWithPath: romParentPath.appendingPathComponent(item.lastPathComponent)), shouldReplace: true)
                                    }
                                } else {
                                    try FileManager.safeCopyItem(at: url, to: game.romUrl, shouldReplace: true)
                                }
                            }
                            do {
                                try realm.write { realm.add(game) }
                                SyncManager.upload(localFilePath: game.romUrl.path)
                                OnlineCoverManager.shared.addCoverMatch(OnlineCoverManager.CoverMatch(game: game))
                                completion?(game.gameType == ._3ds ? (game.aliasName ?? game.name) : game.name, nil)
                                return
                            } catch {
                                //写入数据失败
                                Log.debug("导入游戏失败，写入数据库失败:\(error)")
                                if let ciaTitleUrl {
                                    try? FileManager.safeRemoveItem(at: ciaTitleUrl)
                                }
                                completion?(nil, .writeDatabase(fileName: game.name))
                                return
                            }
                        } catch {
                            //复制文件失败
                            Log.debug("导入游戏失败，复制失败:\(error)")
                            if let ciaTitleUrl {
                                try? FileManager.safeRemoveItem(at: ciaTitleUrl)
                            }
                            completion?(nil, .badCopy(fileName: game.name))
                            return
                        }
                    } else {
                        //无法识别文件类型
                        Log.debug("导入游戏失败，后缀不正确\(game.fileName)")
                        Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                        completion?(nil, .badExtension(fileName: game.name))
                        return
                    }
                }
            } else {
                //无法计算文件哈希
                Log.debug("导入游戏失败，无法计算文件哈希")
                Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                completion?(nil, .badFile(fileName: url.lastPathComponent))
                return
            }
        }
    }
    
    private static func removeCIA(ciaTitleUrl: URL?) {
        if let ciaTitleUrl {
            try? FileManager.safeRemoveItem(at: ciaTitleUrl)
        }
    }
    
    private static func importSave(url: URL, completion: ((_ gameName: String?, _ error: ImportError?)->Void)?) {
        DispatchQueue.global().async {
            if url.path.contains(".3ds.sav") {
                handle3DSGameSave(url: url, completion: completion)
                return
            }
            
            if url.path.contains(".psp.sav") {
                handlePSPGameSave(url: url, completion: completion)
                return
            }
            
            let realm = Database.realm
            let fileExtension = url.pathExtension
            let fileName = url.deletingPathExtension().lastPathComponent
            var games: Results<Game>
            if let gameType = GameType(saveFileExtension: fileExtension) {
                games = realm.objects(Game.self).where { $0.name == fileName && $0.gameType == gameType && !$0.isDeleted }
            } else {
                games = realm.objects(Game.self).where { $0.name == fileName && !$0.isDeleted }
            }
            if games.count == 0 {
                //该存档没有匹配到游戏
                completion?(nil, .saveNoMatchGames(gameSaveUrl: url))
                return
            } else if games.count == 1 {
                //匹配到游戏了
                //注意这个game带到别的线程使用会报错
                let game = games.first!
                if game.isSaveExtsts {
                    //匹配的游戏的存档也存在了 不再复制
                    //要将realm对象传输出去 最好搞到主线程上
                    let ref = ThreadSafeReference(to: game)
                    DispatchQueue.main.async {
                        let realm = Database.realm
                        if let game = realm.resolve(ref) {
                            completion?(nil, .saveAlreadyExist(gameSaveUrl: url, game: game))
                        }
                    }
                    return
                } else {
                    //匹配的游戏还没有存档 开始复制
                    do {
                        try FileManager.safeCopyItem(at: url, to: game.gameSaveUrl)
                        SyncManager.upload(localFilePath: game.gameSaveUrl.path)
                        completion?(game.name, nil)
                        return
                    } catch {
                        completion?(nil, .badCopy(fileName: "\(url.lastPathComponent)"))
                        return
                    }
                }
            } else if games.count > 0 {
                //要将realm对象传输出去 最好搞到主线程上
                let ref = ThreadSafeReference(to: games)
                DispatchQueue.main.async {
                    let realm = Database.realm
                    if let games = realm.resolve(ref) {
                        completion?(nil, .saveMatchToMuch(gameSaveUrl: url, games: games.map { $0 }))
                    }
                }
                return
            }
        }
    }
    
    private static func importSkin(url: URL, completion: ((_ skinName: String?, _ error: ImportError?)->Void)?) {
        DispatchQueue.global().async {
            if let controllerSkin = ControllerSkin(fileURL: url) {
                if let hash = FileHashUtil.truncatedHash(url: url) {
                    let realm = Database.realm
                    if let skin = realm.object(ofType: Skin.self, forPrimaryKey: hash) {
                        //skin数据库已经存在
                        if skin.isFileExtsts {
                            //skin文件也存在
                            completion?(nil, .fileExist(fileName: skin.fileName))
                            return
                        } else {
                            //skin文件不存在
                            do {
                                //复制成功
                                try FileManager.safeCopyItem(at: url, to: skin.fileURL, shouldReplace: true)
                                completion?(skin.name, nil)
                                return
                            } catch {
                                //复制失败
                                completion?(nil, .badCopy(fileName: skin.fileName))
                                return
                            }
                        }
                    } else if realm.objects(Skin.self).where({ $0.identifier == controllerSkin.identifier }).count > 0 {
                        //identifier冲突了
                        completion?(nil, .skinIdentifierConflict(identifier: controllerSkin.identifier))
                        return
                    } else {
                        //数据库skin不存在
                        let skin = Skin()
                        skin.id = hash
                        skin.identifier = controllerSkin.identifier
                        skin.name = controllerSkin.name
                        skin.fileName = url.lastPathComponent
                        skin.gameType = controllerSkin.gameType
                        skin.skinType = .import
                        skin.skinData = CreamAsset.create(objectID: skin.id, propName: "skinData", url: url)
                        do {
                            try realm.write {
                                realm.add(skin)
                            }
                            SyncManager.upload(localFilePath: skin.fileURL.path)
                            completion?(skin.name, nil)
                            return
                        } catch {
                            completion?(nil, .writeDatabase(fileName: skin.fileName))
                            return
                        }
                    }
                } else {
                    completion?(nil, .noPermission(fileUrl: url))
                    return
                }
            } else {
                //皮肤文件有问题
                completion?(nil, .skinBadFile(fileName: url.lastPathComponent))
                return
            }
        }
    }
    
    static func handleZip(urls: [URL], silentMode: Bool, completion: @escaping ([URL])->Void) {
        DispatchQueue.global().async {
            var results = [URL]()
            for url in urls {
                if FileType.zip.extensions.contains(url.pathExtension) {
                    var innerResults = [URL]()
                    if url.pathExtension.lowercased() == "zip" {
                        //先检查zip里面有没有支持的文件类型
                        if SSZipArchive.isFilePasswordProtected(atPath: url.path) {
                            //加密文件先不处理
                            if !silentMode {
                                UIView.makeToast(message: R.string.localizable.notSupportPasswordZip(url.lastPathComponent))
                            }
                            continue
                        } else {
                            //未加密
                            if let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) {
                                for entry in archive {
                                    if entry.type == .file, let _ = FileType(fileExtension: entry.path.pathExtension) {
                                        if entry.path.lastPathComponent.hasPrefix(".") {
                                            //跳过隐藏文件夹
                                            continue
                                        }
                                        do {
                                            let dstPath = Constants.Path.ZipWorkSpace.appendingPathComponent(entry.decodedPath)
                                            let destUrl = URL(fileURLWithPath: dstPath)
                                            if FileManager.default.fileExists(atPath: dstPath) {
                                                try FileManager.safeRemoveItem(at: destUrl)
                                            }
                                            _ = try archive.extract(entry, to: destUrl)
                                            innerResults.append(destUrl)
                                        } catch {
                                            if !silentMode {
                                                UIView.makeToast(message: R.string.localizable.unzipFailed(entry.path.lastPathComponent))
                                            }
                                        }
                                    }
                                }
                                results.append(contentsOf: innerResults)
                            } else {
                                if !silentMode {
                                    UIView.makeToast(message: R.string.localizable.unzipFailed(url.lastPathComponent))
                                }
                                continue
                            }
                        }
                    } else if url.pathExtension.lowercased() == "7z"  {
                        do {
                            Log.debug("开始解压7z")
                            let archivePath = try Path(url.path)
                            let archivePathInStream = try InStream(path: archivePath)
                            let decoder = try Decoder(stream: archivePathInStream, fileType: .sevenZ)
                            let _ = try decoder.open()
                            let numberOfArchiveItems = try decoder.count()
                            for itemIndex in 0..<numberOfArchiveItems {
                                let item = try decoder.item(at: itemIndex)
                                if item.isDir {
                                    continue
                                }
                                let path = try item.path().description
                                if path.lastPathComponent.hasPrefix(".") {
                                    //跳过隐藏文件夹
                                    continue
                                }
                                let itemArray = try ItemArray(capacity: 1)
                                if let _ = FileType(fileExtension: path.pathExtension) {
                                    try itemArray.add(item: item)
                                } else {
                                    continue
                                }
                                let dstPath = Constants.Path.ZipWorkSpace.appendingPathComponent(path)
                                Log.debug("构建路径:\(dstPath)")
                                let destUrl = URL(fileURLWithPath: dstPath)
                                if FileManager.default.fileExists(atPath: dstPath) {
                                    try FileManager.safeRemoveItem(at: destUrl)
                                }
                                if !FileManager.default.fileExists(atPath: dstPath.deletingLastPathComponent) {
                                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: dstPath.deletingLastPathComponent), withIntermediateDirectories: true)
                                }
                                let _ = try decoder.extract(items: itemArray, to: Path(Constants.Path.ZipWorkSpace))
                                Log.debug("解压成功!")
                                innerResults.append(destUrl)
                            }
                            results.append(contentsOf: innerResults)
                        } catch {
                            Log.debug("解压7z失败:\(error)")
                            UIView.makeToast(message: R.string.localizable.sevenZipDecompressError())
                        }
                    }
                    if innerResults.isEmpty {
                        if !silentMode {
                            UIView.makeToast(message: R.string.localizable.noSupportInZip(url.lastPathComponent))
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
    static func handle3DSGameSave(url: URL, completion: ((_ gameName: String?, _ error: ImportError?)->Void)?) {
        if let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) {
            var isValid = false
            for entry in archive {
                if entry.type == .file, entry.path.hasPrefix("sdmc") {
                    isValid = true
                    break
                }
            }

            guard isValid else {
                UIView.makeToast(message: R.string.localizable.threeDSImportSaveFailed(url.lastPathComponent))
                completion?(nil, nil)
                return
            }

            var isSaveExist = false
            for entry in archive {
                if entry.type == .file {
                    let savePath = Constants.Path.ThreeDS.appendingPathComponent(entry.path)
                    if FileManager.default.fileExists(atPath: savePath) {
                        isSaveExist = true
                        break
                    }
                }
            }
            
            func extractSaveFiles() {
                for entry in archive {
                    if entry.type == .file && entry.path.hasPrefix("sdmc") {
                        let savePath = Constants.Path.ThreeDS.appendingPathComponent(entry.path)
                        if FileManager.default.fileExists(atPath: savePath) {
                            try? FileManager.default.removeItem(atPath: savePath)
                        }
                        let _ = try? archive.extract(entry, to: URL(fileURLWithPath: savePath))
                    }
                }
            }
            
            if isSaveExist {
                //询问是否覆盖
                UIView.makeAlert(title: R.string.localizable.gameSaveAlreadyExistTitle(),
                                 detail: R.string.localizable.filesImporterErrorSaveAlreadyExist(url.lastPathComponent),
                                 confirmTitle: R.string.localizable.confirmTitle(),
                                 enableForceHide: false,
                                 confirmAction: {
                    extractSaveFiles()
                    UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle(), identifier: "importGameSaveSuccessTitle")
                })
                completion?(nil, nil)
            } else {
                //直接解压
                extractSaveFiles()
                UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle(), identifier: "importGameSaveSuccessTitle")
                completion?(nil, nil)
            }
        } else {
            UIView.makeToast(message: R.string.localizable.threeDSImportSaveFailed(url.lastPathComponent))
            completion?(nil, nil)
        }
    }
    
    static func handlePSPGameSave(url: URL, completion: ((_ gameName: String?, _ error: ImportError?)->Void)?) {
        if let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) {
            var isSaveExist = false
            for entry in archive {
                if entry.type == .file {
                    let realPath = entry.path.components(separatedBy: "/")[1...].reduce("") { $0 + "/" + $1 }
                    let savePath = Constants.Path.PSPSave.appendingPathComponent(realPath)
                    if FileManager.default.fileExists(atPath: savePath) {
                        isSaveExist = true
                        break
                    }
                }
            }
            
            func extractSaveFiles() {
                for entry in archive {
                    if entry.type == .file {
                        let realPath = entry.path.components(separatedBy: "/")[1...].reduce("") { $0 + "/" + $1 }
                        let savePath = Constants.Path.PSPSave.appendingPathComponent(realPath)
                        if FileManager.default.fileExists(atPath: savePath) {
                            try? FileManager.default.removeItem(atPath: savePath)
                        }
                        let _ = try? archive.extract(entry, to: URL(fileURLWithPath: savePath))
                    }
                }
            }
            
            if isSaveExist {
                //询问是否覆盖
                UIView.makeAlert(title: R.string.localizable.gameSaveAlreadyExistTitle(),
                                 detail: R.string.localizable.filesImporterErrorSaveAlreadyExist(url.lastPathComponent),
                                 confirmTitle: R.string.localizable.confirmTitle(),
                                 enableForceHide: false,
                                 confirmAction: {
                    extractSaveFiles()
                    UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle(), identifier: "importGameSaveSuccessTitle")
                })
                completion?(nil, nil)
            } else {
                //直接解压
                extractSaveFiles()
                UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle(), identifier: "importGameSaveSuccessTitle")
                completion?(nil, nil)
            }
        } else {
            UIView.makeToast(message: R.string.localizable.threeDSImportSaveFailed(url.lastPathComponent))
            completion?(nil, nil)
        }
    }
    
    static func handleM3uFiles(urls: [URL], multiFileItems: [MultiFileRom]) -> (result: [URL], errors: [ImportError], m3uItems: [MultiFileRom], multiFileItems: [MultiFileRom]) {
        var resultUrls = [URL]()
        var resultM3uItems = [MultiFileRom]()
        var resultErrors = [ImportError]()
        
        var excludeUrls = [URL]()
        var excludeMultiFiles = [MultiFileRom]()
        for url in urls {
            if url.pathExtension.lowercased() == "m3u" {
                if let content = try? String(contentsOf: url) {
                    var isBadM3u = false
                    var missFileName = ""
                    var m3uFiles = [URL]()
                    let fileNames = content.components(separatedBy: .newlines).filter({ !$0.isEmpty })
                    guard fileNames.count > 0 else {
                        resultErrors.append(.badCopy(fileName: url.lastPathComponent))
                        continue
                    }
                    for fileName in fileNames {
                        //读取m3u的每一行
                        if !fileName.isEmpty {
                            //查询这个文件是否存在
                            if let fileUrl = urls.first(where: { $0.lastPathComponent == fileName}) {
                                if fileUrl.pathExtension.lowercased() == "cue" {
                                    //cue文件则从cueItems中进行判断
                                    if let cue = multiFileItems.first(where: { $0.url.lastPathComponent == fileName }) {
                                        //cue文件存在 则排除这个cue
                                        excludeMultiFiles.append(cue)
                                        excludeUrls.append(cue.url)
                                        m3uFiles.append(cue.url)
                                        m3uFiles.append(contentsOf: cue.files)
                                    } else {
                                        //m3u中的不包含这个cue文件 说明这个m3u不合法，文件有缺失 则不导入这个m3u文件，并且将m3u中的其他文件也一并排除
                                        isBadM3u = true
                                        missFileName = fileName
                                    }
                                } else {
                                    //文件存在 则将这个文件排除，不再需要导入
                                    excludeUrls.append(fileUrl)
                                    m3uFiles.append(fileUrl)
                                }

                            } else {
                                //m3u中的文件不存在 说明这个m3u不合法，文件有缺失 则不导入这个m3u文件，并且将m3u中的其他文件也一并排除
                                isBadM3u = true
                                missFileName = fileName
                                break
                            }
                        }
                    }
                    if isBadM3u {
                        //排除错误文件
                        excludeUrls.append(url)
                        for fileName in fileNames {
                            if fileName.pathExtension.lowercased() == "cue" {
                                excludeMultiFiles.append(contentsOf: multiFileItems.filter({ $0.url.lastPathComponent == fileName }))
                            } else {
                                excludeUrls.append(contentsOf: urls.filter({ $0.lastPathComponent == fileName }))
                            }
                        }
                        resultErrors.append(.missingFile(errorFileName: url.lastPathComponent, missingFileName: missFileName))
                    } else {
                        //m3u文件合法
                        resultUrls.append(url)
                        resultM3uItems.append(MultiFileRom(url: url, files: m3uFiles))
                    }
                } else {
                    //无法读取m3u文件
                    resultErrors.append(.badFile(fileName: url.lastPathComponent))
                }
            } else {
                resultUrls.append(url)
            }
        }
        
        //排除m3u的files
        resultUrls.removeAll(where: { excludeUrls.contains([$0]) })
        
        let resultCueItems = multiFileItems.filter { originCue in
            if excludeMultiFiles.contains(where: { $0.url == originCue.url }) {
                return false
            }
            return true
        }
        
        return (resultUrls, resultErrors, resultM3uItems, resultCueItems)
    }
    
    fileprivate static func extractCueFilenames(from cueContent: String) -> [String] {
        let pattern = #"FILE\s+"([^"]+)""#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsString = cueContent as NSString
        let matches = regex.matches(in: cueContent, options: [], range: NSRange(location: 0, length: nsString.length))
        
        return matches.map { match in
            nsString.substring(with: match.range(at: 1))
        }
    }
    
    fileprivate static func extractGdiFilenames(from content: String) -> [String] {
        var filenames: [String] = []
        
        let lines = content.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // 第一行是文件总数，跳过
        for line in lines.dropFirst() {
            let components = line.split(separator: " ")
            if components.count >= 2 {
                let filename = components[components.count - 2] // 倒数第二列才是文件名
                filenames.append(String(filename))
            }
        }
        
        return filenames
    }
    
    static func handleMultiFiles(urls: [URL]) -> (results: [URL], errors: [ImportError], cueItems: [MultiFileRom]) {
        var results = [URL]()
        var excludes = [URL]()
        var errors = [ImportError]()
        var cueItems = [MultiFileRom]()
        for url in urls {
            if url.pathExtension.lowercased() == "cue" || url.pathExtension.lowercased() == "gdi" {
                if let content = try? String(contentsOf: url) {
                    let isCue = url.pathExtension.lowercased() == "cue"
                    var isBadFile = false
                    var missFileName = ""
                    var multiFiles = [URL]()
                    let fileNames = isCue ? extractCueFilenames(from: content) : extractGdiFilenames(from: content)
                    guard fileNames.count > 0 else {
                        errors.append(.badMultiFile(fileName: url.lastPathComponent))
                        continue
                    }
                    for fileName in fileNames {
                        //读取每一个文件
                        if !fileName.isEmpty {
                            //查询这个文件是否存在
                            if let fileUrl = urls.first(where: { $0.lastPathComponent == fileName}) {
                                //文件存在 则将这个文件排除，不再需要导入
                                excludes.append(fileUrl)
                                multiFiles.append(fileUrl)
                            } else {
                                //文件不存在 说明这个多文件格式不合法，文件有缺失 则不导入这个文件，并且将其他文件也一并排除
                                isBadFile = true
                                missFileName = fileName
                                break
                            }
                        }
                    }
                    if isBadFile {
                        //排除错误文件
                        excludes.append(url)
                        for fileName in fileNames {
                            excludes.append(contentsOf: urls.filter({ $0.lastPathComponent == fileName }))
                        }
                        errors.append(.missingFile(errorFileName: url.lastPathComponent, missingFileName: missFileName))
                    } else {
                        //cue文件合法
                        results.append(url)
                        cueItems.append(MultiFileRom(url: url, files: multiFiles))
                    }
                } else {
                    //无法读取cue文件
                    errors.append(.badMultiFile(fileName: url.lastPathComponent))
                }
            } else {
                results.append(url)
            }
        }
        
        //排除files
        results.removeAll(where: { excludes.contains([$0]) })
        
        return (results, errors, cueItems)
    }
}

struct MultiFileRom {
    var url: URL
    var files: [URL]
}
