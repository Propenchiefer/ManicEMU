//
//  ShareManager.swift
//  LandArt
//
//  Created by Aoshuang Lee on 2023/5/17.
//  Copyright © 2023 Aoshuang Lee. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import LinkPresentation
import ZIPFoundation
import UniformTypeIdentifiers

enum ShareFileType {
    case rom, save
}

/// 分享管理器包含了UIDocumentInteractionController和UIActivityViewController
/// 其中UIActivityViewController分享App 主要其实就是一个appstore的url
/// UIDocumentInteractionController分享文件 包括rom、save
class ShareManager: NSObject {
    private static let shared = ShareManager()
    private lazy var metadata: LPLinkMetadata = {
        //构建一个分享App的data
        let data = LPLinkMetadata()
        data.url = Constants.URLs.AppStoreUrl
        //标题
        data.title = Constants.Config.AppName
        //副标题
        data.originalURL = URL(fileURLWithPath: R.string.localizable.shareAppSubtitle())
        //展示的图标
        data.iconProvider = NSItemProvider(object: UIImage.placeHolder())
        return data
    }()
    private var documentInteractionController: UIDocumentInteractionController? = nil
}

extension ShareManager: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return metadata.url!
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return metadata.url
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return metadata
    }
    
    static func shareApp(senderForIpad: UIView? = nil) {
        let activityViewController = UIActivityViewController(activityItems: [ShareManager.shared], applicationActivities: nil)
        //分享App的链接
        activityViewController.excludedActivityTypes = [.saveToCameraRoll, .airDrop, .copyToPasteboard, .print]
        DispatchQueue.main.async {
            if let topVc = topViewController() {
                if let ppvc = activityViewController.popoverPresentationController {
                    ppvc.sourceView = senderForIpad
                }
                topVc.present(activityViewController, animated: true)
            }
        }
    }
}

extension ShareManager: UIDocumentInteractionControllerDelegate {
    static func shareFiles(games: [Game], shareFileType: ShareFileType) {
        guard games.count > 0 else {
            UIView.makeToast(message: {
                switch shareFileType {
                case .rom:
                    R.string.localizable.shareRomFilesFailed()
                case .save:
                    R.string.localizable.shareSaveFilesFailed()
                }
            }())
            
            return
        }
        
        if games.count == 1 {
            //单个文件分享
            let game = games.first!
            var url: URL
            var uti: String
            switch shareFileType {
            case .rom:
                if !game.isRomExtsts {
                    UIView.makeToast(message: R.string.localizable.shareRomFilesFailed())
                    return
                }
                url = game.romUrl
                uti = game.gameType.rawValue
            case .save:
                if !game.isSaveExtsts {
                    UIView.makeToast(message: R.string.localizable.shareSaveFilesFailed())
                    return
                }
                if game.gameType == ._3ds {
                    guard let newUrl = create3DSGameSave(urls: [game.name: game.gameSaveUrl]) else {
                        UIView.makeToast(message: R.string.localizable.shareSaveFilesFailed())
                        return
                    }
                    url = newUrl
                } else if game.gameType == .psp {
                    guard let newUrl = createPSPGameSave([game]) else {
                        UIView.makeToast(message: R.string.localizable.shareSaveFilesFailed())
                        return
                    }
                    url = newUrl
                } else {
                    url = game.gameSaveUrl
                }
                uti = "public.data"
            }
            let documentInteractionController = UIDocumentInteractionController()
            ShareManager.shared.documentInteractionController = documentInteractionController
            documentInteractionController.delegate = ShareManager.shared
            documentInteractionController.url = url
            documentInteractionController.uti = uti
            if let view = topViewController(appController: true)?.view {
                documentInteractionController.presentOptionsMenu(from: UIDevice.isPad ? .zero : view.frame, in: view, animated: true)
            }
        } else {
            //分享多个文件
            var urls: [URL] = []
            var zipWorkspaceName: String
            switch shareFileType {
            case .rom:
                urls.append(contentsOf: games.compactMap { $0.isRomExtsts ? $0.romUrl : nil })
                zipWorkspaceName = "Manic ROMs"
            case .save:
                var threeDSGameSaveUrls = [String: URL]()
                var pspGames = [Game]()
                for game in games {
                    if game.isSaveExtsts {
                        if game.gameType == ._3ds {
                            threeDSGameSaveUrls[game.name] = game.gameSaveUrl
                        } else if game.gameType == .psp {
                            pspGames.append(game)
                        } else {
                            urls.append(game.gameSaveUrl)
                        }
                    }
                }
                if threeDSGameSaveUrls.count > 0, let threeDSGameSaveUrl = create3DSGameSave(urls: threeDSGameSaveUrls) {
                    urls.append(threeDSGameSaveUrl)
                }
                if pspGames.count > 0, let pspSaveUrl = createPSPGameSave(pspGames) {
                    urls.append(pspSaveUrl)
                }
                zipWorkspaceName = "Manic Saves"
            }
            if urls.count == 0 {
                UIView.makeToast(message: {
                    switch shareFileType {
                    case .rom:
                        R.string.localizable.shareRomFilesFailed()
                    case .save:
                        R.string.localizable.shareSaveFilesFailed()
                    }
                }())
                return
            }
            
            UIView.makeLoading()
            DispatchQueue.global().async {
                let zipWorkspaceUrl = URL(fileURLWithPath: Constants.Path.ShareWorkSpace.appendingPathComponent("\(zipWorkspaceName) \(Date().string(withFormat: Constants.Strings.FileNameTimeFormat))"))
                //复制文件
                do {
                    for url in urls {
                        try FileManager.safeCopyItem(at: url, to: zipWorkspaceUrl.appendingPathComponent(url.lastPathComponent), shouldReplace: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        UIView.hideLoading()
                        UIView.makeToast(message: R.string.localizable.shareFilesCopyFailed())
                    }
                    return
                }
                //压缩文件
                let zipFileUrl = zipWorkspaceUrl.appendingPathExtension("zip")
                do {
                    try FileManager.default.zipItem(at: zipWorkspaceUrl, to: zipFileUrl)
                } catch {
                    DispatchQueue.main.async {
                        UIView.hideLoading()
                        UIView.makeToast(message: R.string.localizable.shareFilesCompressFailed())
                    }
                    return
                }
                DispatchQueue.main.async {
                    UIView.hideLoading()
                    let documentInteractionController = UIDocumentInteractionController()
                    ShareManager.shared.documentInteractionController = documentInteractionController
                    documentInteractionController.delegate = ShareManager.shared
                    documentInteractionController.url = zipFileUrl
                    documentInteractionController.uti = UTType.zip.identifier
                    if let view = topViewController(appController: true)?.view {
                        documentInteractionController.presentOptionsMenu(from: UIDevice.isPad ? .zero : view.frame, in: view, animated: true)
                    }
                    //App启动的时候再行清理操作
                }
            }
        }
    }
    
    static func shareFile(fileUrl: URL) {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            UIView.makeToast(message: R.string.localizable.shareFileFailedMissing())
            return
        }
        let documentInteractionController = UIDocumentInteractionController()
        ShareManager.shared.documentInteractionController = documentInteractionController
        documentInteractionController.delegate = ShareManager.shared
        documentInteractionController.url = fileUrl
        documentInteractionController.uti = "public.data"
        if let view = topViewController(appController: true)?.view {
            documentInteractionController.presentOptionsMenu(from: UIDevice.isPad ? .zero : view.frame, in: view, animated: true)
        }
    }
    
    private static func create3DSGameSave(urls: [String: URL]) -> URL? {
        var result = [URL]()
        for (name, url) in urls {
            let originalPath = url.path
            if let originalPathRange = originalPath.range(of: "sdmc") {
                let newPath = Constants.Path.ShareWorkSpace.appendingPathComponent(name).appendingPathComponent(String(originalPath[originalPathRange.lowerBound...]))
                do {
                    if FileManager.default.fileExists(atPath: newPath) {
                        try FileManager.default.removeItem(atPath: newPath)
                    }
                    try FileManager.default.createDirectory(atPath: newPath.deletingLastPathComponent, withIntermediateDirectories: true)
                    try FileManager.default.copyItem(atPath: originalPath, toPath: newPath)
                    if let newPathRange = newPath.range(of: "sdmc") {
                        let zipUrl = URL(fileURLWithPath: Constants.Path.ShareWorkSpace.appendingPathComponent(name + ".3ds.sav"))
                        if FileManager.default.fileExists(atPath: zipUrl.path) {
                            try FileManager.default.removeItem(at: zipUrl)
                        }
                        try FileManager.default.zipItem(at: URL(fileURLWithPath: String(newPath[...newPathRange.upperBound])), to: zipUrl)
                        result.append(zipUrl)
                    }
                } catch {
                    continue
                }
                try? FileManager.default.removeItem(atPath: newPath)
            }
        }
        if result.count == 1 {
            return result.first
        } else if result.count > 1 {
            let mergeResultName = "3DS Saves"
            let mergeResultPath = Constants.Path.ShareWorkSpace.appendingPathComponent(mergeResultName)
            try? FileManager.default.createDirectory(atPath: mergeResultPath, withIntermediateDirectories: true)
            for url in result {
                do {
                    try FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: mergeResultPath.appendingPathComponent(url.lastPathComponent)))
                } catch {
                    continue
                }
            }
            let mergeZipUrl = URL(fileURLWithPath: Constants.Path.ShareWorkSpace.appendingPathComponent(mergeResultName + ".zip"))
            if FileManager.default.fileExists(atPath: mergeZipUrl.path) {
                try? FileManager.default.removeItem(at: mergeZipUrl)
            }
            try? FileManager.default.zipItem(at: URL(fileURLWithPath: mergeResultPath), to: mergeZipUrl)
            if FileManager.default.fileExists(atPath: mergeZipUrl.path) {
                return mergeZipUrl
            }
        }
        return nil
    }
    
    private static func createPSPGameSave(_ games: [Game]) -> URL? {
        let pspSavePath = Constants.Path.PSPSave
        guard games.count > 0 else { return nil }
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: pspSavePath) else { return nil }
        let zipName = games.count > 1 ? "PSP Saves" : "\(games.first!.name)"
        let zipPath = Constants.Path.ShareWorkSpace.appendingPathComponent(zipName)
        if FileManager.default.fileExists(atPath: zipPath) {
            try? FileManager.default.removeItem(atPath: zipPath)
        }
        try? FileManager.default.createDirectory(atPath: zipPath, withIntermediateDirectories: true)
        for game in games {
            if game.gameType != .psp {
                continue
            }
            guard let code = game.gameCodeForPSP else { continue }
            contents.filter({ $0.hasPrefix(code) }).forEach { savePath in
                try? FileManager.default.copyItem(atPath: pspSavePath.appendingPathComponent(savePath), toPath: zipPath.appendingPathComponent(savePath.lastPathComponent))
            }
        }
        let zipUrl = URL(fileURLWithPath: zipPath + ".psp.sav")
        try? FileManager.safeRemoveItem(at: zipUrl)
        try? FileManager.default.zipItem(at: URL(fileURLWithPath: zipPath), to: zipUrl)
        try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: zipPath))
        if FileManager.default.fileExists(atPath: zipUrl.path) {
            return zipUrl
        }
        return nil
    }
    
    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        Log.debug("文件分享管理器隐藏了")
        documentInteractionController = nil
    }
}
