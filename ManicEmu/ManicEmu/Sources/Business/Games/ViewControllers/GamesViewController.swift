//
//  GamesViewController.swift
//  ManicEmu
//
//  Created by Max on 2025/1/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import SideMenu
import RealmSwift
import KeyboardKit

class GamesViewController: BaseViewController {
    private var cornerMaskViewForiPad: TransparentHoleView = {
        let view = TransparentHoleView()
        return view
    }()
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur(blurColor: Constants.Color.Background)
        return view
    }()
    
    private lazy var gamesNavigationView: GamesNavigationView = {
        let view = GamesNavigationView()
        view.controllerButton.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.showSideMenu(leftSide: true)
        }
        
        view.historyButton.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.showSideMenu(leftSide: false)
        }
        
        return view
    }()
    ///顶部工具条 搜索 选择
    private lazy var gamesToolView: GamesToolView = {
        let view = GamesToolView()
        view.isHidden = true
        ///搜索变更
        view.didSearchChange = { [weak self] string in
            guard let self = self else { return }
            if let s = string, !s.isEmpty {
                if !view.selectIcon.isSelected, (self.gamesListView.collectionView.indexPathsForSelectedItems ?? []).count > 0 {
                    self.gamesListView.collectionView.selectItem(at: nil, animated: false, scrollPosition: [])
                }
                self.gamesListView.searchDatas(string: s)
            } else {
                self.gamesListView.stopSearch()
            }
            self.updateTopBlurView()
        }
        ///选择变更
        view.didToolViewSelectionChange = { [weak self] mode in
            guard let self = self else { return }
            UIDevice.generateHaptic()
            self.gamesListView.selectionMode = mode
            self.gamesToolView.foldKeyboard()
            switch mode {
            case .normalMode:
                //隐藏editBar
                self.setEditToolBar(show: false)
            case .selectionMode:
                break
            case .selectAll:
                let totalGamesCountForCurrentMode = self.gamesListView.totalGamesCountForCurrentMode
                self.setEditToolBar(show: totalGamesCountForCurrentMode > 0, singleSelect: totalGamesCountForCurrentMode == 1)
            case .deSelectAll:
                self.setEditToolBar(show: false)
            }
            self.updateTopBlurView()
        }
        view.didSearchTextResignFirstResponder = { [weak self] in
            self?.gamesListView.collectionView.becomeFirstResponder()
        }
        return view
    }()
    ///游戏列表
    private lazy var gamesListView: GameListView = {
        let view = GameListView()
        ///选择变更
        view.didListViewSelectionChange = { [weak self] selectionType in
            guard let self = self else { return }
            UIDevice.generateHaptic()
            self.gamesToolView.updateSelectIconLabel(selectionType: selectionType)
            switch selectionType {
            case .selectAll:
                self.setEditToolBar(show: true, singleSelect: false)
            case .selectSome(onlyOne: let onlyOne):
                self.setEditToolBar(show: true, singleSelect: onlyOne)
            case .selectNone:
                self.setEditToolBar(show: false)
            }
        }
        view.didUpdateToolView = { [weak self] show, showCorner in
            if show {
                UIView.normalAnimate {
                    self?.gamesToolView.alpha = 1
                }
            } else {
                UIView.springAnimate {
                    self?.gamesToolView.alpha = 0
                }
            }
            UIView.springAnimate {
                self?.gamesToolView.backgroundGradientView.isHidden = !showCorner
            }
            
        }
        view.didScroll = { [weak self] in
            guard let self = self else { return }
            self.gamesToolView.foldKeyboard()
        }
        view.didDatasUpdate = { [weak self] empty in
            guard let self = self else { return }
            if empty {
                self.gamesToolView.stopSearch()
            }
            self.gamesToolView.isHidden = empty
        }
        return view
    }()
    
    ///选择模式的时候会触发底部弹起的工具条
    private lazy var gamesEditToolBar: GameEditToolBar = {
        let view = GameEditToolBar()
        view.didSelectItem = { [weak self] item in
            guard let self = self else { return }
            self.gamesListView.editGame(item: item)
            self.setEditToolBar(show: false)
            self.gamesToolView.selectIcon.isSelected = false
            self.gamesToolView.updateSelectIconLabel(selectionType: .selectNone)
            self.gamesToolView.didToolViewSelectionChange?(.normalMode)
        }
        return view
    }()
    
    private lazy var playHistoryView: PlayHistoryView = {
        let view = PlayHistoryView()
        view.needToHideSideMenu = { [weak self] in
            guard let self = self else { return }
            self.hideSideMenu()
        }
        view.didTapGame = { [weak self] game in
            guard let self = self else { return }
            self.hideSideMenu {
                if Settings.defalut.quickGame {
                    PlayViewController.startGame(game: game)
                } else {
                    topViewController()?.present(GameInfoViewController(game: game), animated: true)
                }
            }
        }
        view.didTapGameRetro = { [weak self] game in
            guard let self = self else { return }
            self.hideSideMenu {
                if let _ = AchievementsUser.getUser() {
                    topViewController()?.present(RetroAchievementsListViewController(game: game), animated: true)
                } else {
                    //先进行登录
                    let vc = RetroAchievementsViewController()
                    vc.dismissAfterLoginSuccess = { [weak self] in
                        topViewController()?.present(RetroAchievementsListViewController(game: game), animated: true)
                    }
                    topViewController()?.present(vc, animated: true)
                }
            }
        }
        return view
    }()
    
    private var controllersSettingView: ControllersSettingView = {
        let view = ControllersSettingView()
        return view
    }()
    
    var setHomeTabBar: ((_ show: Bool)->Void)?
    
    private weak var sideMenu: UIViewController?
    
    private let GameEditToolBarHeightMax = 205.0
    private let GameEditToolBarHeightMin = 116.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        //处理Launch Link
        if let launchGameID = ApplicationSceneDelegate.launchGameID {
            ApplicationSceneDelegate.launchGameID = nil
            let realm = Database.realm
            if let game = realm.object(ofType: Game.self, forPrimaryKey: launchGameID) {
                PlayViewController.startGame(game: game)
            }
        }
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        Log.debug("gamesListView becomeFirstResponder")
        return gamesListView.collectionView.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        Log.debug("gamesListView resignFirstResponder")
        return gamesListView.collectionView.resignFirstResponder()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.isPad {
            hideSideMenu { [weak self] in
                self?.updateViews()
            }
        } else if UIDevice.isPhone {
            self.gamesToolView.stopSearch()
            self.gamesToolView.stopSelect()
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.hideSideMenu { [weak self] in
                    self?.updateViews()
                }
            }
        }
    }
    
    private func setupViews() {
        if UIDevice.isPhone {
            //iPhone布局
            view.addSubview(gamesListView)
            gamesListView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            view.addSubview(topBlurView)
            
            view.addSubview(gamesNavigationView)
            gamesNavigationView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Constants.Size.ContentInsetTop)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ItemHeightMid)
            }
            
            view.addSubview(gamesToolView)
            gamesToolView.snp.makeConstraints { make in
                make.top.equalTo(gamesNavigationView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ItemHeightHuge)
            }
            
            
            topBlurView.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.bottom.equalTo(gamesNavigationView)
            }
            
            view.addSubview(gamesEditToolBar)
            gamesEditToolBar.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(GameEditToolBarHeightMax)
                make.bottom.equalToSuperview().offset(GameEditToolBarHeightMax)
            }
            
            if UIDevice.isLandscape {
                updateViews()
            }
            
        } else {
            //iPad布局
            view.backgroundColor = .black
            
            view.addSubview(gamesListView)
            gamesListView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            view.addSubview(topBlurView)
            
            view.addSubview(gamesNavigationView)
            gamesNavigationView.controllerButton.isHidden = false
            gamesNavigationView.historyButton.isHidden = false
            
            gamesNavigationView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Constants.Size.ContentInsetTop)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ItemHeightMid)
            }
            
            view.addSubview(gamesToolView)
            gamesToolView.snp.makeConstraints { make in
                make.top.equalTo(gamesNavigationView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ItemHeightHuge)
            }
            
            topBlurView.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.bottom.equalTo(gamesNavigationView)
            }
            
            view.addSubview(gamesEditToolBar)
            gamesEditToolBar.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(GameEditToolBarHeightMax)
                make.bottom.equalToSuperview().offset(GameEditToolBarHeightMax)
            }
            
            view.addSubview(cornerMaskViewForiPad)
            cornerMaskViewForiPad.snp.makeConstraints { make in
                make.edges.equalTo(gamesListView)
            }
            cornerMaskViewForiPad.isHidden = true
        }
    }

    
    private func setEditToolBar(show: Bool, singleSelect: Bool = true) {
        
        let show = gamesToolView.selectIcon.isSelected ? show : false
        
        gamesEditToolBar.isSingleGame = singleSelect
        gamesEditToolBar.snp.updateConstraints { make in
            if show {
                make.bottom.equalToSuperview()
                make.height.equalTo(singleSelect ? GameEditToolBarHeightMax : GameEditToolBarHeightMin)
            } else {
                make.bottom.equalToSuperview().offset(singleSelect ? GameEditToolBarHeightMax : GameEditToolBarHeightMin)
            }
        }
        UIView.springAnimate { [weak self] in
            self?.view.layoutIfNeeded()
        }
        setHomeTabBar?(!show)
    }
    
    private func showSideMenu(leftSide: Bool) {
        var leftSide = leftSide
        let vc: UIViewController
        if Locale.isRTLLanguage {
            leftSide = !leftSide
            vc = leftSide ? PlayHistoryViewController(playHistoryView: playHistoryView) : ControllersSettingViewController(controllersSettingView: controllersSettingView)
        } else {
            vc = leftSide ? ControllersSettingViewController(controllersSettingView: controllersSettingView) : PlayHistoryViewController(playHistoryView: playHistoryView)
        }
        UIDevice.generateHaptic()
        let menu = ControllableSideMenu(rootViewController: vc)
        menu.navigationBar.isHidden = true
        menu.presentDuration = Constants.Numbers.LongAnimationDuration
        menu.dismissDuration = Constants.Numbers.LongAnimationDuration
        menu.leftSide = leftSide
        menu.menuWidth = Constants.Size.SideMenuWidth
        menu.presentationStyle = SideMenuShowStyle()
        sideMenu = menu
        topViewController()?.present(menu, animated: true)
    }
    
    private func hideSideMenu(completion: (()->Void)? = nil) {
        if let sideMenu = sideMenu {
            sideMenu.dismiss(animated: true, completion: completion)
        } else {
            completion?()
        }
    }
    
    ///更新顶部的模糊视图 如果编辑模式 则toolView不会隐藏 所以需要将blurView加大 反之则需要减小
    private func updateTopBlurView() {
        topBlurView.snp.updateConstraints { make in
            make.bottom.equalTo(self.gamesNavigationView).offset((gamesListView.isSelectionMode || gamesListView.isSearchMode) ? Constants.Size.ItemHeightHuge : 0)
        }
    }
    
    private func updateViews() {
        if UIDevice.isPad {
            // do nothing
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                self.gamesListView.collectionView.reloadData()
            }
        } else if UIDevice.isPhone {
            if UIDevice.isLandscape {
                gamesNavigationView.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(0)
                }
                gamesToolView.isHidden = true
                topBlurView.snp.updateConstraints { make in
                    make.leading.equalToSuperview().inset(-Constants.Size.SafeAera.left)
                    make.trailing.equalToSuperview().inset(-Constants.Size.SafeAera.right)
                }
            } else {
                gamesNavigationView.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(Constants.Size.ContentInsetTop)
                }
                gamesToolView.isHidden = false
                topBlurView.snp.updateConstraints { make in
                    make.leading.equalToSuperview()
                    make.trailing.equalToSuperview()
                }
            }
            gamesListView.updateRotation()
        }
    }
    
    override func handleScreenPanGesture(edges: UIRectEdge) {
        if UIDevice.isPhone || (UIDevice.isPad && !UIDevice.isLandscape) {
            if edges == .left {
                showSideMenu(leftSide: true)
            } else if edges == .right {
                showSideMenu(leftSide: false)
            }
        }
    }
}

extension GamesViewController: UIControllerPressable {
    override var keyCommands: [UIKeyCommand]? {
        var commands = super.keyCommands ?? []
        commands.append(UIKeyCommand(input: "[", modifierFlags: [], action: #selector(didGamesViewKeyboardPress)))
        commands.append(UIKeyCommand(input: "]", modifierFlags: [], action: #selector(didGamesViewKeyboardPress)))
        return commands
    }
    
    
    func didControllerPress(key: KeyboardKit.UIControllerKey) {
        if !(UIDevice.isPad && UIDevice.isLandscape) {
            if key == .l2 {
                showSideMenu(leftSide: true)
            } else if key == .r2 {
                showSideMenu(leftSide: false)
            }
        }
    }
    
    @objc func didGamesViewKeyboardPress(_ sender: UIKeyCommand) {
        if let inputString = sender.input, !(UIDevice.isPad && UIDevice.isLandscape) {
            if inputString == "[" {
                showSideMenu(leftSide: true)
            } else if inputString == "]" {
                showSideMenu(leftSide: false)
            }
        }
    }
    
}
