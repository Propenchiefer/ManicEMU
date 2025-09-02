//
//  SettingsListView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/28.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import RealmSwift
import MessageUI

class SettingsListView: BaseView {
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur(blurColor: Constants.Color.Background)
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: SettingsItemCollectionViewCell.self)
        view.register(cellWithClass: MembershipCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: TitleBackgroundColorHaderCollectionReusableView.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: SettingsListFooterCollectionReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ContentInsetTop + Constants.Size.ItemHeightMid, left: 0, bottom: Constants.Size.ContentInsetBottom + Constants.Size.HomeTabBarSize.height + Constants.Size.ContentSpaceMax, right: 0)
        return view
    }()
    
    enum SectionIndex: Int, CaseIterable {
        case general = 1, advance, support, others
        var title: String {
            switch self {
            case .general:
                R.string.localizable.generalSettingTitle()
            case .advance:
                R.string.localizable.advanceSettingTitle()
            case .support:
                R.string.localizable.supportSettingTitle()
            case .others:
                R.string.localizable.othersSettingTitle()
            }
        }
    }
    
    private var settingsUpdateToken: NotificationToken? = nil
    private lazy var items: [SectionIndex: [SettingItem]] = {
        var datas = [SectionIndex: [SettingItem]]()
        //监听数据的变化
        settingsUpdateToken = Settings.defalut.observe(keyPaths: [\Settings.language,
                                                                   \Settings.quickGame,
                                                                   \Settings.autoSaveState,
                                                                   \Settings.airPlay,
                                                                   \Settings.fullScreenWhenConnectController,
                                                                   \Settings.respectSilentMode]) { [weak self] change in
            guard let self = self else { return }
            switch change {
            case .change(let object, let properties):
                //更新数据源
                for property in properties {
                    if let newvalue = property.newValue {
                        for sectionIndex in SectionIndex.allCases {
                            var stopIter = false
                            if let itemArray = self.items[sectionIndex] {
                                for (itemIndex, item) in itemArray.enumerated() {
                                    if item.type.rawValue == property.name {
                                        stopIter = true
                                        var newItem = item
                                        if item.type == .language {
                                            if let language = property.newValue as? String {
                                                newItem.arrowDetail = Locale.getSystemLanguageDisplayName(preferredLanguage: language)
                                            }
                                        } else {
                                            if let isOn = property.newValue as? Bool {
                                                newItem.isOn = isOn
                                            }
                                        }
                                        self.items[sectionIndex]?[itemIndex] = newItem
                                        break
                                    }
                                }
                            }
                            if stopIter {
                                break
                            }
                        }
                    }
                    Log.debug("设置更新 Property '\(property.name)' changed from \(property.oldValue == nil ? "nil" : property.oldValue!) to '\(property.newValue!)'")
                }
            default:
                break
            }
        }
        for section in SectionIndex.allCases {
            if section == .general {
                datas[section] = [SettingItem(type: .theme),
                                  SettingItem(type: .quickGame, isOn: Settings.defalut.quickGame),
                                  SettingItem(type: .autoSaveState, isOn: Settings.defalut.autoSaveState)]
            } else if section == .advance {
#if SIDE_LOAD
                datas[section] = [SettingItem(type: .airPlay, isOn: Settings.defalut.airPlay),
                                  SettingItem(type: .fullScreenWhenConnectController, isOn: Settings.defalut.fullScreenWhenConnectController),
                                  SettingItem(type: .bios),
                                  SettingItem(type: .respectSilentMode, isOn: Settings.defalut.respectSilentMode),
                ]
#else
                datas[section] = [SettingItem(type: .airPlay, isOn: Settings.defalut.airPlay),
                                  SettingItem(type: .iCloud, isOn: Settings.defalut.iCloudSyncEnable),
                                  SettingItem(type: .fullScreenWhenConnectController, isOn: Settings.defalut.fullScreenWhenConnectController),
                                  SettingItem(type: .bios),
                                  SettingItem(type: .respectSilentMode, isOn: Settings.defalut.respectSilentMode),
                ]
#endif
            } else if section == .support {
                datas[section] = [SettingItem(type: .FAQ),
                                  SettingItem(type: .feedback),
                                  SettingItem(type: .qq),
                                  SettingItem(type: .telegram),
                                  SettingItem(type: .discord)]
            } else if section == .others {
                datas[section] = [SettingItem(type: .shareApp),
                                  SettingItem(type: .clearCache, arrowDetail: CacheManager.totleSize),
                                  SettingItem(type: .language, arrowDetail: Locale.getSystemLanguageDisplayName(preferredLanguage: Settings.defalut.language)),
                                  SettingItem(type: .userAgreement),
                                  SettingItem(type: .privacyPolicy)]
            }
        }
        return datas
    }()
    
    private let MembershipViewHeight = 130.0
    
    private var membershipNotification: Any? = nil
    
    var didTapDetail: ((UIViewController)->Void)? = nil
    
    deinit {
        if let membershipNotification = membershipNotification {
            NotificationCenter.default.removeObserver(membershipNotification)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ContentInsetTop + Constants.Size.ItemHeightMid)
        }
        
        let headerTitleLabel = UILabel()
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.text = R.string.localizable.tabbarTitleSettings()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(Constants.Size.ContentInsetTop)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        membershipNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.MembershipChange, object: nil, queue: .main) { [weak self] notification in
            self?.collectionView.reloadData()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            
            let lastSectionIndex = SectionIndex.allCases.last!.rawValue
            
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(sectionIndex == 0 ? self.MembershipViewHeight : Constants.Size.ItemHeightMax)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: sectionIndex == 0 ? Constants.Size.ContentSpaceMin : 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            
            if sectionIndex > 0 {
                //header布局
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(44)),
                                                                             elementKind: UICollectionView.elementKindSectionHeader,
                                                                             alignment: .top)
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
                if sectionIndex == lastSectionIndex {
                    section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: SettingsBottomDecorationCollectionReusableView.self))]
                } else {
                    section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: SettingsDecorationCollectionReusableView.self))]
                }
            }
            
            if sectionIndex == lastSectionIndex {
                let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(538)),
                                                                             elementKind: UICollectionView.elementKindSectionFooter,
                                                                             alignment: .bottom)
                section.boundarySupplementaryItems.append(footerItem)
            }
            
            return section
        }
        layout.register(SettingsDecorationCollectionReusableView.self, forDecorationViewOfKind: String(describing: SettingsDecorationCollectionReusableView.self))
        layout.register(SettingsBottomDecorationCollectionReusableView.self, forDecorationViewOfKind: String(describing: SettingsBottomDecorationCollectionReusableView.self))
        return layout
    }
    
    class SettingsDecorationCollectionReusableView: UICollectionReusableView {
        var backgroundView: UIView = {
            let view = UIView()
            view.layerCornerRadius = Constants.Size.CornerRadiusMax
            view.backgroundColor = Constants.Color.BackgroundPrimary
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Constants.Size.ItemHeightMin)
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class SettingsBottomDecorationCollectionReusableView: UICollectionReusableView {
        var backgroundView: UIView = {
            let view = UIView()
            view.layerCornerRadius = Constants.Size.CornerRadiusMax
            view.backgroundColor = Constants.Color.BackgroundPrimary
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Constants.Size.ItemHeightMin)
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMin-526)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension SettingsListView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return items[SectionIndex(rawValue: section)!]!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: MembershipCollectionViewCell.self, for: indexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: SettingsItemCollectionViewCell.self, for: indexPath)
            let item = items[SectionIndex(rawValue: indexPath.section)!]![indexPath.row]
            cell.setData(item: item)
            cell.switchButton.onChange(handler: nil)
            cell.switchButton.onDisableTap(handler: nil)
            if item.type == .quickGame {
                cell.switchButton.onChange { value in
                    //快速游戏设置
                    Settings.change { _ in
                        Settings.defalut.quickGame = value
                    }
                }
            } else if item.type == .airPlay {
                cell.switchButton.onChange { value in
                    //airPlay设置
                    Settings.change { _ in
                        Settings.defalut.airPlay = value
                    }
                }
                cell.switchButton.onDisableTap {
                    topViewController()?.present(PurchaseViewController(featuresType: .airplay), animated: true)
                }
            } else if item.type == .iCloud {
                cell.switchButton.onChange { [weak cell] value in
                    //icloud设置
                    if value {
                        UIView.makeAlert(title: R.string.localizable.iCloudTipsTitle(),
                                         detail: R.string.localizable.iCloudTipsDetail(),
                                         confirmTitle: R.string.localizable.iCloudConfirm(), cancelAction: { [weak cell] in
                            cell?.switchButton.setOn(false)
                        }, confirmAction: {
                            Settings.defalut.iCloudSyncEnable = value
                            if value, let iCloudServiceEnable = SyncManager.shared.iCloudServiceEnable, !iCloudServiceEnable {
                                //尝试开启iCloud 但是目前iCloud服务不可用 弹出一个提示
                                UIView.makeAlert(title: R.string.localizable.iCloudDisableTitle(), detail: R.string.localizable.iCloudDisableDetail(), cancelTitle: R.string.localizable.confirmTitle())
                            }
                        })
                    } else {
                        Settings.defalut.iCloudSyncEnable = value
                    }
                }
                cell.switchButton.onDisableTap {
                    topViewController()?.present(PurchaseViewController(featuresType: .iCloud), animated: true)
                }
            } else if item.type == .fullScreenWhenConnectController {
                cell.switchButton.onChange { value in
                    //airPlay设置
                    Settings.change { _ in
                        Settings.defalut.fullScreenWhenConnectController = value
                    }
                }
            } else if item.type == .autoSaveState {
                cell.switchButton.onChange { value in
                    //airPlay设置
                    Settings.change { _ in
                        Settings.defalut.autoSaveState = value
                    }
                }
            } else if item.type == .respectSilentMode {
                cell.switchButton.onChange { value in
                    //快速游戏设置
                    Settings.change { _ in
                        Settings.defalut.respectSilentMode = value
                    }
                }
            } else {
                cell.switchButton.onChange { value in }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: TitleBackgroundColorHaderCollectionReusableView.self, for: indexPath)
            header.titleLabel.font = Constants.Font.body(size: .l, weight: .semibold)
            header.titleLabel.text = SectionIndex(rawValue: indexPath.section)?.title
            if UIDevice.isPad {
                header.makeBlur(blurColor: Constants.Color.Background)
            }
            return header
        } else {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: SettingsListFooterCollectionReusableView.self, for: indexPath)
            return footer
        }
    }
}

extension SettingsListView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
#if !SIDE_LOAD
            topViewController()?.present(PurchaseViewController(), animated: true)
#endif
        } else {
            let item = items[SectionIndex(rawValue: indexPath.section)!]![indexPath.row]
            switch item.type {
            case .bios:
                let vc = BIOSSelectionViewController(showClose: UIDevice.isPad ? false : true)
                if UIDevice.isPad {
                    didTapDetail?(vc)
                } else {
                    topViewController()?.present(vc, animated: true)
                }
                
            case .theme:
                let vc = ThemeViewController()
                if UIDevice.isPad {
                    didTapDetail?(vc)
                } else {
                    topViewController()?.present(vc, animated: true)
                }
                
            case .FAQ:
                let vc = WebViewController(url: Constants.URLs.FAQ, showClose: UIDevice.isPhone)
                if UIDevice.isPad {
                    didTapDetail?(vc)
                } else {
                    topViewController()?.present(vc, animated: true)
                }
            case .feedback:
                if MFMailComposeViewController.canSendMail() {
                    let mailController = MFMailComposeViewController()
                    mailController.setToRecipients([Constants.Strings.SupportEmail])
                    mailController.mailComposeDelegate = self
                    topViewController(appController: true)?.present(mailController, animated: true)
                } else {
                    UIView.makeToast(message: R.string.localizable.noEmailSetting())
                }
            case .shareApp:
                ShareManager.shareApp(senderForIpad: UIDevice.isPad ? (collectionView.cellForItem(at: indexPath) ?? collectionView) : nil)
            case .qq:
                UIApplication.shared.open(Constants.URLs.JoinQQ)
            case .telegram:
                UIApplication.shared.open(Constants.URLs.JoinTelegram)
            case .discord:
                UIView.makeAlert(detail: R.string.localizable.joinDiscordAlertMessage("Maftyマフティー"), confirmTitle: R.string.localizable.confirmTitle(), confirmAction: {
                    UIApplication.shared.open(Constants.URLs.JoinDiscord)
                })
            case .clearCache:
                UIView.makeLoading()
                CacheManager.clear { [weak self] in
                    guard let self = self else { return }
                    if let section = SectionIndex(rawValue: indexPath.section), let items = self.items[section], indexPath.row < items.count {
                        self.items[section]?[indexPath.row].arrowDetail = nil
                        self.collectionView.reloadData()
                    }
                    UIView.hideLoading()
                }
            case .language:
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            case .userAgreement:
                let vc = WebViewController(url: Constants.URLs.TermsOfUse, showClose: UIDevice.isPhone)
                if UIDevice.isPad {
                    didTapDetail?(vc)
                } else {
                    topViewController()?.present(vc, animated: true)
                }
                
            case .privacyPolicy:
                let vc = WebViewController(url: Constants.URLs.PrivacyPolicy, showClose: UIDevice.isPhone)
                if UIDevice.isPad {
                    didTapDetail?(vc)
                } else {
                    topViewController()?.present(vc, animated: true)
                }
            default:
                break
            }
        }
    }
}

extension SettingsListView: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        switch result {
        case .sent:
            UIView.makeToast(message: R.string.localizable.sendEmailSuccess())
            controller.dismiss(animated: true)
        case .failed:
            var errorMsg = ""
            if let error = error {
                errorMsg += "\n" + error.localizedDescription
            }
            UIView.makeToast(message: R.string.localizable.sendEmailFailed(errorMsg))
        default:
            controller.dismiss(animated: true)
        }
    
    }
}
