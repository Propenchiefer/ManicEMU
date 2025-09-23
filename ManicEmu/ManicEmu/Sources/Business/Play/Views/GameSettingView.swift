//
//  GameSettingView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/5.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ProHUD
import ManicEmuCore
import KeyboardKit


class GameSettingView: BaseView {
    
    static func estimatedHeight(for contentWidth: CGFloat, hasGrabber: Bool = true) -> CGFloat {
        let line = 4//默认显示4行
        let itemHeight = (contentWidth - totalHorizontalSpacing) / CGFloat(line) //宽和高相等
        return (hasGrabber ? 20 : 0) + Constants.Size.ItemHeightMid + Constants.Size.ContentSpaceMin + itemHeight * CGFloat(line) + itemSpacing * CGFloat(line-1) + Constants.Size.ContentInsetBottom
    }
    /// 充当导航条
    private var navigationBlurView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)))
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.didTapClose?()
        }
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = KeyboardCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: SettingItemCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: GameSettingSortCollectionReusableView.self)
        view.dataSource = self
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: Constants.Size.ContentSpaceMin, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        if isEditingMode {
            view.addLongPressGesture { [weak self] gesture in
                guard let self = self else { return }
                let location = gesture.location(in: self.collectionView)
                
                switch gesture.state {
                case .began:
                    guard let indexPath = self.collectionView.indexPathForItem(at: location) else { return }
                    self.collectionView.beginInteractiveMovementForItem(at: indexPath)
                    // 添加触觉反馈（可选）
                    UIDevice.generateHaptic()
                    // 添加动画效果（可选）
                    self.animateCellWhenDragBegin(at: indexPath)
                case .changed:
                    self.collectionView.updateInteractiveMovementTargetPosition(location)
                case .ended:
                    self.collectionView.endInteractiveMovement()
                    // 结束动画（可选）
                    self.animateCellWhenDragEnd()
                case .cancelled, .failed:
                    self.collectionView.cancelInteractiveMovement()
                default:
                    break
                }
            }
        } else {
            view.buttonPress = { [weak self] key in
                guard let self else { return }
                if key == .a {
                    if let selectedItems = self.collectionView.indexPathsForSelectedItems,
                        selectedItems.count == 1,
                        let selectedItem = selectedItems.first {
                        let _ = self.collectionView(self.collectionView, didSelectItemAt: selectedItem)
                    }
                } else if key == .b {
                    self.didTapClose?()
                }
            }
        }
        return view
    }()
    
    private let game: Game
    
    private let isEditingMode: Bool
    
    private let isMappingMode: Bool
    
    private var displayGamesFunctionCount = Settings.defalut.displayGamesFunctionCount
    
    private var gameSettings = [GameSetting]()
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    ///点击item回调
    var didSelectItem: ((_ item: GameSetting)->Void)?
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    private var settingsUpdateToken: Any? = nil
    private var gameUpdateToken: Any? = nil
    init(game: Game, isEditingMode: Bool = false, isMappingMode: Bool = false) {
        self.game = game
        self.isEditingMode = isEditingMode
        self.isMappingMode = isMappingMode
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        updateSettings()
        
        if !isMappingMode {
            settingsUpdateToken = Settings.defalut.observe(keyPaths: [\Settings.gameFunctionList, \Settings.displayGamesFunctionCount]) { [weak self] change in
                guard let self = self else { return }
                switch change {
                case .change(_, _):
                    self.updateSettings()
                default:
                    break
                }
            }
            
            if !self.isEditingMode {
                gameUpdateToken = self.game.observe(keyPaths: [\Game.speed]) { [weak self] change in
                    guard let self = self else { return }
                    switch change {
                    case .change(_, _):
                        for (index, setting) in self.gameSettings.enumerated() {
                            if setting.type == .fastForward, setting.fastForwardSpeed != self.game.speed {
                                var item = setting
                                item.fastForwardSpeed = self.game.speed
                                self.gameSettings[index] = item
                                let indexPath = IndexPath(row: index, section: 0)
                                var isSelected = false
                                if let selectedItems = self.collectionView.indexPathsForSelectedItems, selectedItems.contains([indexPath]) {
                                    isSelected = true
                                }
                                self.collectionView.reloadItems(at: [indexPath])
                                if isSelected {
                                    DispatchQueue.main.asyncAfter(delay: 0.35) {
                                        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                                    }
                                }
                                break
                            }
                        }
                    default:
                        break
                    }
                }
            }
            
            addSubview(navigationBlurView)
            navigationBlurView.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ItemHeightMid)
            }
            
            let headerLabel = UILabel()
            headerLabel.font = Constants.Font.title(size: .s, weight: .bold)
            headerLabel.textColor = Constants.Color.LabelPrimary
            headerLabel.text = isEditingMode ? R.string.localizable.gameSettingFunctionSort() : "MENU"
            navigationBlurView.addSubview(headerLabel)
            headerLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            }
            
            navigationBlurView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            }
        }

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            if isMappingMode {
                make.edges.equalToSuperview()
            } else {
                make.top.equalTo(navigationBlurView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
        
        if isEditingMode {
            collectionView.allowsSelection = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateSettings() {
        let settings = Settings.defalut
        displayGamesFunctionCount = settings.displayGamesFunctionCount
        gameSettings = settings.gameFunctionList.compactMap { itemTypeValue in
            if let itemType = GameSetting.ItemType(rawValue: itemTypeValue) {
                if isMappingMode {
                    return GameSetting(type: itemType)
                } else {
                    return GameSetting(type: itemType,
                                       volumeOn: game.volume,
                                       fastForwardSpeed: game.speed,
                                       resolution: game.resolution == .undefine ? .one : game.resolution,
                                       hapticType: game.haptic,
                                       controllerType: game.controllerType,
                                       orientation: game.orientation,
                                       isFullScreen: game.forceFullSkin,
                                       palette: game.pallete,
                                       currentDiskIndex: game.currentDiskIndex)
                }
            }
            return nil
        }
        collectionView.reloadData()
    }
    
    func updateMappingMode(gameType: GameType) {
        guard isMappingMode else { return }
        game.gameType = gameType
        collectionView.reloadData()
    }
    
    static let horizontalEdgeSpacing = UIDevice.isPad ? Constants.Size.ContentSpaceHuge : Constants.Size.ContentSpaceMid
    static let itemSpacing = UIDevice.isPad ? Constants.Size.ContentSpaceMax : Constants.Size.ContentSpaceMin
    static let itemsPerRow = 4
    static let totalHorizontalSpacing = CGFloat(itemsPerRow - 1) * itemSpacing + horizontalEdgeSpacing*2
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self = self else { return nil }
            
            let collectionViewWidth = environment.container.effectiveContentSize.width
            let itemWidth = (collectionViewWidth - Self.totalHorizontalSpacing) / CGFloat(Self.itemsPerRow)
            
            // 定义 item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(itemWidth) // 保证高度等于宽度
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // 定义 group
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemWidth) // 高度等于 item 高度
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: Self.itemsPerRow
            )
            group.interItemSpacing = .fixed(Self.itemSpacing) // 确保 item 之间间距固定
            
            // 定义 section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Self.itemSpacing // 确保行间距和列间距相等
            section.contentInsets = NSDirectionalEdgeInsets(top: self.isEditingMode ? Self.itemSpacing : 0,
                                                            leading: Self.horizontalEdgeSpacing,
                                                            bottom: self.isEditingMode ? Self.itemSpacing : 0,
                                                            trailing: Self.horizontalEdgeSpacing)
            if self.isEditingMode {
                let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(80)),
                                                                             elementKind: UICollectionView.elementKindSectionFooter,
                                                                             alignment: .bottom)
                section.boundarySupplementaryItems.append(footerItem)
            }
            
            return section
            
        }
        return layout
    }
    
    private func animateCellWhenDragBegin(at indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.normalAnimate {
                cell.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                cell.alpha = 0.8
            }
        }
    }

    private func animateCellWhenDragEnd() {
        collectionView.visibleCells.forEach { cell in
            UIView.normalAnimate {
                cell.transform = .identity
                cell.alpha = 1.0
            }
        }
    }
}

extension GameSettingView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        isEditingMode ? 2 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isEditingMode {
            if section == 0 {
                return displayGamesFunctionCount
            } else {
                return gameSettings.count - displayGamesFunctionCount
            }
        } else {
            return gameSettings.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item: GameSetting
        if isEditingMode {
            item = gameSettings[indexPath.section == 0 ? indexPath.row : indexPath.row + displayGamesFunctionCount]
        } else {
            item = gameSettings[indexPath.row]
        }
        let cell = collectionView.dequeueReusableCell(withClass: SettingItemCollectionViewCell.self, for: indexPath)
        var specialTitle: String? = nil
        if item.type == .palette {
            if game.gameType == .vb {
                specialTitle = item.palette.paletteTitleForVB
            } else if game.gameType == .pm {
                specialTitle = item.palette.paletteTitleForPM
            }
        } else if item.type == .resolution {
            if game.gameType == .ps1 {
                specialTitle = R.string.localizable.gameSettingResolution(item.resolution.resolutionTitleForPS1)
            } else if game.isN64ParaLLEl {
                specialTitle = R.string.localizable.gameSettingResolution(item.resolution.resolutionTitleForN64ParaLLEl)
            }
        }
        
        cell.setData(item: item, editable: isEditingMode, isPlus: indexPath.section != 0, enable: item.enable(for: game.gameType, defaultCore: game.defaultCore), mappingMode: isMappingMode, specialTitle: specialTitle)
        if isEditingMode {
            cell.editButton.addTapGesture { [weak self] gesture in
                guard let self = self else { return }
                UIDevice.generateHaptic()
                let settings = Settings.defalut
                if indexPath.section == 0 {
                    //减少选项
                    self.collectionView.performBatchUpdates {
                        //更新UI
                        self.displayGamesFunctionCount -= 1
                        self.collectionView.moveItem(at: indexPath, to: IndexPath(row: 0, section: 1))
                    } completion: { _ in
                        //更新数据源
                        Settings.change { realm in
                            if indexPath.row != self.displayGamesFunctionCount {
                                settings.gameFunctionList.move(from: indexPath.row, to: self.displayGamesFunctionCount)
                            }
                            settings.displayGamesFunctionCount -= 1
                        }
                    }
                } else {
                    //新增选项
                    func updateDatas() {
                        Settings.change { realm in
                            let fromIndex = settings.displayGamesFunctionCount + indexPath.row
                            var toIndex = settings.displayGamesFunctionCount
                            if toIndex == Constants.Numbers.GameFunctionButtonCount {
                                toIndex -= 1
                            }
                            if fromIndex != toIndex {
                                settings.gameFunctionList.move(from: fromIndex, to: toIndex)
                            }
                            if settings.displayGamesFunctionCount < Constants.Numbers.GameFunctionButtonCount {
                                settings.displayGamesFunctionCount += 1
                            }
                        }
                    }
                    
                    self.collectionView.performBatchUpdates {
                        //更新UI
                        self.displayGamesFunctionCount += 1
                        var toIndex = self.displayGamesFunctionCount - 1
                        if self.displayGamesFunctionCount > Constants.Numbers.GameFunctionButtonCount {
                            toIndex -= 1
                        }
                        self.collectionView.moveItem(at: indexPath, to: IndexPath(row: toIndex, section: 0)) //先将section1的item移到section0的末尾
                    } completion: { _ in
                        if self.displayGamesFunctionCount > Constants.Numbers.GameFunctionButtonCount {
                            //section0的个数超了 需要将section0的最后一个item移到section1
                            self.collectionView.performBatchUpdates {
                                self.displayGamesFunctionCount -= 1
                                self.collectionView.moveItem(at: IndexPath(row: self.displayGamesFunctionCount, section: 0), to: IndexPath(row: 0, section: 1))
                            } completion: { _ in
                                updateDatas()
                            }
                        } else {
                            updateDatas()
                        }
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: GameSettingSortCollectionReusableView.self, for: indexPath)
        footer.descLabel.text = indexPath.section == 0 ? R.string.localizable.functionSortDesc1() : R.string.localizable.functionSortDesc2()
        return footer
    }
}

extension GameSettingView: UICollectionViewDelegate {
    private func updateCellAndCallBack(item: GameSetting, indexPath: IndexPath, reload: Bool = true) {
        if reload {
            var isSelected = false
            if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.contains([indexPath]) {
                isSelected = true
            }
            gameSettings[indexPath.row] = item
            collectionView.reloadItems(at: [indexPath])
            if isSelected {
                DispatchQueue.main.asyncAfter(delay: 0.35) {
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
            }
        }
        didSelectItem?(item)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditingMode {
            return
        }
        var item = gameSettings[indexPath.row]
        guard item.enable(for: game.gameType, defaultCore: game.defaultCore) else {
            UIView.makeToast(message: R.string.localizable.notSupportGameSetting(game.gameType.localizedShortName))
            return
        }
        
        if isMappingMode {
            didSelectItem?(item)
        } else {
            switch item.type {
            case .volume:
                item.volumeOn = !item.volumeOn
                updateCellAndCallBack(item: item, indexPath: indexPath)
                return
            case .fastForward:
                item.fastForwardSpeed = item.fastForwardSpeed.next
                if PurchaseManager.isMember || item.fastForwardSpeed.rawValue > GameSetting.FastForwardSpeed.two.rawValue {
                    updateCellAndCallBack(item: item, indexPath: indexPath, reload: false)
                } else {
                    updateCellAndCallBack(item: item, indexPath: indexPath)
                }
                return
            case .resolution:
                if game.gameType == .ps1 {
                    item.resolution = item.resolution.nextForPS1
                } else if game.isN64ParaLLEl {
                    item.resolution = item.resolution.nextForN64ParaLLEl
                } else {
                    item.resolution = item.resolution.next
                }
                updateCellAndCallBack(item: item, indexPath: indexPath)
                return
            case .haptic:
                item.hapticType = item.hapticType.next
                updateCellAndCallBack(item: item, indexPath: indexPath)
                return
            case .orientation:
                item.orientation = item.orientation.next
                updateCellAndCallBack(item: item, indexPath: indexPath)
                return
            case .palette:
                if game.gameType == .vb {
                    item.palette = item.palette.nextForVB
                } else if game.gameType == .pm {
                    item.palette = item.palette.nextForPM
                } else {
                    item.palette = item.palette.next
                }
                updateCellAndCallBack(item: item, indexPath: indexPath)
                return
            case .toggleFullscreen:
                item.isFullScreen = !item.isFullScreen
                updateCellAndCallBack(item: item, indexPath: indexPath)
            case .swapDisk:
                if game.supportSwapDisc {
                    item.currentDiskIndex = item.currentDiskIndex + 1 < game.totalDiskCount ? item.currentDiskIndex + 1 : 0
                    game.currentDiskIndex = item.currentDiskIndex
                    updateCellAndCallBack(item: item, indexPath: indexPath)
                    return
                }
            default:
                break
            }
            didSelectItem?(item)
        }
    }
    
    //长按弹出可交互菜单
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first, !isEditingMode, !isMappingMode else { return nil }
        var item = gameSettings[indexPath.row]
        guard item.enable(for: game.gameType, defaultCore: game.defaultCore) else { return nil }
        if item.type == .quickLoadState {
            //设置快速读档
            let actions = self.game.gameSaveStates.filter({ $0.type == .manualSaveState }).suffix(5).map { state in
                var image: UIImage? = nil
                if let coverData = state.stateCover?.storedData() {
                    image = UIImage(data: coverData)
                }
                return UIAction(title: state.date.dateTimeString(ofStyle: .short), image: image) { [weak self] _ in
                    guard let self = self else { return }
                    //加载存档
                    item.loadState = state
                    self.didSelectItem?(item)
                }
            }
            if actions.count > 0 {
                return UIContextMenuConfiguration(actionProvider: { _ in UIMenu(children: Array(actions)) })
            }
        } else if item.type == .fastForward {
            //设置快进
            let actions = GameSetting.FastForwardSpeed.allCases.map { speed in
                UIAction(title: speed == .one ? R.string.localizable.gameSettingFastForwardResume() : speed.title,
                         image: speed == game.speed ? UIImage(symbol: .checkmarkCircleFill) : nil) { [weak self] _ in
                    guard let self = self else { return }
                    item.fastForwardSpeed = speed
                    self.updateCellAndCallBack(item: item, indexPath: indexPath)
                }
            }
            return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
        } else if item.type == .resolution {
            //设置分辨率
            if game.gameType == .ps1 {
                let actions = GameSetting.Resolution.ResolutionForPS1.filter({ $0 != .undefine }).map { resolution in
                    UIAction(title: R.string.localizable.gameSettingResolution(resolution.resolutionTitleForPS1),
                             image: resolution == game.resolution ? UIImage(symbol: .checkmarkCircleFill) : nil) { [weak self] _ in
                        guard let self = self else { return }
                        item.resolution = resolution
                        self.updateCellAndCallBack(item: item, indexPath: indexPath)
                    }
                }
                return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
            } else if game.isN64ParaLLEl {
                let actions = GameSetting.Resolution.ResolutionForN64ParaLLEl.filter({ $0 != .undefine }).map { resolution in
                    UIAction(title: R.string.localizable.gameSettingResolution(resolution.resolutionTitleForN64ParaLLEl),
                             image: resolution == game.resolution ? UIImage(symbol: .checkmarkCircleFill) : nil) { [weak self] _ in
                        guard let self = self else { return }
                        item.resolution = resolution
                        self.updateCellAndCallBack(item: item, indexPath: indexPath)
                    }
                }
                return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
            } else {
                let actions = GameSetting.Resolution.allCases.filter({ $0 != .undefine }).map { resolution in
                    UIAction(title: resolution.title,
                             image: resolution == game.resolution ? UIImage(symbol: .checkmarkCircleFill) : nil) { [weak self] _ in
                        guard let self = self else { return }
                        item.resolution = resolution
                        self.updateCellAndCallBack(item: item, indexPath: indexPath)
                    }
                }
                return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
            }
        } else if item.type == .haptic {
            //震感设置
            let actions = GameSetting.HapticType.allCases.map { hapticType in
                return UIAction(title: hapticType.title, image: hapticType.image) { [weak self] _ in
                    guard let self = self else { return }
                    item.hapticType = hapticType
                    self.updateCellAndCallBack(item: item, indexPath: indexPath)
                }
            }
            return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
        } else if item.type == .orientation {
            //设置旋转
            let actions = GameSetting.OrientationType.allCases.map { orientation in
                return UIAction(title: orientation.title,
                                image: orientation == game.orientation ? UIImage(symbol: .checkmarkCircleFill) : nil) { [weak self] _ in
                    guard let self = self else { return }
                    item.orientation = orientation
                    self.updateCellAndCallBack(item: item, indexPath: indexPath)
                }
            }
            return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
        } else if item.type == .palette {
            //设置调色板
            if game.gameType == .vb {
                let actions = GameSetting.Palette.PalettesForVB.map { palette in
                    UIAction(title: palette.paletteTitleForVB,
                             image: item.image) { [weak self] _ in
                        guard let self = self else { return }
                        item.palette = palette
                        self.updateCellAndCallBack(item: item, indexPath: indexPath)
                    }
                }
                return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
            } else if game.gameType == .pm {
                let actions = GameSetting.Palette.PalettesForPM.map { palette in
                    UIAction(title: palette.paletteTitleForPM,
                             image: item.image) { [weak self] _ in
                        guard let self = self else { return }
                        item.palette = palette
                        self.updateCellAndCallBack(item: item, indexPath: indexPath)
                    }
                }
                return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
            } else {
                let actions = GameSetting.Palette.allCases.map { palette in
                    UIAction(title: palette == .None ? "None" : palette.shortTitle,
                             image: item.image) { [weak self] _ in
                        guard let self = self else { return }
                        item.palette = palette
                        self.updateCellAndCallBack(item: item, indexPath: indexPath)
                    }
                }
                return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
            }
            
        } else if item.type == .swapDisk, game.supportSwapDisc {
            var actions = [UIAction]()
            for index in 0..<game.totalDiskCount {
                actions.append(UIAction(title: "Disc \(index + 1)",
                                        image: index == game.currentDiskIndex ? UIImage(symbol: .checkmarkCircleFill) : nil,
                                        handler: { [weak self] _ in
                    guard let self = self else { return }
                    item.currentDiskIndex = index
                    self.updateCellAndCallBack(item: item, indexPath: indexPath)
                }))
            }
            return UIContextMenuConfiguration(actionProvider:  { _ in UIMenu(children: actions) })
        }
        return nil
    }
    
    //拖动交互
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let settings = Settings.defalut
        if sourceIndexPath.section == 0 {
            if destinationIndexPath.section == 0 {
                //第1个section内移动
                Settings.change { realm in
                    settings.gameFunctionList.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
                }
            } else {
                //第1个section移到第2个section
                Settings.change { realm in
                    settings.gameFunctionList.move(from: sourceIndexPath.row, to: settings.displayGamesFunctionCount + destinationIndexPath.row - 1)
                    settings.displayGamesFunctionCount -= 1
                }
            }
        } else {
            if destinationIndexPath.section == 0 {
                //第2个section移到第1个section
                Settings.change { realm in
                    settings.gameFunctionList.move(from: settings.displayGamesFunctionCount + sourceIndexPath.row, to: destinationIndexPath.row)
                    if settings.displayGamesFunctionCount < Constants.Numbers.GameFunctionButtonCount {
                        settings.displayGamesFunctionCount += 1
                    }
                }
            } else {
                //第2个section内移动
                Settings.change { realm in
                    settings.gameFunctionList.move(from: settings.displayGamesFunctionCount + sourceIndexPath.row, to: settings.displayGamesFunctionCount + destinationIndexPath.row)
                }
            }
        }
    }
    
}

extension GameSettingView {
    static var isEditingShow: Bool {
        Sheet.find(identifier: "GameSettingViewEditingMode").count > 0 ? true : false
    }
    
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: GameSettingView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game,
                     gameViewRect: CGRect,
                     isEditingMode: Bool = false,
                     menuInsets: UIEdgeInsets? = nil,
                     didSelectItem:((_ item: GameSetting, _ sheet: SheetTarget?)->Bool)? = nil,
                     hideCompletion: (()->Void)? = nil) {
        
        let initializer: ((SheetTarget)->Void) = { sheet in
            sheet.configGamePlayingStyle(isForGameMenu: isEditingMode ? false : true, gameViewRect: gameViewRect, menuInsets: menuInsets, hideCompletion: hideCompletion)
            
            let view = UIView()
            let grabber = UIImageView(image: R.image.grabber_icon())
            grabber.isUserInteractionEnabled = true
            grabber.contentMode = .center
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        // 达到移除的速度
                        sheet.pop(completon: hideCompletion)
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            let grabberHeight = Constants.Size.ContentSpaceTiny*3
            if !isEditingMode {
                view.addSubview(grabber)
                grabber.snp.makeConstraints { make in
                    make.leading.top.trailing.equalToSuperview()
                    make.height.equalTo(grabberHeight)
                }
            }
            
            
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape || menuInsets != nil) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = Constants.Color.BackgroundPrimary
            if !isEditingMode {
                containerView.makeBlur()
            }
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                if isEditingMode {
                    make.edges.equalToSuperview()
                    if let maxHeight = sheet.config.cardMaxHeight {
                        make.height.equalTo(maxHeight)
                    }
                } else {
                    make.top.equalTo(grabber.snp.bottom)
                    make.leading.bottom.trailing.equalToSuperview()
                    if let maxHeight = sheet.config.cardMaxHeight {
                        make.height.equalTo(maxHeight - grabberHeight)
                    }
                }
            }
            
            let settingView = GameSettingView(game: game, isEditingMode: isEditingMode)
            settingView.collectionView.becomeFirstResponder()
            settingView.didSelectItem = { [weak sheet] gameSetting in
                if let needToHide = didSelectItem?(gameSetting, sheet), needToHide {
                    sheet?.pop(completon: hideCompletion)
                }
            }
            settingView.didTapClose = { [weak sheet] in
                sheet?.pop(completon: hideCompletion)
            }
            containerView.addSubview(settingView)
            settingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        if isEditingMode {
            Sheet.lazyPush(identifier: "GameSettingViewEditingMode", handler: initializer)
        } else {
            Sheet.lazyPush(identifier: String(describing: GameSettingView.self), handler: initializer)
        }
    }
}
