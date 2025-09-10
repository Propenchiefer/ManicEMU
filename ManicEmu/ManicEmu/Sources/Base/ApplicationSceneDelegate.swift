//
//  ApplicationSceneDelegate.swift
//  testScene
//
//  Created by Aoshuang Lee on 2024/12/26.
//

import UIKit
import OAuthSwift
import UniformTypeIdentifiers
import ManicEmuCore

class ApplicationSceneDelegate: UIResponder, UIWindowSceneDelegate {
    static weak var applicationScene: UIWindowScene?
    static weak var applicationWindow: UIWindow?
    var window: UIWindow?
    static var launchGameID: String? = nil

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            ApplicationSceneDelegate.applicationScene = windowScene
            window = UIWindow(windowScene: windowScene)
            ApplicationSceneDelegate.applicationWindow = window
            window?.tintColor = Constants.Color.Main
            //初始化数据库
            ResourcesKit.loadResources { isSuccess in
                Database.setup {
                    ThemeManager.shared.setup()
                    self.window?.rootViewController = HomeViewController()
                    self.window?.makeKeyAndVisible()
                    if Settings.defalut.iCloudSyncEnable {
                        SyncManager.shared.startSync()
                    }
                    
                    if !isSuccess {
                        UIView.makeAlert(title: R.string.localizable.fatalErrorTitle(), detail: R.string.localizable.fatalErrorDesc(), cancelTitle: R.string.localizable.confirmTitle())
                    }
                    if connectionOptions.urlContexts.count > 0 {
                        self.scene(scene, openURLContexts: connectionOptions.urlContexts)
                    }
                    
                    //设置控制器死区配置
                    ExternalGameControllerUtils.shared.deadZone = Settings.defalut.getExtraFloat(key: ExtraKey.deadZone.rawValue) ?? 0
                    
                    //设置RetroAchievement
                    CheevosBridge.setup(with: Constants.Config.AppVersion, requireCredentials: {
                        if let user = AchievementsUser.getUser() {
                            let cheevosUser = CheevosUser()
                            cheevosUser.userName = user.username
                            cheevosUser.password = user.password
                            cheevosUser.token = user.token
                            return cheevosUser
                        }                        
                        return nil
                    }, updateCredentials: { cheevosUser in
                        if let u = cheevosUser?.userName,
                           let p = cheevosUser?.password,
                           let t = cheevosUser?.token {
                            AchievementsUser.updateUser(username: u, password: p, token: t)
                        }
                    })
                }
            }
            let dropInteraction = UIDropInteraction(delegate: self)
            window?.addInteraction(dropInteraction)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for URLContext in URLContexts {
            let url = URLContext.url
            Log.debug("openURLContexts 回调URL:\(url)")
            if let scheme = url.scheme {
                if scheme == Constants.Strings.OAuthGoogleDriveCallbackHost ||
                    scheme == Constants.Strings.OAuthCallbackHost ||
                    scheme == Constants.Strings.OAuthOneDriveCallbackHost {
                    Log.debug("OAuth鉴权回调")
                    OAuthSwift.handle(url: url)
                } else if scheme == Constants.Strings.ManicScheme {
                    Self.launchGameID = url.lastPathComponent
                }
            }
        }
        
        if let launchGameID = Self.launchGameID, let window, let _ = window.rootViewController {
            //页面已经初始化好了，在这里处理, 如果没有初始化好，则交给GamesViewController处理
            Self.launchGameID = nil
            let realm = Database.realm
            if let game = realm.object(ofType: Game.self, forPrimaryKey: launchGameID) {
                PlayViewController.startGame(game: game)
            }
        }
        
        DispatchQueue.global().async {
            let allSupportExtentions = FileType.allSupportFileExtension()
            let fileUrls = URLContexts.map({ $0.url }).filter { $0.scheme == "file" && allSupportExtentions.contains([$0.pathExtension]) }
            if fileUrls.count > 0 {
                //先复制到本地 确保后续操作有足够权限
                var newFileUrls = [URL]()
                for fileUrl in fileUrls {
                    if #available(iOS 17.0, *) {
                        guard fileUrl.startAccessingSecurityScopedResource() else {
                            DispatchQueue.main.async {
                                UIView.makeToast(message: R.string.localizable.openFilePermissionsLimit(fileUrl.lastPathComponent))
                            }
                            continue
                        }
                    } else {
                        let _ = fileUrl.startAccessingSecurityScopedResource()
                    }
                    let newFileUrl = URL(fileURLWithPath: Constants.Path.Temp.appendingPathComponent(fileUrl.lastPathComponent))
                    do {
                        try FileManager.safeCopyItem(at: fileUrl, to: newFileUrl, shouldReplace: true)
                        newFileUrls.append(newFileUrl)
                    } catch {
                        DispatchQueue.main.async {
                            UIView.makeToast(message: R.string.localizable.openFilePermissionsLimit(fileUrl.lastPathComponent))
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(delay: 1.5) {
                    if newFileUrls.count > 0 {
                        FilesImporter.importFiles(urls: newFileUrls)
                    }
                }
            }
        }
    }
}

extension ApplicationSceneDelegate: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: any UIDropSession) {
        window?.showDropView()
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: any UIDropSession) -> Bool {
        if let _ = session.localDragSession {
            return false
        }
        return true
    }
    
    // 处理拖放操作
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        let allowedTypes = UTType.allTypes
        if session.hasItemsConforming(toTypeIdentifiers: allowedTypes.map({ $0.identifier })) {
            UIView.makeLoading()
            let dispatchGroup = DispatchGroup()
            var urls: [URL] = []
            var errors: [ImportError] = []
            let supportIdentifiers = allowedTypes.reduce("") { $0 + " " + $1.identifier }
            for item in session.items {
                let itemProvider = item.itemProvider
                var supportIdentifier: String? = nil
                //找出item支持的UTType的identifier
                for itemProviderIdentifier in itemProvider.registeredTypeIdentifiers {
                    if supportIdentifiers.contains(itemProviderIdentifier, caseSensitive: false) {
                        supportIdentifier = itemProviderIdentifier
                        break
                    }
                }

                if let supportIdentifier = supportIdentifier {
                    //找到了支持的类型
                    if let utType = UTType(supportIdentifier),
                        let extens = utType.tags[.filenameExtension]?.first,
                        let suggestedName = itemProvider.suggestedName {
                        //获取到文件名
                        let fileName = suggestedName + "." + extens
                        //将内容先复制到缓存目录中
                        let dstUrl = URL(fileURLWithPath: Constants.Path.DropWorkSpace.appendingPathComponent(fileName))
                        dispatchGroup.enter()
                        itemProvider.loadFileRepresentation(forTypeIdentifier: supportIdentifier) { url, error in
                            defer { dispatchGroup.leave() }
                            if let url = url {
                                do {
                                    try FileManager.safeCopyItem(at: url, to: dstUrl, shouldReplace: true)
                                    //复制成功
                                    urls.append(dstUrl)
                                } catch {
                                    //复制失败
                                    errors.append(.badCopy(fileName: fileName))
                                }
                            }
                        }
                    }
                }
            }
            
            // 所有操作完成后刷新UI
            dispatchGroup.notify(queue: .main) {
                if urls.count > 0 {
                    FilesImporter.importFiles(urls: urls, preErrors: errors)
                } else {
                    UIView.hideLoading()
                    UIView.makeToast(message: R.string.localizable.dropErrorLoadFailed())
                }
            }
        } else {
            UIView.makeToast(message: R.string.localizable.dropErrorNotSupportFile())
        }
    }
    
    // 设置拖放操作类型为复制
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: any UIDropSession) {
        window?.hideDropView()
    }
}
