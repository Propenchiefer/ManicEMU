//
//  GameListView.swift
//  ManicEmu
//
//  Created by Max on 2025/1/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import RealmSwift
import ManicEmuCore
import UniformTypeIdentifiers
import Fireworks
import VisualEffectView
import IceCream
import Kingfisher
import KeyboardKit

class GameListView: BaseView {
    lazy var collectionView: BlankSlateCollectionView = {
        let view = BlankSlateCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = Constants.Color.Background
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: GameCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: GamesCollectionReusableView.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: RandomGameCollectionReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.allowsMultipleSelection = true
        let top = Constants.Size.ContentInsetTop + Constants.Size.ItemHeightMid + Constants.Size.ItemHeightHuge
        let bottom = Constants.Size.ContentInsetBottom + Constants.Size.HomeTabBarSize.height + Constants.Size.ContentSpaceMax
        view.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        view.blankSlateView = GamesListBlankSlateView()
        view.isOrthogonalSection = { [weak self] section in
            guard let self else { return false }
            if UIDevice.isPhone, UIDevice.isLandscape {
                return true
            }
            return false
        }
        view.buttonPress = { [weak self] key in
            guard let self else { return }
            if key == .a {
                if let selectedItems = self.collectionView.indexPathsForSelectedItems,
                    selectedItems.count == 1,
                    let selectedItem = selectedItems.first {
                    self.controllerButtonPress = true
                    let _ = self.collectionView(self.collectionView, shouldSelectItemAt: selectedItem)
                    self.controllerButtonPress = false
                }
                
            } else if key == .b {
                self.collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
            }
        }
        return view
    }()
    
    ///右侧索引栏
    private lazy var indexView: SectionIndexView = {
        let view = SectionIndexView()
        view.isItemIndicatorAlwaysInCenterY = true
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    ///点击随机游戏撒花效果
    private lazy var fireworks = ClassicFireworkController()
    
    ///普通模式数据源
    private var normalDatas: [GameType: [Game]] = [:]
    ///当前模式下的数据个数
    var totalGamesCountForCurrentMode: Int { (isSearchMode ? searchDatas : normalDatas).values.reduce(0) { $0 + $1.count } }
    
    ///搜索模式数据源
    private lazy var searchDatas: [GameType: [Game]] = [:]
    
    private var coverSizes = [GameType: CGSize]()
    
    ///选择模式
    var isSelectionMode: Bool { selectionMode != .normalMode }
    var selectionMode: SelectionChangeMode = .normalMode {
        didSet {
            guard selectionMode != oldValue else { return }
            for (gameTypeIndex, gameType) in self.sortDatasKeys().enumerated() {
                if let games = (isSearchMode ? searchDatas : normalDatas)[gameType] {
                    for (gameIndex, _) in games.enumerated() {
                        switch selectionMode {
                        case .normalMode, .selectionMode:
                            if selectionMode == .normalMode {
                                //退出选择模式的时候 进行复位一次
                                collectionView.allowsSelection = false
                                collectionView.allowsMultipleSelection = false
                                collectionView.allowsSelection = true
                                collectionView.allowsMultipleSelection = true
                            }
                            if let cell = collectionView.cellForItem(at: IndexPath(row: gameIndex, section: gameTypeIndex)) as? GameCollectionViewCell {
                                cell.updateViews(isSelect: selectionMode == .normalMode ? false : true)
                            }
                        case .selectAll:
                            collectionView.selectItem(at: IndexPath(row: gameIndex, section: gameTypeIndex), animated: true, scrollPosition: [])
                        case .deSelectAll:
                            collectionView.deselectItem(at: IndexPath(row: gameIndex, section: gameTypeIndex), animated: true)
                        }
                    }
                }
            }
        }
    }
    ///选择item回调
    var didListViewSelectionChange: ((_ selectionType: SelectionType)->Void)?
    
    ///更新工具条回调
    var didUpdateToolView: ((_ show: Bool, _ showCorner: Bool)->Void)?
    
    ///开始滚动
    var didScroll: (()->Void)?
    
    ///数据更新
    var didDatasUpdate: ((_ isEmpty: Bool)->Void)? {
        didSet {
            didDatasUpdate?(normalDatas.isEmpty)
        }
    }
    
    ///搜索模式
    var isSearchMode = false
    private var searchString: String? = nil
    
    ///UI辅助
    private var lastContentOffsetY = 0.0
    private var lastSelectSection = 0
    private var gamesNavigationBottom: CGFloat {
        if UIDevice.isPhone, UIDevice.isLandscape {
            return Constants.Size.ItemHeightMid
        } else {
            return (Constants.Size.SafeAera.top > 0 ? Constants.Size.SafeAera.top : Constants.Size.ContentSpaceMax) + Constants.Size.ItemHeightMid
        }
    }
    private var gamesToolBottom: CGFloat {
        if UIDevice.isPhone, UIDevice.isLandscape {
            return gamesNavigationBottom
        } else {
            return gamesNavigationBottom + Constants.Size.ItemHeightHuge
        }
    }
    private var landscapePhonePagingHeight = 0.0
    private var controllerButtonPress: Bool = false
    
    private var gameCoverChangeNotification: Any? = nil
    private var platformOrderChangeNotification: Any? = nil
    private var platformSelectionNotification: Any? = nil
    private var gameListStyleChangeNotification: Any? = nil
    private var keyboardDidConnectNotification: Any? = nil
    private var keyboardDidDisConnectNotification: Any? = nil
    private var gameControllerDidConnectNotification: Any? = nil
    private var gameControllerDidDisConnectNotification: Any? = nil
    private var stopPlayGameNotification: Any? = nil
    private var gameSortChangeNotification: Any? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().offset(0)
            make.top.bottom.equalToSuperview()
        }
        
        addSubview(indexView)
        indexView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.width.equalTo(31)
        }
        indexView.isHidden = true
        
        //更新游戏
        updateGames()
        
        gameCoverChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.GameCoverChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.collectionView.reloadData()
        }
        
        platformOrderChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.PlatformOrderChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.collectionView.reloadData()
            self.reloadIndexView()
        }
        
        platformSelectionNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.PlatformSelectionChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.updateDatas()
            self.collectionView.reloadData()
            self.reloadIndexView()
        }
        
        gameListStyleChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.GameListStyleChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.collectionView.reloadData()
            self.reloadIndexView()
        }
        
        if UIDevice.isPhone {
            gameControllerDidConnectNotification = NotificationCenter.default.addObserver(forName: .externalGameControllerDidConnect, object: nil, queue: .main) { [weak self] notification in
                self?.collectionView.reloadData()
            }
            gameControllerDidDisConnectNotification = NotificationCenter.default.addObserver(forName: .externalGameControllerDidDisconnect, object: nil, queue: .main) { [weak self] notification in
                self?.collectionView.reloadData()
            }
            keyboardDidConnectNotification = NotificationCenter.default.addObserver(forName: .externalKeyboardDidConnect, object: nil, queue: .main) { [weak self] notification in
                self?.collectionView.reloadData()
            }
            keyboardDidDisConnectNotification = NotificationCenter.default.addObserver(forName: .externalKeyboardDidDisconnect, object: nil, queue: .main) { [weak self] notification in
                self?.collectionView.reloadData()
            }
        }
        
        //监听结束游戏
        stopPlayGameNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.StopPlayGame, object: nil, queue: .main) { [weak self] notification in
            self?.collectionView.reloadData()
        }
        
        //游戏排序变更
        gameSortChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.GameSortChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.updateDatas()
            self.collectionView.reloadData()
            self.reloadIndexView()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        if let gameCoverChangeNotification = gameCoverChangeNotification {
            NotificationCenter.default.removeObserver(gameCoverChangeNotification)
        }
        
        if let platformOrderChangeNotification = platformOrderChangeNotification {
            NotificationCenter.default.removeObserver(platformOrderChangeNotification)
        }
        
        if let platformSelectionNotification = platformSelectionNotification {
            NotificationCenter.default.removeObserver(platformSelectionNotification)
        }
        
        if let gameListStyleChangeNotification = gameListStyleChangeNotification {
            NotificationCenter.default.removeObserver(gameListStyleChangeNotification)
        }
        if let keyboardDidConnectNotification {
            NotificationCenter.default.removeObserver(keyboardDidConnectNotification)
        }
        if let keyboardDidDisConnectNotification {
            NotificationCenter.default.removeObserver(keyboardDidDisConnectNotification)
        }
        if let gameControllerDidConnectNotification {
            NotificationCenter.default.removeObserver(gameControllerDidConnectNotification)
        }
        if let gameControllerDidDisConnectNotification {
            NotificationCenter.default.removeObserver(gameControllerDidDisConnectNotification)
        }
        if let stopPlayGameNotification {
            NotificationCenter.default.removeObserver(stopPlayGameNotification)
        }
    }
    
    private var gamesUpdateToken: NotificationToken? = nil
    private var games: Results<Game> = {
        //查询数据库
        let realm = Database.realm
        let games = realm.objects(Game.self).where { !$0.isDeleted }
        return games
    }()
    private func updateGames() {
        //监听数据的变化
        gamesUpdateToken = games.observe(keyPaths: [\Game.gameCover, \Game.aliasName, \Game.onlineCoverUrl]) { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .update(_, let deletions, let insertions, let modifications):
                Log.debug("游戏列表 游戏更新")
                //删除或新增数据
                if !deletions.isEmpty || !insertions.isEmpty {
                    self.updateDatas()
                    self.collectionView.reloadData()
                    self.reloadIndexView()
                }
                
                //如果被修改了则更新视图
                if !modifications.isEmpty {
                    let indexPaths = modifications.compactMap({ self.getIndexPath(for: self.games[$0]) })
                    self.collectionView.reloadItems(at: indexPaths)
                }
            default:
                break
            }
        }
        //查询结束更新数据库
        updateDatas()
        if games.count > 0 {
            //更新视图
            collectionView.reloadData()
            //更新索引视图
            reloadIndexView()
        }
    }
    
    ///构造符合UI展示的数据源
    private func updateDatas() {
        let groupGames = Dictionary(grouping: games, by: { $0.gameType })
        // 数据结果 [GameType: [Game]]
        let sortType = GameSortType(rawValue: Theme.defalut.getExtraInt(key: ExtraKey.gameSortType.rawValue) ?? 0) ?? .title
        let sortOrder = GameSortOrder(rawValue: Theme.defalut.getExtraInt(key: ExtraKey.gameSortOrder.rawValue) ?? 0) ?? .ascending
        normalDatas = groupGames.mapValues { $0.sorted(by: {
            if $0.gameType == .ds {
                //特殊处理NDS排序 总是保证Home Menu排在首位
                let priority: [String: Int] = [ Game.DsHomeMenuPrimaryKey: 0, Game.DsiHomeMenuPrimaryKey: 1 ]
                let lhsPriority = priority[$0.id] ?? Int.max
                    let rhsPriority = priority[$1.id] ?? Int.max
                    if lhsPriority != rhsPriority {
                        return lhsPriority < rhsPriority
                    } else {
                        //和其他机型一样
                        return self.sortDatas(game1: $0, game2: $1, sortType: sortType, sortOrder: sortOrder)
                    }
            } else {
                return self.sortDatas(game1: $0, game2: $1, sortType: sortType, sortOrder: sortOrder)
            }
        }) }
        
        if isSearchMode {
            //如果当前处于搜索模式 则搜索数据也进行更新
            updateSearchDatas()
        }
        didDatasUpdate?(normalDatas.isEmpty)
    }
    
    private func sortDatas(game1: Game, game2: Game, sortType: GameSortType, sortOrder: GameSortOrder) -> Bool {
        switch sortType {
        case .title:
            if sortOrder == .ascending {
                return game1.name < game2.name
            } else {
                return game1.name > game2.name
            }
        case .latestPlayed:
            let game1LatestPlayTime = (game1.latestPlayDate ?? Date(timeIntervalSince1970: 0)).timeIntervalSinceNow
            let game2LatestPlayTime = (game2.latestPlayDate ?? Date(timeIntervalSince1970: 0)).timeIntervalSinceNow
            if sortOrder == .ascending {
                return game1LatestPlayTime < game2LatestPlayTime
            } else {
                return game1LatestPlayTime > game2LatestPlayTime
            }
        case .addTime:
            if sortOrder == .ascending {
                return game1.importDate.timeIntervalSinceNow > game2.importDate.timeIntervalSinceNow
            } else {
                return game1.importDate.timeIntervalSinceNow < game2.importDate.timeIntervalSinceNow
            }
        case .playTime:
            if sortOrder == .ascending {
                return game1.totalPlayDuration < game2.totalPlayDuration
            } else {
                return game1.totalPlayDuration > game2.totalPlayDuration
            }
        }
    }
    
    ///构造符合搜索UI展示的数据源
    private func updateSearchDatas() {
        if let searchString = searchString {
            searchDatas.removeAll()
            for (gameTypeSection, gameType) in sortDatasKeys().enumerated() {
                for game in getGames(at: gameTypeSection) {
                    if ((game.aliasName ?? game.name) + game.fileExtension).contains(searchString, caseSensitive: false) {
                        var gamesList = searchDatas[gameType]
                        if gamesList == nil {
                            gamesList = []
                            searchDatas[gameType] = gamesList
                        }
                        searchDatas[gameType]?.append(game)
                    }
                }
            }
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            let isLandscapePhone = UIDevice.isPhone && UIDevice.isLandscape
            let gameType = self.sortDatasKeys()[sectionIndex]
            let itemSpacing = Constants.Size.ContentSpaceMax - Constants.Size.GamesListSelectionEdge*2
            let sectionInset = Constants.Size.ContentSpaceHuge
            
            //group布局
            let group: NSCollectionLayoutGroup
            if isLandscapePhone {
                let itemEstimatedHeight = min(env.container.contentSize.height, env.container.contentSize.width) - Constants.Size.ItemHeightMid - Constants.Size.ItemHeightMin - 106
                self.landscapePhonePagingHeight = Constants.Size.ItemHeightMid + Constants.Size.ContentSpaceUltraTiny + itemEstimatedHeight + Constants.Size.ContentSpaceHuge*2
                let coverHeight = itemEstimatedHeight - Constants.Size.GamesListSelectionEdge - (self.isSearchMode || !Constants.Size.GamesHideTitle ? Constants.Size.ContentSpaceMin + Constants.Font.body().lineHeight : 0) - Constants.Size.GamesListSelectionEdge
                let coverWidth = coverHeight
                let itemEstimatedWidth = coverWidth + Constants.Size.GamesListSelectionEdge*2
                let coverSize = CGSize(width: coverWidth, height: coverHeight)
                if let size =  self.coverSizes[gameType] {
                    //尺寸存在
                    if size != coverSize {
                        self.coverSizes[gameType] = coverSize
                    }
                } else {
                    //尺寸不存在
                    self.coverSizes[gameType] = coverSize
                }
                let newItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                        heightDimension: .fractionalHeight(1)))
                
                group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(itemEstimatedWidth),
                                                                                              heightDimension: .absolute(itemEstimatedHeight)),
                                                           subitems: [newItem])
            } else {
                var column = Constants.Size.GamesPerRow
                if UIDevice.isPad {
                    column = UIDevice.isPadMini ? 7 : 8
                }
                let widthDimension: NSCollectionLayoutDimension = .fractionalWidth(1/column)
                //item布局
                let totleSpacing = (Constants.Size.ContentSpaceHuge-Constants.Size.GamesListSelectionEdge)*2 + itemSpacing*(column-1)//横向间距总和
                let itemEstimatedWidth = (env.container.contentSize.width - totleSpacing)/column //一个item的宽
                let coverWidth = itemEstimatedWidth-Constants.Size.GamesListSelectionEdge*2
                let coverHeight = coverWidth/Constants.Size.GameCoverRatio(gameType: gameType) //书籍封面的高度
                //一个item的高度 = 间距 + 封面高度 + 间距 + title高度 + 间距
                let itemEstimatedHeight = Constants.Size.GamesListSelectionEdge + coverHeight + (self.isSearchMode || !Constants.Size.GamesHideTitle ? Constants.Size.ContentSpaceMin + Constants.Font.body().lineHeight : 0) + Constants.Size.GamesListSelectionEdge
                let coverSize = CGSize(width: coverWidth, height: coverHeight)
                if let size =  self.coverSizes[gameType] {
                    //尺寸存在
                    if size != coverSize {
                        self.coverSizes[gameType] = coverSize
                    }
                } else {
                    //尺寸不存在
                    self.coverSizes[gameType] = coverSize
                }
                
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: widthDimension,
                                                                                     heightDimension: .absolute(itemEstimatedHeight)))
                group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                              heightDimension: .absolute(itemEstimatedHeight)),
                                                           subitem: item, count: Int(column))
                
                group.interItemSpacing = NSCollectionLayoutSpacing.fixed(itemSpacing)
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: sectionInset-Constants.Size.GamesListSelectionEdge,
                                                              bottom: 0,
                                                              trailing: sectionInset-Constants.Size.GamesListSelectionEdge)
            }
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            if isLandscapePhone {
                section.orthogonalScrollingBehavior = .continuous
            }
            section.interGroupSpacing = itemSpacing
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceUltraTiny,
                                                            leading: isLandscapePhone ? Constants.Size.SafeAera.left : 0,
                                                            bottom: (sectionIndex != (self.normalDatas.count - 1)) ? (isLandscapePhone ? Constants.Size.ContentSpaceHuge*2 : Constants.Size.ContentSpaceHuge) : 0,
                                                            trailing: isLandscapePhone ? Constants.Size.SafeAera.right : 0)
            if self.isSearchMode || !Constants.Size.GamesHideGroupTitle || isLandscapePhone {
                //header布局
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .estimated(Constants.Size.ItemHeightMin)),
                                                                             elementKind: UICollectionView.elementKindSectionHeader,
                                                                             alignment: .top)
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
            }
            
            if !self.isSearchMode && sectionIndex == self.normalDatas.count - 1 && self.collectionView.numberOfItems() > Constants.Numbers.RandomGameLimit && !isLandscapePhone {
                //最后一个section添加footer
                let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(55)),
                                                                             elementKind: UICollectionView.elementKindSectionFooter,
                                                                             alignment: .bottom)
                section.boundarySupplementaryItems.append(footerItem)
            }
            
            return section
            
        }
        return layout
    }
    
    func searchDatas(string: String) {
        guard searchString != string else { return }
        //开始搜索前获取已经选中的games
        let games = collectionView.indexPathsForSelectedItems?.compactMap({ getGame(at: $0) })
        isSearchMode = false
        searchString = string
        updateSearchDatas()
        isSearchMode = true
        collectionView.reloadData { [weak self] in
            guard let self = self else { return }
            if let games = games {
                //重新选中搜索前选中的item
                games.forEach {
                    if let indexPath = self.getIndexPath(for: $0) {
                        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
                var mode: SelectionType = .selectNone
                if games.count == self.totalGamesCountForCurrentMode, self.totalGamesCountForCurrentMode > 0 {
                    mode = .selectAll
                } else if games.count > 0 {
                    mode = .selectSome(onlyOne: games.count == 1)
                }
                //通知外部 选择类型更新
                if self.totalGamesCountForCurrentMode > 0 {
                    self.didListViewSelectionChange?(mode)
                }
            }
        }
        reloadIndexView()
    }
    
    func stopSearch() {
        if isSearchMode {
            //停止搜索前获取已经选中的games
            let games = collectionView.indexPathsForSelectedItems?.compactMap({ getGame(at: $0) })
            isSearchMode = false
            searchString = nil
            searchDatas.removeAll()
            collectionView.reloadData { [weak self] in
                guard let self = self else { return }
                if let games = games {
                    //重新选中搜索前选中的item
                    games.forEach { self.collectionView.selectItem(at: self.getIndexPath(for: $0), animated: false, scrollPosition: []) }
                    var mode: SelectionType = .selectNone
                    if games.count == self.totalGamesCountForCurrentMode {
                        mode = .selectAll
                    } else if games.count > 0 {
                        mode = .selectSome(onlyOne: games.count == 1)
                    }
                    //通知外部 选择类型更新
                    self.didListViewSelectionChange?(mode)
                }
            }
            reloadIndexView()
        }
    }
    
    private func reloadIndexView() {
        let datasCount = (isSearchMode ? searchDatas : normalDatas).count
        if datasCount == 0 {
            indexView.isHidden = true
            return
        } else {
            indexView.isHidden = false
        }
        indexView.reloadData()
        indexView.deselectCurrentItem()
        indexView.selectItem(at: 0)
        if UIDevice.isPhone, UIDevice.isLandscape {
            indexView.isHidden = true
        } else {
            indexView.isHidden = Constants.Size.GamesHideScrollIndicator
        }
    }
    
    func editGame(item: GameEditToolItem, indexPath: IndexPath? = nil) {
        var games: [Game] = []
        if let indexPath = indexPath, let game = self.getGame(at: indexPath) {
            games.append(game)
        } else if let tempIndexPaths = collectionView.indexPathsForSelectedItems {
            games.append(contentsOf: tempIndexPaths.compactMap({ getGame(at: $0) }))
        } else {
            return
        }
        
        if games.count == 0 {
            return
        }
        
        let firstGame = games.first!
        
        switch item {
        case .rename:
            topViewController()?.present(GameInfoViewController(game: firstGame, readyAction: .rename), animated: true)
        case .cover:
            topViewController()?.present(GameInfoViewController(game: firstGame, readyAction: .changeCover), animated: true)
        case .checkSave:
            topViewController()?.present(GameInfoViewController(game: firstGame), animated: true)
        case .skin:
            topViewController()?.present(SkinSettingsViewController(game: firstGame), animated: true)
        case .shareRom:
            ShareManager.shareFiles(games: games, shareFileType: .rom)
        case .importSave:
            if firstGame.gameType == .dc {
                
                return
            }
            FilesImporter.shared.presentImportController(supportedTypes: UTType.gamesaveTypes, allowsMultipleSelection: false) { urls in
                if let url = urls.first {
                    if firstGame.gameType == ._3ds || firstGame.gameType == .psp {
                        FilesImporter.importFiles(urls: [url])
                    } else {
                        if firstGame.isSaveExtsts {
                            UIView.makeAlert(title: R.string.localizable.gameSaveAlreadyExistTitle(),
                                             detail: ImportError.saveAlreadyExist(gameSaveUrl: url, game: firstGame).localizedDescription,
                                             confirmTitle: R.string.localizable.confirmTitle(),
                                             enableForceHide: false,
                                             confirmAction: {
                                try? FileManager.safeCopyItem(at: url, to: firstGame.gameSaveUrl, shouldReplace: true)
                                UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle())
                            })
                        } else {
                            try? FileManager.safeCopyItem(at: url, to: firstGame.gameSaveUrl, shouldReplace: true)
                            UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle())
                        }
                    }
                }
            }
        case .shareSave:
            ShareManager.shareFiles(games: games, shareFileType: .save)
        case .delete:
            UIView.makeAlert(title: R.string.localizable.gamesDelete(),
                             detail: R.string.localizable.deleteGameAlertDetail(),
                             confirmTitle: R.string.localizable.confirmDelte(),
                             confirmAction: {
                Game.change { realm in
                    for game in games {
                        if game.isRomExtsts {
                            if game.gameType == ._3ds, game.fileExtension.lowercased() == "app", let range = game.romUrl.path.range(of: "/content/00000000.app") {
                                let gamePath = String(game.romUrl.path[...range.lowerBound])
                                try FileManager.safeRemoveItem(at: URL(fileURLWithPath: gamePath))
                                SyncManager.delete(localFilePath: gamePath)
                                //删除DLC和更新
                                let updatePath = gamePath.replacingOccurrences(of: "/00040000/", with: "/0004000e/")
                                try FileManager.safeRemoveItem(at: URL(fileURLWithPath: updatePath))
                                SyncManager.deletePath(localPath: updatePath)
                                let dlcPath = gamePath.replacingOccurrences(of: "/00040000/", with: "/0004008c/")
                                try FileManager.safeRemoveItem(at: URL(fileURLWithPath: dlcPath))
                                SyncManager.deletePath(localPath: dlcPath)
                            } else if game.isMultiFileGame {
                                let romParentPath = game.romUrl.path.deletingLastPathComponent
                                try FileManager.safeRemoveItem(at: URL(fileURLWithPath: romParentPath))
                                SyncManager.deletePath(localPath: romParentPath)
                            } else {
                                try FileManager.safeRemoveItem(at: game.romUrl)
                                SyncManager.delete(localFilePath: game.romUrl.path)
                            }
                        }
                        if game.isSaveExtsts {
                            if game.gameType == .psp, let code = game.gameCodeForPSP {
                                //psp的存档可能分为多个文件夹
                                try? FileManager.default.contentsOfDirectory(atPath: Constants.Path.PSPSave).filter({ $0.hasPrefix(code)}).forEach { savePath in
                                    let deletePath = Constants.Path.PSPSave.appendingPathComponent(savePath)
                                    try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: deletePath))
                                    SyncManager.deletePath(localPath: deletePath)
                                }
                            } else {
                                try FileManager.safeRemoveItem(at: game.gameSaveUrl)
                                SyncManager.delete(localFilePath: game.gameSaveUrl.path)
                            }
                        }
                        if let coverData = game.gameCover {
                            coverData.deleteAndClean(realm: realm)
                        }
                        CreamAsset.batchDeleteAndClean(assets: game.gameSaveStates.compactMap({ $0.stateCover }), realm: realm)
                        CreamAsset.batchDeleteAndClean(assets: game.gameSaveStates.compactMap({ $0.stateData }), realm: realm)
                        if Settings.defalut.iCloudSyncEnable {
                            //iCloud同步时使用软删除
                            game.gameCheats.forEach { $0.isDeleted = true }
                            game.gameSaveStates.forEach { $0.isDeleted = true }
                            game.isDeleted = true
                        } else {
                            //本地删除
                            realm.delete(game.gameCheats)
                            realm.delete(game.gameSaveStates)
                            realm.delete(game)
                        }
                    }
                }
            })
        }
    }
    
    func updateRotation() {
        if UIDevice.isPhone {
            collectionView.snp.updateConstraints { make in
                make.leading.equalToSuperview().offset(-Constants.Size.SafeAera.left)
                make.trailing.equalToSuperview().offset(Constants.Size.SafeAera.right)
            }
            DispatchQueue.main.asyncAfter(delay: 0.35) { [weak self] in
                guard let self else { return }
                self.collectionView.reloadData {
                    if UIDevice.isLandscape {
                        self.collectionView.contentInset.top = self.gamesNavigationBottom
                        if self.normalDatas.count > 0 {
                            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: self.lastSelectSection), at: .top, animated: true)
                        }
                    }
                }
                self.reloadIndexView()
            }
        }
    }
}

extension GameListView: UICollectionViewDataSource {
    private func sortDatasKeys() -> [GameType] {
        var predefinedOrder: [GameType]
        if let customPlatformOrder = Constants.Config.PlatformOrder {
            predefinedOrder = customPlatformOrder.compactMap { GameType(shortName: $0) }
        } else {
            predefinedOrder = System.allCases.map { $0.gameType }
        }
        predefinedOrder.append(.unknown)
        let sortedKeys: [GameType] = predefinedOrder.filter { (isSearchMode ? searchDatas : normalDatas).keys.contains($0) }
        return sortedKeys
    }
    
    private func getGames(at section: Int) -> [Game] {
        let gameTypes = sortDatasKeys()
        let gameType = gameTypes[section]
        if let results = (isSearchMode ? searchDatas : normalDatas)[gameType] {
            return results
        }
        return []
    }
    
    private func getGame(at indexPath: IndexPath) -> Game? {
        let games = getGames(at: indexPath.section)
        if games.count > indexPath.row {
            return games[indexPath.row]
        }
        return nil
    }
    
    private func getIndexPath(for game: Game) -> IndexPath? {
        if let results = (isSearchMode ? searchDatas : normalDatas)[game.gameType] {
            if let section = sortDatasKeys().firstIndex(of: game.gameType), let row = results.firstIndex(of: game) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }
    
    private func deleteGames(indexPaths: [IndexPath]) {
        var sectionRowsDict: [Int: [Int]] = [:]
        for indexPath in indexPaths {
            if sectionRowsDict[indexPath.section] != nil {
                sectionRowsDict[indexPath.section]?.append(indexPath.row)
            } else {
                sectionRowsDict[indexPath.section] = [indexPath.row]
            }
        }
        
        let sortDatasKeys = sortDatasKeys()
        for (key, value) in sectionRowsDict {
            if var games = normalDatas[sortDatasKeys[key]] {
                games.remove(atOffsets: IndexSet(value))
                normalDatas[sortDatasKeys[key]] = games.count == 0 ? nil : games
            }
        }
        
        collectionView.reloadData()
        didDatasUpdate?(normalDatas.isEmpty)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        (isSearchMode ? searchDatas : normalDatas).count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getGames(at: section).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: GameCollectionViewCell.self, for: indexPath)
        if let game = getGame(at: indexPath) {
            cell.setData(game: game, isSelect: isSelectionMode, highlightString: searchString, coverSize: coverSizes[game.gameType] ?? .zero, showTitle: !Constants.Size.GamesHideTitle || isSearchMode, indexPath: indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            //header
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: GamesCollectionReusableView.self, for: indexPath)
            let gameType = sortDatasKeys()[indexPath.section]
            header.setData(gameType: gameType, highlightString: searchString, contentInsets: UIDevice.isPhone && UIDevice.isLandscape ? .init(top: 0, left: Constants.Size.SafeAera.left, bottom: 0, right: Constants.Size.SafeAera.right) : .zero)
            if gameType == .unknown {
                header.skinButton.isHidden = true
            } else {
                header.skinButton.isHidden = false
                header.skinButton.onTap {
                    topViewController()?.present(SkinSettingsViewController(gameType: gameType), animated: true)
                }
            }
            header.didTapPlatform = {
                if gameType != .unknown {
                    topViewController(appController: true)?.present(WebViewController(url: Constants.URLs.History(gameType: gameType)), animated: true)
                }   
            }
            return header
        } else {
            //随机游戏footer
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: RandomGameCollectionReusableView.self, for: indexPath)
            header.addTapGesture { [weak self, weak header] gesture in
                guard let self = self else { return }
                guard let header = header else { return }
                self.fireworks.addFireworks(count: 2, around: header.iconImage)
                header.iconImage.rotateShake(completion: { [weak self] in
                    guard let self = self else { return }
                    let randomSection = Int(arc4random()) % self.normalDatas.count
                    if let games = self.normalDatas[self.sortDatasKeys()[randomSection]] {
                        let randomGame = games[Int(arc4random()) % games.count]
                        Log.debug("开始随机游戏:\(randomGame.aliasName ?? randomGame.name)")
                        PlayViewController.startGame(game: randomGame)
                    }
                })
            }
            return header
        }
    }
}

extension UIView {
    func rotateShake(
        duration: TimeInterval = 1,
        completion: (() -> Void)? = nil) {
            CATransaction.begin()
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            CATransaction.setCompletionBlock(completion)
            animation.duration = duration
            
            animation.values = [-.pi/4.0, .pi/4.0, -.pi/6.0, .pi/6.0, -.pi/8.0, .pi/8.0, -.pi/10.0, .pi/10.0, 0.0]
            layer.add(animation, forKey: "rotateShake")
            CATransaction.commit()
        }
}

extension GameListView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSelectionMode {
            if let selectedItems = collectionView.indexPathsForSelectedItems?.count {
                if selectedItems == totalGamesCountForCurrentMode && selectedItems > 1 {
                    //全部选中了
                    didListViewSelectionChange?(.selectAll);
                } else if selectedItems > 0 {
                    didListViewSelectionChange?(.selectSome(onlyOne: selectedItems == 1));
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if isSelectionMode {
            if let game = getGame(at: indexPath) {
                if game.gameType == .unknown {
                    UIView.makeToast(message: R.string.localizable.unknownPlatformGameSelectWarn())
                    return false
                } else if game.id == Game.DsHomeMenuPrimaryKey || game.id == Game.DsiHomeMenuPrimaryKey {
                    UIView.makeToast(message: R.string.localizable.homeMenuSelectWarn())
                    return false
                }
            }
            return true
        }
        if let game = getGame(at: indexPath) {
            if game.isNDSHomeMenuGame {
                let biosCompletion = game.gameType.isNDSBiosComplete()
                if (game.id == Game.DsHomeMenuPrimaryKey && !biosCompletion.isDSComplete) || (game.id == Game.DsiHomeMenuPrimaryKey && !biosCompletion.isDsiComplete) {
                    //弹出bios导入页面
                    topViewController(appController: true)?.present(BIOSSelectionViewController(gameType: game.gameType), animated: true)
                } else {
                    PlayViewController.startGame(game: game)
                }
            } else if Settings.defalut.quickGame || controllerButtonPress {
                PlayViewController.startGame(game: game)
            } else {
                if game.gameType == .unknown {
                    PlatformSelectionView.show(game: game)
                } else {
                    topViewController()?.present(GameInfoViewController(game: game), animated: true)
                }
            }
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let selectCount = collectionView.indexPathsForSelectedItems?.count {
            didListViewSelectionChange?(selectCount > 0 ? .selectSome(onlyOne: selectCount == 1) : .selectNone);
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?()
        
        let contentOffsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        
        //上滑和下滑隐藏或展示工具条
        let isEditMode = isSearchMode || isSelectionMode
        if isEditMode {
            //编辑模式下 toolView滑动过程中不需要隐藏 但是需要将toolView的圆角背景进行隐藏
            if contentOffsetY > Constants.Size.ItemHeightTiny {
                didUpdateToolView?(true, false)
            } else {
                didUpdateToolView?(true, true)
            }
            lastContentOffsetY = contentOffsetY
        } else {
            //正常模式下 tooleView在顶部进行上滑或者下滑的过程中需要进行隐藏或者展示 这里难点是还要处理header的pin的位置
            if contentOffsetY > 0 && lastContentOffsetY > 0 && contentOffsetY > lastContentOffsetY && scrollView.contentInset.top != gamesNavigationBottom {
                //上滑
                //隐藏toolView
                didUpdateToolView?(false, true)
                lastContentOffsetY = 0
                UIView.springAnimate { [weak self] in
                    guard let self = self else { return }
                    //将header的pin位置上移 设置contentInset会改变contentOffset，所以注意上面lastContentOffsetY修复为0
                    scrollView.contentInset.top = self.gamesNavigationBottom
                }
            } else if contentOffsetY <= 0 && contentOffsetY < lastContentOffsetY && scrollView.contentInset.top != gamesToolBottom {
                //下滑
                //展示toolView
                didUpdateToolView?(true, true)
                lastContentOffsetY += Constants.Size.ItemHeightHuge
                UIView.normalAnimate { [weak self] in
                    guard let self = self else { return }
                    //为了使动画更加平顺
                    self.collectionView.contentOffset = CGPoint(x: 0, y: -self.gamesToolBottom)
                } completion: { [weak self] _ in
                    guard let self = self else { return }
                    //将header的pin位置下移 设置contentInset会改变contentOffset，所以注意上面lastContentOffsetY添加了toolView的高度
                    scrollView.contentInset.top = self.gamesToolBottom
                }
            } else {
                lastContentOffsetY = contentOffsetY
            }
        }
        
        // indexView变更
        guard !indexView.isTouching else { return }
        let sections = collectionView.numberOfSections
        var pinnedSection: Int?
        for section in 0..<sections {
            if let layoutAttributes = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section)
            ) {
                let headerFrame = layoutAttributes.frame
                if contentOffsetY + 5 >= floor(headerFrame.origin.y) {
                    pinnedSection = section
                } else {
                    break
                }
            }
        }

        if let pinnedSection = pinnedSection {
            guard let item = self.indexView.item(at: pinnedSection), item.bounds != .zero  else { return }
            guard !(self.indexView.selectedItem?.isEqual(item) ?? false) else { return }
            self.indexView.deselectCurrentItem()
            self.indexView.selectItem(at: pinnedSection)
            self.lastSelectSection = pinnedSection
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if UIDevice.isPhone, UIDevice.isLandscape {
            targetContentOffset.pointee = scrollView.contentOffset
            
            let contentInsetTop: CGFloat = scrollView.contentInset.top
            let adjustedOffsetY = scrollView.contentOffset.y + contentInsetTop + Constants.Size.ItemHeightMid
            let sectionFullHeight = landscapePhonePagingHeight
            let currentSectionFloat = adjustedOffsetY / sectionFullHeight
            let isScrollingDown = velocity.y > 0
            let isScrollingUp = velocity.y < 0
            
            var targetSection = Int(round(currentSectionFloat))
            
            // 根据速度判断是否翻页
            if abs(velocity.y) > 0.5 {
                if isScrollingDown {
                    targetSection = Int(floor(currentSectionFloat)) + 1
                } else if isScrollingUp {
                    targetSection = Int(ceil(currentSectionFloat)) - 1
                }
            }
            
            // 限制范围
            targetSection = max(0, min(targetSection, collectionView.numberOfSections - 1))
            
            // 可选：如果你仍想使用 scrollToItem，也可以这样写
            collectionView.scrollToItem(at: IndexPath(item: 0, section: targetSection), at: .top, animated: true)
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        sectionIndexViewDidSelectSearch(indexView)
        return false
    }
    
    //长按弹出可交互菜单
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard selectionMode == .normalMode, let indexPath = indexPaths.first else { return nil }
        
        if let game = getGame(at: indexPath), let imageView = (collectionView.cellForItem(at: indexPath) as? GameCollectionViewCell)?.imageView {
            
            let editItems = GameEditToolItem.singleGameEditItems
            var firstGroup: [UIMenuElement] = []
            var secondGroup: [UIMenuElement] = []
            var thirdGroup: [UIMenuElement] = []
            for (index, editItem) in editItems.enumerated() {
                let action = UIAction(title: editItem.title, image: editItem.image, attributes: editItem == .delete ? .destructive : []) { [weak self] _ in
                    guard let self = self else { return }
                    self.editGame(item: editItems[index], indexPath: indexPath)
                }
                if index < 4 {
                    //0-3为一组
                    firstGroup.append(action)
                } else if index < 7 {
                    //4-6为一组
                    secondGroup.append(action)
                } else {
                    //删除按钮为单独一组
                    thirdGroup.append(action)
                }
            }
            
            if game.isNDSHomeMenuGame {
                //NDS Home Menu只保留删除操作
                return UIContextMenuConfiguration(previewProvider: {
                    let previewImageView = imageView.snapshotView(afterScreenUpdates: false) ?? UIView()
                    previewImageView.layerCornerRadius = imageView.layerCornerRadius
                    let viewController = UIViewController()
                    viewController.view.addSubview(previewImageView)
                    viewController.preferredContentSize = imageView.size
                    return  viewController
                }, actionProvider: { _ in
                    UIMenu(title: game.aliasName ?? game.name, children: [UIMenu(options: .displayInline, children: thirdGroup)])
                })
                
            } else if game.gameType == .unknown {
                //只保留切换平台和删除操作
                let action = UIAction(title: R.string.localizable.platformChange(), image: .symbolImage(.arrowLeftArrowRight)) { _ in
                    PlatformSelectionView.show(game: game)
                }
                
                return UIContextMenuConfiguration(previewProvider: {
                    let previewImageView = imageView.snapshotView(afterScreenUpdates: false) ?? UIView()
                    previewImageView.layerCornerRadius = imageView.layerCornerRadius
                    let viewController = UIViewController()
                    viewController.view.addSubview(previewImageView)
                    viewController.preferredContentSize = imageView.size
                    return  viewController
                }, actionProvider: { _ in
                    UIMenu(title: game.aliasName ?? game.name, children: [UIMenu(options: .displayInline, children: [action]), UIMenu(options: .displayInline, children: thirdGroup)])
                })
                
            } else {
                if GameType.gameTypes(multiPlatformFileExtension: game.fileExtension).count > 1 {
                    //添加更换平台的操作
                    let action = UIAction(title: R.string.localizable.platformChange(), image: .symbolImage(.arrowLeftArrowRight)) { _ in
                        PlatformSelectionView.show(game: game)
                    }
                    firstGroup.append(action)
                }
                
                if game.gameType.supportCores.count > 0 {
                    //添加切换核心的操作
                    let action = UIAction(title: R.string.localizable.switchEmulationCore(), image: .symbolImage(.memorychip)) { _ in
                        if game.gameType == .ss, game.fileExtension.lowercased() == "iso" {
                            UIView.makeToast(message: R.string.localizable.saturnISONoSwitchCore())
                        } else {
                            CoreSelectionView.show(game: game)
                        }
                    }
                    firstGroup.append(action)
                }
            }
            
            
            
            //添加"复制启动链接"
            let action = UIAction(title: R.string.localizable.copyLaunchLinkTitle(), image: .symbolImage(.link)) { _ in
                UIPasteboard.general.string = "manicemu://launch/\(game.id)"
                if game.gameCover != nil || game.onlineCoverUrl != nil {
                    //弹出提示询问用户是否需要进行封面的保存
                    UIView.makeAlert(detail: R.string.localizable.askIfNeedToSaveCover(), confirmTitle: R.string.localizable.saveTitle(), confirmAction: {
                        //保存封面到相册
                        if let imageFilePath = game.gameCover?.filePath, let imageData = try? Data(contentsOf: imageFilePath) {
                            PhotoSaver.save(datas: [imageData])
                        } else if let onlineCoverUrl = game.onlineCoverUrl, let url = URL(string: onlineCoverUrl) {
                            KingfisherManager.shared.retrieveImage(with: url) { result in
                                switch result {
                                case .success(let imageResult):
                                    Task { @MainActor in
                                        PhotoSaver.save(image: imageResult.image)
                                    }
                                case .failure(_):
                                    Task { @MainActor in
                                        UIView.makeToast(message: R.string.localizable.onlineCoverFetchFailed())
                                    }
                                }
                            }

                        } else {
                            UIView.makeToast(message: R.string.localizable.onlineCoverFetchFailed())
                        }
                    })
                }
            }
            firstGroup.append(action)
            
            return UIContextMenuConfiguration(previewProvider: {
                let previewImageView = imageView.snapshotView(afterScreenUpdates: false) ?? UIView()
                previewImageView.layerCornerRadius = imageView.layerCornerRadius
                let viewController = UIViewController()
                viewController.view.addSubview(previewImageView)
                viewController.preferredContentSize = imageView.size
                return  viewController
            }, actionProvider: { _ in
                UIMenu(title: game.aliasName ?? game.name, children: [UIMenu(options: .displayInline, children: firstGroup), UIMenu(options: .displayInline, children: secondGroup), UIMenu(options: .displayInline, children: thirdGroup)])
            })
        }
        return nil
    }
}

extension GameListView: SectionIndexViewDataSource, SectionIndexViewDelegate {
    func numberOfScetions(in sectionIndexView: SectionIndexView) -> Int {
        (isSearchMode ? searchDatas : normalDatas).count
    }
    
    func sectionIndexView(_ sectionIndexView: SectionIndexView, itemAt section: Int) -> any SectionIndexViewItem {
        let item = SectionIndexViewItemView()
        let gameType = sortDatasKeys()[section]
        if let title = (Constants.Size.GamesGroupTitleStyle == .abbr ? gameType.localizedShortName : gameType.localizedName).first?.uppercased() {
            item.title = title
        } else {
            item.title = "?"
        }
        item.titleColor = Constants.Color.LabelTertiary
        item.titleSelectedColor = Constants.Color.LabelPrimary
        item.selectedColor = Constants.Color.Main
        item.titleFont = Constants.Font.caption(size: .s, weight: .bold)
        return item
    }
    
    func sectionIndexView(_ sectionIndexView: SectionIndexView, didSelect section: Int) {
        sectionIndexView.hideCurrentItemIndicator()
        sectionIndexView.deselectCurrentItem()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showCurrentItemIndicator()
        sectionIndexView.impact()
        collectionView.panGestureRecognizer.isEnabled = false
        collectionView.scrollToItem(at: IndexPath(row: 0, section: section), at: .top, animated: true)
    }
    
    func sectionIndexViewToucheEnded(_ sectionIndexView: SectionIndexView) {
        UIView.animate(withDuration: 0.3) {
            sectionIndexView.hideCurrentItemIndicator()
        }
        collectionView.panGestureRecognizer.isEnabled = true
    }
    
    func sectionIndexViewDidSelectSearch(_ sectionIndexView: SectionIndexView) {
        collectionView.scrollToTop()
    }
}
