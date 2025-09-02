//
//  WebServer.swift
//  ManicEmu
//
//  Created by Max on 2025/1/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import GCDWebServer

class WebServer: NSObject {
    static let shard = WebServer()
    
    var ipAddress: String {
        if let webServer = webServer, let serverURL = webServer.serverURL, let host = serverURL.host, let port = serverURL.port {
             return "\(host):\(port)"
        }
        return ""
    }
    
    var isRunning: Bool {
        if let webServer = webServer {
            return webServer.isRunning
        }
        return false
    }
    
    private override init(){}
    private var webServer: GCDWebUploader?
    
    func start() {
        guard webServer == nil else { return }
        webServer = GCDWebUploader(uploadDirectory: Constants.Path.UploadWorkSpace)
        webServer?.allowedFileExtensions = FileType.allSupportFileExtension()
        webServer?.delegate = self
        if FileManager.default.fileExists(atPath: Constants.Path.UploadWorkSpace) {
            try? FileManager.default.removeItem(atPath: Constants.Path.UploadWorkSpace)
        }
        try? FileManager.default.createDirectory(atPath: Constants.Path.UploadWorkSpace, withIntermediateDirectories: true)
        webServer?.start(withPort: 6969, bonjourName: nil)
    }
    
    func stop() {
        if let webServer = webServer {
            if webServer.isRunning {
                DispatchQueue.global().async { [weak self] in
                    guard let self = self else { return }
                    self.webServer?.stop()
                    self.webServer = nil
                }
            }
        }
    }
}

extension WebServer: GCDWebUploaderDelegate {
    func webUploader(_ uploader: GCDWebUploader, didUploadFileAtPath path: String) {
        FilesImporter.importFiles(urls: [URL(fileURLWithPath: path)])
    }
}
