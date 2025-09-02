//
//  RetroAchievementsProfileCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import Kingfisher

class RetroAchievementsProfileCell: UICollectionViewCell {
    class AchievementsUnlockedView: UIView {
        private let backgroundImageView: UIImageView = {
            let view = UIImageView(image: R.image.retro_unlock_bg())
            view.contentMode = .scaleToFill
            return view
        }()
        
        private let trophyImageView: UIImageView = {
            let view = UIImageView(image: R.image.retro_unlock_tryphy())
            return view
        }()
        
        let countLabel: UILabel = {
            let view = UILabel()
            view.font = Constants.Font.title(size: .l, weight: .semibold)
            view.textColor = Constants.Color.Yellow
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            layerCornerRadius = Constants.Size.CornerRadiusMax
            
            addSubview(backgroundImageView)
            backgroundImageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            addSubview(trophyImageView)
            trophyImageView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
            }
            
            addSubview(countLabel)
            countLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(71)
            }
            
            let bottomLabel = UILabel()
            bottomLabel.attributedText = NSAttributedString(string: R.string.localizable.achievementsUnlock(), attributes: [.font: Constants.Font.body(size: .s), .foregroundColor: UIColor.white])
            addSubview(bottomLabel)
            bottomLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class AchievementsScoreView: UIView {
        
        let hardcoreScoreLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 2
            return view
        }()
        
        let softcoreScoreLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 2
            return view
        }()
        
        let rankLabel: UILabel = {
            let view = UILabel()
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = Constants.Color.BackgroundSecondary
            layerCornerRadius = Constants.Size.CornerRadiusMax
            
            let hardcoreContainer = UIView()
            addSubview(hardcoreContainer)
            hardcoreContainer.snp.makeConstraints { make in
                make.height.equalTo(Constants.Size.ItemHeightMax)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.top.equalToSuperview()
            }
            let hardcoreIcon = UIImageView(image: .symbolImage(.flameFill).applySymbolConfig(size: 19, color: UIColor.white))
            hardcoreIcon.contentMode = .center
            hardcoreContainer.addSubview(hardcoreIcon)
            hardcoreIcon.snp.makeConstraints { make in
                make.size.equalTo(24)
                make.leading.centerY.equalToSuperview()
            }
            hardcoreContainer.addSubview(hardcoreScoreLabel)
            hardcoreScoreLabel.snp.makeConstraints { make in
                make.centerY.equalTo(hardcoreIcon)
                make.leading.equalTo(hardcoreIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
                make.trailing.equalToSuperview()
            }
            
            let softcoreContainer = UIView()
            addSubview(softcoreContainer)
            softcoreContainer.snp.makeConstraints { make in
                make.height.equalTo(Constants.Size.ItemHeightMax)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.top.equalTo(hardcoreContainer.snp.bottom)
            }
            let softcoreIcon = UIImageView(image: .symbolImage(.leafFill).applySymbolConfig(size: 19, color: UIColor.white))
            softcoreIcon.contentMode = .center
            softcoreContainer.addSubview(softcoreIcon)
            softcoreIcon.snp.makeConstraints { make in
                make.size.equalTo(24)
                make.leading.centerY.equalToSuperview()
            }
            softcoreContainer.addSubview(softcoreScoreLabel)
            softcoreScoreLabel.snp.makeConstraints { make in
                make.centerY.equalTo(softcoreIcon)
                make.leading.equalTo(softcoreIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
                make.trailing.equalToSuperview()
            }
            
            let rankContainer = UIView()
            addSubview(rankContainer)
            rankContainer.snp.makeConstraints { make in
                make.height.equalTo(Constants.Size.ItemHeightMax)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.top.equalTo(softcoreContainer.snp.bottom)
            }
            let rankIcon = UIImageView(image: .symbolImage(.crownFill).applySymbolConfig(size: 18, color: UIColor.white))
            rankContainer.addSubview(rankIcon)
            rankIcon.snp.makeConstraints { make in
                make.size.equalTo(24)
                make.leading.centerY.equalToSuperview()
            }
            rankContainer.addSubview(rankLabel)
            rankLabel.snp.makeConstraints { make in
                make.centerY.equalTo(rankIcon)
                make.leading.equalTo(rankIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
                make.trailing.equalToSuperview()
            }
            updateDatas(hardcoreScore: 0, softcoreScore: 0, rank: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func updateDatas(hardcoreScore: Int, softcoreScore: Int, rank: Int?) {
            let matt1 = NSMutableAttributedString(string: R.string.localizable.hardcoreTitle(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: UIColor.white])
            matt1.append(NSAttributedString(string: "\(hardcoreScore)", attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.Yellow]))
            matt1.append(NSAttributedString(string: "\n" + R.string.localizable.hardcoreDesc(), attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            hardcoreScoreLabel.attributedText = matt1.applying(attributes: [.paragraphStyle: style])
            
            
            let matt2 = NSMutableAttributedString(string: R.string.localizable.softcoreTitle(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: UIColor.white])
            matt2.append(NSAttributedString(string: "\(softcoreScore)", attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.Yellow]))
            matt2.append(NSAttributedString(string: "\n" + R.string.localizable.softcoreDesc(), attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            softcoreScoreLabel.attributedText = matt2.applying(attributes: [.paragraphStyle: style])
            
            
            let matt3 = NSMutableAttributedString(string: R.string.localizable.rankTitle(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: UIColor.white])
            if let rank {
                matt3.append(NSAttributedString(string: "\(rank)", attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.Yellow]))
            } else {
                matt3.append(NSAttributedString(string: R.string.localizable.rankRequire(), attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            }
            rankLabel.attributedText = matt3
        }
    }
    
    private let avatarImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layerCornerRadius = Constants.Size.CornerRadiusMid
        return view
    }()
    
    private let usernameLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.title(size: .l, weight: .semibold)
        view.textColor = .white
        return view
    }()
    
    private let lastActivityIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.image = .symbolImage(.starCircleFill).applySymbolConfig(color: Constants.Color.LabelSecondary)
        return view
    }()
    
    private let lastActivityLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.body()
        return view
    }()
    
    private let memberSinceIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.image = .symbolImage(.sparkles).applySymbolConfig(color: Constants.Color.LabelSecondary)
        return view
    }()
    
    private let memberSinceLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.body()
        return view
    }()
    
    private lazy var logoutButton: SymbolButton = {
        let view = SymbolButton(image: nil, title: R.string.localizable.achievementsLogoutTitle(), titleFont: Constants.Font.caption(size: .l), titleColor: Constants.Color.Red, titleAlignment: .right, edgeInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 14), horizontalContian: true, titlePosition: .right)
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.logoutSuccess?()
        }
        return view
    }()
    
    private let unlockedView: AchievementsUnlockedView = {
        let view = AchievementsUnlockedView()
        return view
    }()
    
    private let scoreView: AchievementsScoreView = {
        let view = AchievementsScoreView()
        return view
    }()
    
    private lazy var bottomButton: UIButton = {
        let view = UIButton(type: .custom)
        view.setAttributedTitle(NSAttributedString(string: "RetroAchievements", attributes: [.font: Constants.Font.body(size: .s), .foregroundColor: Constants.Color.Indigo]).underlined, for: .normal)
        view.onTap { [weak self] in
            guard let self else { return }
            if let username = self.username {
                UIApplication.shared.open(Constants.URLs.RetroProfile(username: username))
            } else {
                UIApplication.shared.open(Constants.URLs.Retro)
            }
        }
        return view
    }()
    
    private var username: String? = nil
    
    var logoutSuccess: (()->Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(80)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
            make.top.equalToSuperview()
        }
        
        addSubview(usernameLabel)
        usernameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView)
            make.top.equalTo(avatarImageView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        addSubview(logoutButton)
        logoutButton.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceHuge)
            make.centerY.equalTo(usernameLabel)
        }
        
        addSubview(lastActivityIcon)
        lastActivityIcon.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalTo(avatarImageView)
            make.top.equalTo(usernameLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(lastActivityLabel)
        lastActivityLabel.snp.makeConstraints { make in
            make.centerY.equalTo(lastActivityIcon)
            make.leading.equalTo(lastActivityIcon.snp.trailing).offset(6)
        }
        
        addSubview(memberSinceIcon)
        memberSinceIcon.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalTo(avatarImageView)
            make.top.equalTo(lastActivityIcon.snp.bottom).offset(Constants.Size.ContentSpaceTiny)
        }
        
        addSubview(memberSinceLabel)
        memberSinceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(memberSinceIcon)
            make.leading.equalTo(memberSinceIcon.snp.trailing).offset(6)
        }
        
        addSubview(unlockedView)
        unlockedView.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView)
            make.trailing.equalTo(logoutButton)
            make.height.equalTo(130)
            make.top.equalTo(memberSinceIcon.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        addSubview(scoreView)
        scoreView.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView)
            make.trailing.equalTo(logoutButton)
            make.height.equalTo(180)
            make.top.equalTo(unlockedView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        
        let bottomLabelContainer = UIView()
        addSubview(bottomLabelContainer)
        bottomLabelContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(scoreView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        let bottomLabel = UILabel()
        bottomLabel.attributedText = NSAttributedString(string: R.string.localizable.achievementsMoreDetail(), attributes: [.font : Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.Indigo])
        bottomLabelContainer.addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        bottomLabelContainer.addSubview(bottomButton)
        bottomButton.snp.makeConstraints { make in
            make.leading.equalTo(bottomLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.top.bottom.trailing.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDatas(profile: AchievementsProfile) {
        avatarImageView.kf.setImage(with: URL(string: profile.userPic), placeholder: UIImage.placeHolder(preferenceSize: .init(80)))
        usernameLabel.text = profile.user
        lastActivityLabel.text = R.string.localizable.lastActivity(profile.lastActivityTimestamp)
        memberSinceLabel.text = R.string.localizable.memberSince(profile.memberSince)
        unlockedView.countLabel.text = "\(profile.achievementCount)"
        scoreView.updateDatas(hardcoreScore: profile.totalHardcorePoints, softcoreScore: profile.totalSoftcorePoints, rank: profile.totalRanked > 0 ? profile.totalRanked : nil)
    }
}
