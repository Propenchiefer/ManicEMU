//
//  OnlineCoverManager.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/8.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ManicEmuCore
import Fuse
import SwiftSoup
import CryptoKit

class OnlineCoverManager {
    struct CoverMatch {
        var gameType: GameType
        var gameID: String
        var gameName: String
        var fileExtension: String
        
        init(game: Game) {
            self.gameType = game.gameType
            self.gameID = game.id
            self.gameName = game.aliasName ?? game.name
            self.fileExtension = game.fileExtension
        }
        
        init(gameType: GameType, gameID: String, gameName: String, fileExtension: String) {
            self.gameType = gameType
            self.gameID = gameID
            self.gameName = gameName
            self.fileExtension = fileExtension
        }
    }
    
    class MatchOperation: Operation, @unchecked Sendable {
        private let coverMatch: CoverMatch
        
        init(coverMatch: CoverMatch) {
            self.coverMatch = coverMatch
        }
        
        override func main() {
            guard !isCancelled else { return }
            let semaphore = DispatchSemaphore(value: 0)
            
            MatchOperation.searchCovers(coverMatch: coverMatch, fetchOne: true) { [weak self] urls, requestFailed in
                guard let self = self else {
                    semaphore.signal()
                    return
                }
                guard !requestFailed else {
                    semaphore.signal()
                    return
                }
                let realm = Database.realm
                if let game = realm.object(ofType: Game.self, forPrimaryKey: self.coverMatch.gameID) {
                    try? realm.write {
                        game.hasCoverMatch = true
                        if let onlineCoverUrl = urls.first {
                            game.onlineCoverUrl = onlineCoverUrl.absoluteString
                        }
                    }
                }
                semaphore.signal()
            }
            semaphore.wait() // 保证同步等待当前请求完成
        }
        
        static func searchCovers(coverMatch: CoverMatch, fetchOne: Bool = false, persistentedTranslation: Bool = true, isCallBackMain: Bool = false, completion: (([URL], Bool)->Void)? = nil) {
            //请求封面列表
            let host = URL(string: "https://thumbnails.libretro.com")!
            var boxArtUrl: URL? = nil
            switch coverMatch.gameType {
            case ._3ds:
                boxArtUrl = host.appendingPathComponent("Nintendo - Nintendo 3DS/Named_Boxarts/")
            case .ds:
                boxArtUrl = host.appendingPathComponent("Nintendo - Nintendo DS/Named_Boxarts/")
            case .gba:
                boxArtUrl = host.appendingPathComponent("Nintendo - Game Boy Advance/Named_Boxarts/")
            case .gbc:
                boxArtUrl = host.appendingPathComponent("Nintendo - Game Boy Color/Named_Boxarts/")
            case .gb:
                boxArtUrl = host.appendingPathComponent("Nintendo - Game Boy/Named_Boxarts/")
            case .nes:
                boxArtUrl = host.appendingPathComponent("Nintendo - Nintendo Entertainment System/Named_Boxarts/")
            case .snes:
                boxArtUrl = host.appendingPathComponent("Nintendo - Super Nintendo Entertainment System/Named_Boxarts/")
            case .psp:
                boxArtUrl = host.appendingPathComponent("Sony - PlayStation Portable/Named_Boxarts/")
            case .md:
                boxArtUrl = host.appendingPathComponent("Sega - Mega Drive - Genesis/Named_Boxarts/")
            case .mcd:
                boxArtUrl = host.appendingPathComponent("Sega - Mega-CD - Sega CD/Named_Boxarts/")
            case ._32x:
                boxArtUrl = host.appendingPathComponent("Sega - 32X/Named_Boxarts/")
            case .gg:
                boxArtUrl = host.appendingPathComponent("Sega - Game Gear/Named_Boxarts/")
            case .ms:
                boxArtUrl = host.appendingPathComponent("Sega - Master System - Mark III/Named_Boxarts/")
            case .sg1000:
                boxArtUrl = host.appendingPathComponent("Sega - SG-1000/Named_Boxarts/")
            case .ss:
                boxArtUrl = host.appendingPathComponent("Sega - Saturn/Named_Boxarts/")
            case .n64:
                boxArtUrl = host.appendingPathComponent("Nintendo - Nintendo 64/Named_Boxarts/")
            default:
                boxArtUrl = nil
            }
            guard let boxArtUrl else {
                completion?([], false)
                return
            }
            
            getMatchList(url: boxArtUrl) { matchList in
                translateGameName(coverMatch.gameName, gameID: persistentedTranslation ? coverMatch.gameID : nil) { gameName in
                    var onlineCoverUrls = [URL]()
                    let fuse = Fuse()
                    let pattern = fuse.createPattern(from: gameName)
                    if fetchOne {
                        //只获取一个
                        if let result = matchList.min(by: {
                            if let result0 = fuse.search(pattern, in: $0) {
                                if let result1 = fuse.search(pattern, in: $1) {
                                    return result0.score < result1.score
                                } else {
                                    return true
                                }
                            } else if let _ = fuse.search(pattern, in: $1) {
                                return false
                            } else {
                                return true
                            }
                        }) {
                            if let score = fuse.search(pattern, in: result)?.score, score < 0.35 {
                                //匹配结果OK
                                onlineCoverUrls.append(boxArtUrl.appendingPathComponent(result))
                            }
                        }
                    } else {
                        //获取多个
                        let result = matchList.filter({
                            if let result = fuse.search(pattern, in: $0), result.score < 0.35 {
                                Log.debug("搜索参数:\(gameName) 结果:\($0) 分数:\(result.score)")
                                return true
                            } else {
                                return false
                            }
                        }).sorted(by: {
                            if let result0 = fuse.search(pattern, in: $0) {
                                if let result1 = fuse.search(pattern, in: $1) {
                                    return result0.score < result1.score
                                } else {
                                    return true
                                }
                            } else if let _ = fuse.search(pattern, in: $1) {
                                return false
                            } else {
                                return true
                            }
                        }).compactMap({  boxArtUrl.appendingPathComponent($0) })
                        onlineCoverUrls.append(contentsOf: result)
                    }
                    if isCallBackMain {
                        DispatchQueue.main.async {
                            completion?(onlineCoverUrls, matchList.count == 0)
                        }
                    } else {
                        completion?(onlineCoverUrls, matchList.count == 0)
                    }
                }
            }
        }
        
        private static func getMatchList(url: URL, completion: @escaping ([String])->Void) {
            let matchListPath = Constants.Path.BoxArtsCache.appendingPathComponent("\(Insecure.MD5.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined())")
            try? FileManager.default.createDirectory(atPath: Constants.Path.BoxArtsCache, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: matchListPath) {
                //已经有搜索列表缓存
                if let content = try? String(contentsOf: URL(fileURLWithPath: matchListPath), encoding: .utf8) {
                    let result = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                    DispatchQueue.global().async {
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: matchListPath), let creationDate = attributes[.creationDate] as? Date {
                            if creationDate.daysSince(Date.now.tomorrow) < -7 {
                               //需要更新缓存
                                self.updateCache(url: url, cachePath: matchListPath)
                            }
                            
                        } else {
                            //无法获取创建时间 去更新缓存
                            self.updateCache(url: url, cachePath: matchListPath)
                        }
                    }
                    completion(result)
                }
            } else {
                self.updateCache(url: url, cachePath: matchListPath, completion: completion)
            }
        }
        
        private static func updateCache(url: URL, cachePath: String, completion: (([String])->Void)? = nil) {
            //没有搜索列表的缓存 尝试查找请求网络
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let html = String(data: data, encoding: .utf8), let document = try? SwiftSoup.parse(html) {
                    let links = try? document.select("a").filter({ $0.hasAttr("href") }).compactMap({
                        if let href = try? $0.attr("href"), href.hasSuffix(".png") {
                            return href.removingPercentEncoding
                        }
                        return nil
                    })
                        
                    if let links {
                        //进行缓存
                        DispatchQueue.global().async {
                            try? links.joined(separator: "\n").write(to: URL(fileURLWithPath: cachePath), atomically: true, encoding: .utf8)
                        }
                        completion?(links)
                    } else {
                        completion?([])
                    }
                } else {
                    completion?([])
                }
            }.resume()
        }
        
        //如果不传入gameID，则翻译结果不会保存到game中
        private static func translateGameName(_ name: String, gameID: String? = nil, completion:((String)->Void)? = nil) {
            if name.isEnglishLanguage() {
                Log.debug("英文语言无需翻译!")
                completion?(name)
            } else {
                if let gameID {
                    let realm = Database.realm
                    if let game = realm.object(ofType: Game.self, forPrimaryKey: gameID), let translatedName = game.translatedName {
                        Log.debug("已经处理过翻译!直接返回")
                        completion?(translatedName)
                        return
                    }
                }
                
                
                let content = """
                    Given the retro game title: "\(name)", detect its language.  
                    If it's English, return:{"isEN": true}  
                    If not, try to find out the official title to accurate English (ignore comments/special characters) and return:{"isEN": false, "name": "TRANSLATION"}  
                    Return JSON only, no explanations.
                    """
                var request = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
                request.timeoutInterval = 10
                request.httpMethod = "POST"
                request.addValue("Bearer \(Constants.Cipher.DeepSeek)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.httpBody = ["frequency_penalty": 0.7, "max_tokens": 2048, "model": "deepseek-chat", "presence_penalty": 0.7, "stream" : false, "temperature" : 1.3, "top_p" : 0.9, "response_format" : ["type": "json_object"], "messages": [["content": "\(content)", "role":"user"]]].jsonData()
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let _ = error {
                        completion?(name)
                        return
                    }
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                        completion?(name)
                        return
                    }
                    if let response = try? data?.jsonObject() as? [String: Any] {
                        //返回数据成功
                        Log.debug("deepseek返回:\(response.jsonString() ?? "json解析失败")")
                        if let firstChoices = (response["choices"] as? [[String: Any]])?.first,
                           let message = firstChoices["message"] as? [String: Any],
                           let responeJsonData = (message["content"] as? String)?.data(using: .utf8),
                           let responeJson = try? JSONSerialization.jsonObject(with: responeJsonData) as? [String: Any],
                           let isEN = responeJson["isEN"] as? Bool {
                            //数据返回成功
                            var resultName = name
                            if !isEN, let translatedName = responeJson["name"] as? String {
                                //返回翻译结果
                                Log.debug("获取翻译结果:\(translatedName)")
                                resultName = translatedName
                            }
                            completion?(resultName)
                            if let gameID {
                                let realm = Database.realm
                                if let game = realm.object(ofType: Game.self, forPrimaryKey: gameID) {
                                    var extras = (try? game.extras?.jsonObject() as? [String: Any]) ?? [String: Any]()
                                    extras["translatedName"] = resultName
                                    if let extrasData = extras.jsonData() {
                                        try? realm.write {
                                            game.extras = extrasData
                                        }
                                    }
                                }
                            }
                        } else {
                            //数据返回失败
                            Log.debug("解析deepseek失败2")
                            completion?(name)
                        }
                    } else {
                        //数据返回失败
                        Log.debug("解析deepseek失败1")
                        completion?(name)
                    }
                }
                task.resume()
            }
        }
    }
    
    static let shared = OnlineCoverManager()
    private let queue: OperationQueue
    
    init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
    }
    
    func addCoverMatch(_ coverMatch: CoverMatch) {
        guard coverMatch.gameType != .unknown && coverMatch.gameType != .notSupport else { return }
        let operation = MatchOperation(coverMatch: coverMatch)
        queue.addOperation(operation)
    }
    
    
}
