//
//  CheevosPopupView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/9/10.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ProHUD
import Kingfisher

class CheevosPopupAchievementCell: UICollectionViewCell {
    private let containerView: RoundAndBorderView = {
        let view = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid, borderColor: Constants.Color.Border, borderWidth: 1)
        view.backgroundColor = Constants.Color.BackgroundPrimary
        return view
    }()
    
    private let infoContainerView = UIView()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layerCornerRadius = 4
        return view
    }()
    
    private let titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 2
        return view
    }()
    
    private let progressView = RetroAchievementsListCell.AchievementsProgressView()
    
    private let progressLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.caption(size: .m)
        view.textColor = Constants.Color.Yellow
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
        }
        
        containerView.addSubview(infoContainerView)
        infoContainerView.snp.makeConstraints { make in
            make.centerY.equalTo(imageView)
            make.leading.equalTo(imageView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
        }
        
        infoContainerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-18)
        }
        
        infoContainerView.addSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        infoContainerView.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalTo(progressLabel)
            make.trailing.equalTo(progressLabel.snp.leading).offset(-Constants.Size.ContentSpaceMin)
            make.height.equalTo(2)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(achievement: CheevosAchievement) {
        imageView.kf.setImage(with: URL(string: achievement.unlockedBadgeUrl), placeholder: UIImage.placeHolder(preferenceSize: .init(40)))
        
        let matt = NSMutableAttributedString(string: achievement.title ?? "", attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelPrimary])
        matt.append(NSAttributedString(string: "\n\(achievement._description ?? "")", attributes: [.font: Constants.Font.body(size: .s), .foregroundColor: Constants.Color.LabelSecondary]))
        let style = NSMutableParagraphStyle()
        style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
        style.alignment = .left
        titleLabel.attributedText = matt.applying(attributes: [.paragraphStyle: style])
        
        if let measuredProgress = achievement.measuredProgress, !measuredProgress.isEmpty {
            progressView.progress = achievement.measuredPercent
            progressLabel.text = measuredProgress
            progressView.isHidden = false
            progressLabel.isHidden = false
            titleLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(-18)
            }
        } else {
            progressView.isHidden = true
            progressLabel.isHidden = true
            titleLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(0)
            }
        }
    }
}

class CheevosPopupLeaderboardCell: UICollectionViewCell {
    private let containerView: RoundAndBorderView = {
        let view = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid, borderColor: Constants.Color.Border, borderWidth: 1)
        view.backgroundColor = Constants.Color.BackgroundPrimary
        return view
    }()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layerCornerRadius = 4
        return view
    }()
    
    private let titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 2
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
        }
        
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(imageView.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(leaderboard: CheevosLeaderboard) {
        if let badgeUrl = leaderboard.badgeUrl {
            imageView.kf.setImage(with: URL(string: badgeUrl), placeholder: UIImage.placeHolder(preferenceSize: .init(40)))
        } else {
            imageView.image = leaderboard.image
        }
        
        let matt = NSMutableAttributedString(string: leaderboard.title ?? "", attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: UIColor.white])
        matt.append(NSAttributedString(string: "\n\(leaderboard._description ?? "")", attributes: [.font: Constants.Font.body(size: .s), .foregroundColor: Constants.Color.LabelSecondary]))
        let style = NSMutableParagraphStyle()
        style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
        style.alignment = .left
        titleLabel.attributedText = matt.applying(attributes: [.paragraphStyle: style])
    }
}

enum CheevosPopupViewType {
    case leaderboard, progress, challenge
}

class CheevosPopupView: UIView {
    /// 充当导航条
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
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
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: CheevosPopupLeaderboardCell.self)
        view.register(cellWithClass: CheevosPopupAchievementCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.allowsSelection = true
        view.allowsMultipleSelection = false
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMid + Constants.Size.ContentSpaceMax, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()

    private var leaderBoards: [CheevosLeaderboard] = []
    
    private var achievements: [CheevosAchievement] = []
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    let type: CheevosPopupViewType
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(type: CheevosPopupViewType, leaderBoards: [CheevosLeaderboard]? = nil, achievements: [CheevosAchievement]? = nil) {
        self.type = type
        
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        switch type {
        case .leaderboard:
            guard let leaderBoards, leaderBoards.count > 0 else { return }
        case .progress, .challenge:
            guard let achievements, achievements.count > 0 else { return }
        }
        
        if type == .leaderboard {
            self.leaderBoards = leaderBoards ?? []
        } else {
            self.achievements = achievements ?? []
        }

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        let headerLabel = UILabel()
        headerLabel.font = Constants.Font.title(size: .s, weight: .bold)
        headerLabel.textColor = Constants.Color.LabelPrimary
        switch type {
        case .leaderboard:
            headerLabel.text = R.string.localizable.leaderboard()
        case .progress:
            headerLabel.text = R.string.localizable.progress()
        case .challenge:
            headerLabel.text = R.string.localizable.challenge()
        }
        
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self else { return nil }
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(self.type == .leaderboard ? 64 : Constants.Size.ItemHeightHuge)), subitem: item, count: Int(1))
            
            
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceMid, bottom: 0, trailing: Constants.Size.ContentSpaceMid)
            group.interItemSpacing = NSCollectionLayoutSpacing.fixed(Constants.Size.ContentSpaceMid)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMid

            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMid, leading: Constants.Size.ContentSpaceMid, bottom: Constants.Size.ContentSpaceMid, trailing: Constants.Size.ContentSpaceMid)
            
            return section
        }
        return layout
    }
}

extension CheevosPopupView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        type == .leaderboard ? leaderBoards.count : achievements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if type == .leaderboard {
            let cell = collectionView.dequeueReusableCell(withClass: CheevosPopupLeaderboardCell.self, for: indexPath)
            cell.setData(leaderboard: leaderBoards[indexPath.row])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: CheevosPopupAchievementCell.self, for: indexPath)
            cell.setData(achievement: achievements[indexPath.row])
            return cell
        }
    }
}

extension CheevosPopupView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard type == .challenge || type == .progress else { return }
        topViewController()?.present(RetroAchievementsDetailViewController(achievement: achievements[indexPath.row]), animated: true)
    }
}

extension CheevosPopupView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: CheevosPopupView.self)).count > 0 ? true : false
    }
    
    static func show(type: CheevosPopupViewType,
                     leaderboards: [CheevosLeaderboard]? = nil,
                     achievements: [CheevosAchievement]? = nil,
                     gameViewRect: CGRect,
                     menuInsets: UIEdgeInsets?,
                     hideCompletion: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: CheevosPopupView.self)) { sheet in
            sheet.configGamePlayingStyle(isForGameMenu: true, gameViewRect: gameViewRect, menuInsets: menuInsets, hideCompletion: hideCompletion)
            
            let view = UIView()
            
            let grabber = UIImageView(image: R.image.grabber_icon())
            grabber.isUserInteractionEnabled = true
            grabber.contentMode = .center
            view.addSubview(grabber)
            let grabberHeight = Constants.Size.ContentSpaceTiny*3
            grabber.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.height.equalTo(grabberHeight)
            }
            
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape || menuInsets != nil) ? .allCorners : [.topLeft, .topRight])
            containerView.makeBlur()
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.top.equalTo(grabber.snp.bottom)
                make.leading.bottom.trailing.equalToSuperview()
                if let maxHeight = sheet.config.cardMaxHeight {
                    make.height.equalTo(maxHeight - grabberHeight)
                }
            }
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        // 达到移除的速度
                        sheet.pop()
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            
            let listView = CheevosPopupView(type: type, leaderBoards: leaderboards, achievements: achievements)
            listView.didTapClose = { [weak sheet] in
                sheet?.pop()
                hideCompletion?()
            }
            containerView.addSubview(listView)
            listView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
