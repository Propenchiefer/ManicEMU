//
//  BIOSSelectionView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/6/10.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore
import IceCream

class BIOSSelectionView: BaseView {
    
    private enum SectionIndex: Int, CaseIterable {
        case desc, mcd, ss, ds, ps1, dc
        var title: String {
            switch self {
            case .desc: ""
            case .mcd: GameType.mcd.localizedName
            case .ss: GameType.ss.localizedName
            case .ds: GameType.ds.localizedName
            case .ps1: GameType.ps1.localizedName
            case .dc: GameType.dc.localizedName
            }
        }
        
        var gameType: GameType {
            switch self {
            case .desc: return .notSupport
            case .mcd: return .mcd
            case .ss: return .ss
            case .ds: return .ds
            case .ps1: return .ps1
            case .dc: return .dc
            }
        }
    }
    
    private let datas: [SectionIndex]
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur(blurColor: Constants.Color.BackgroundPrimary)
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: BIOSCollectionViewCell.self)
        view.register(cellWithClass: SettingDescriptionCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: PrimaryHaderReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid, left: 0, bottom: UIDevice.isPad ? (Constants.Size.ContentInsetBottom + Constants.Size.HomeTabBarSize.height + Constants.Size.ContentSpaceMax) : Constants.Size.ContentInsetBottom, right: 0)
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
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(gameType: GameType? = nil, showClose: Bool = true) {
        if let gameType, gameType == .mcd {
            self.datas = [.desc, .mcd]
        } else if let gameType, gameType == .ss {
            self.datas = [.desc, .ss]
        } else if let gameType, gameType == .ds {
            self.datas = [.desc, .ds]
        } else if let gameType, gameType == .ps1 {
            self.datas = [.desc, .ps1]
        } else if let gameType, gameType == .dc {
            self.datas = [.desc, .dc]
        } else {
#if SIDE_LOAD
            self.datas = [.desc, .dc, .ps1, .mcd, .ss, .ds]
#else
            self.datas = [.desc, .dc, .ps1, .ss, .ds]
#endif
        }
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        backgroundColor = Constants.Color.BackgroundPrimary
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let icon = UIImageView(image: UIImage(symbol: .cpu))
        topBlurView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        let headerTitleLabel = UILabel()
        headerTitleLabel.text = "BIOS"
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(icon)
        }
        
        if showClose {
            topBlurView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            guard let self else { return nil }
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            
            
            let sectionType = self.datas[sectionIndex]
            let itemHeight: CGFloat = sectionType == .desc ? 120 : BIOSCollectionViewCell.CellHeight(gameType: sectionType.gameType)
            
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: sectionType == .desc ? .estimated(itemHeight) : .absolute(itemHeight)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            
            if sectionType != .desc {
                //header布局
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(44)),
                                                                             elementKind: UICollectionView.elementKindSectionHeader,
                                                                             alignment: .top)
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
            }
            
            return section
        }
        return layout
    }
}

extension BIOSSelectionView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = datas[indexPath.section]
        if section == .desc {
            let cell = collectionView.dequeueReusableCell(withClass: SettingDescriptionCollectionViewCell.self, for: indexPath)
            cell.descLabel.text = R.string.localizable.biosAlert()
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: BIOSCollectionViewCell.self, for: indexPath)
            cell.setData(gameType: section.gameType) { [weak self] in
                //导入成功 进行刷新
                self?.collectionView.reloadData()
                if section.gameType == .ds {
                    let ndsBiosCompletion = section.gameType.isNDSBiosComplete()
                    let realm = Database.realm
                    var games = [Game]()
                    if ndsBiosCompletion.isDSComplete, realm.object(ofType: Game.self, forPrimaryKey: Game.DsHomeMenuPrimaryKey) == nil {
                        let game = Game()
                        game.id = Game.DsHomeMenuPrimaryKey
                        game.name = Game.DsHomeMenuPrimaryKey
                        games.append(game)
                    }
                    if ndsBiosCompletion.isDsiComplete, realm.object(ofType: Game.self, forPrimaryKey: Game.DsiHomeMenuPrimaryKey) == nil {
                        //新增Home Menu (DSi)
                        let game = Game()
                        game.id = Game.DsiHomeMenuPrimaryKey
                        game.name = Game.DsiHomeMenuPrimaryKey
                        games.append(game)
                    }
                    if games.count > 0 {
                        games.forEach { game in
                            game.fileExtension = "ds"
                            game.gameType = .ds
                            game.importDate = Date()
                        }
                        try? realm.write { realm.add(games) }
                    }
                }
            }
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: PrimaryHaderReusableView.self, for: indexPath)
        let section = datas[indexPath.section]
        let matt = NSMutableAttributedString(string: section.title, attributes: [.font: Constants.Font.title(size: .s), .foregroundColor: Constants.Color.LabelPrimary])
        if section == .ps1 {
            matt.append(NSAttributedString(string: " (\(R.string.localizable.chooseOne()))", attributes: [.font: Constants.Font.body(size: .m), .foregroundColor: Constants.Color.LabelSecondary]))
        }
        header.titleLabel.attributedText = matt
        return header
    }
}

extension BIOSSelectionView: UICollectionViewDelegate {
    
}
