//
//  BIOSCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/6/10.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ManicEmuCore
import UniformTypeIdentifiers

class BIOSCollectionViewCell: UICollectionViewCell {
    
    class ItemView: UIView {
        var titleLabel: UILabel = {
            let view = UILabel()
            view.font = Constants.Font.body(size: .l)
            view.textColor = Constants.Color.LabelPrimary
            return view
        }()
        
        var detailLabel: UILabel = {
            let view = UILabel()
            view.font = Constants.Font.caption(size: .l)
            view.textColor = Constants.Color.LabelSecondary
            view.numberOfLines = 0
            return view
        }()
        
        var optionButton: UIButton = {
            let view = UIButton(type: .custom)
            view.titleLabel?.font = Constants.Font.caption(size: .l)
            view.setTitle("(\(R.string.localizable.optionTitleOptional()))", for: .normal)
            view.setTitle("(\(R.string.localizable.optionTitleRequired()))", for: .selected)
            view.setTitleColor(Constants.Color.LabelSecondary, for: .normal)
            view.setTitleColor(Constants.Color.Red, for: .selected)
            return view
        }()
        
        var button: UIButton = {
            let view = UIButton(type: .custom)
            view.titleLabel?.font = Constants.Font.body(size: .l, weight: .semibold)
            view.setTitle(R.string.localizable.tabbarTitleImport(), for: .normal)
            view.setTitle(R.string.localizable.biosImported(), for: .selected)
            view.setTitleColor(Constants.Color.Red, for: .normal)
            view.setTitleColor(Constants.Color.Green, for: .selected)
            return view
        }()
        
        init(enableButton: Bool = true, enableOptionButton: Bool = true) {
            super.init(frame: .zero)
            layerCornerRadius = Constants.Size.CornerRadiusMid
            backgroundColor = Constants.Color.BackgroundPrimary
            
            let titleContainer = UIView()
            addSubview(titleContainer)
            titleContainer.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                if !enableButton {
                    make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
                }
            }
            
            titleContainer.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.top.equalToSuperview()
                if !enableOptionButton {
                    make.trailing.equalToSuperview()
                }
            }
            
            if enableOptionButton {
                titleContainer.addSubview(optionButton)
                optionButton.snp.makeConstraints { make in
                    make.trailing.lessThanOrEqualToSuperview()
                    make.centerY.equalTo(titleLabel)
                    make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
                }
            }
            
            titleContainer.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
                make.leading.bottom.equalToSuperview()
                make.trailing.lessThanOrEqualToSuperview()
            }
            
            if enableButton {
                addSubview(button)
                titleContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
                titleContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                button.setContentHuggingPriority(.required, for: .horizontal)
                button.setContentCompressionResistancePriority(.required, for: .horizontal)
                button.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
                    make.leading.equalTo(titleContainer.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                }
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    private func getBiosItems(gameType: GameType, completion: (([BIOSItem])->Void)? = nil) {
        DispatchQueue.global().async {
            var biosItems = [BIOSItem]()
            if gameType == .mcd {
                biosItems = Constants.BIOS.MegaCDBios
            } else if gameType == .ss {
                biosItems = Constants.BIOS.SaturnBios
            } else if gameType == .ds {
                biosItems = Constants.BIOS.DSBios
            } else if gameType == .ps1 {
                biosItems = Constants.BIOS.PS1Bios
            } else if gameType == .dc {
                biosItems = Constants.BIOS.DCBios
            }
            let fileManager = FileManager.default
            for (index, bios) in biosItems.enumerated() {
                var biosInLib = Constants.Path.System.appendingPathComponent(bios.fileName)
                if gameType == .dc {
                   // biosInLib = Constants.Path.Flycast.appendingPathComponent("dc/\(bios.fileName)")
                }
                let isBiosExists = fileManager.fileExists(atPath: biosInLib)
                if isBiosExists {
                    biosItems[index].imported = true
                } else {
                    let biosInDoc = Constants.Path.BIOS.appendingPathComponent(bios.fileName)
                    if fileManager.fileExists(atPath: biosInDoc) {
                        try? FileManager.safeCopyItem(at: URL(fileURLWithPath: biosInDoc), to: URL(fileURLWithPath: biosInLib))
                        biosItems[index].imported = true
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion?(biosItems)
            }
        }
    }
    
    private let itemViews: [ItemView] = {
        var views = [ItemView]()
        (0...7).forEach { _ in
            let v = ItemView()
            v.isHidden = true
            views.append(v)
        }
        return views
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layerCornerRadius = Constants.Size.CornerRadiusMax
        backgroundColor = Constants.Color.BackgroundSecondary
        
        addSubviews(itemViews)
        for (index, view) in itemViews.enumerated() {
            view.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.height.equalTo(Constants.Size.ItemHeightMax)
                if index == 0 {
                    make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                } else {
                    make.top.equalTo(itemViews[index-1].snp.bottom).offset(Constants.Size.ContentSpaceMid)
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(gameType: GameType, importSuccess: (()->Void)? = nil) {
        getBiosItems(gameType: gameType) { [weak self] biosItems in
            guard let self else { return }
            for (index, itemView) in self.itemViews.enumerated() {
                if index < biosItems.count {
                    let b = biosItems[index]
                    itemView.titleLabel.text = b.fileName
                    itemView.detailLabel.text = b.desc
                    itemView.optionButton.isSelected = b.required
                    itemView.button.isSelected = b.imported
                    itemView.isHidden = false
                    itemView.button.onTap {
                        FilesImporter.shared.presentImportController(supportedTypes: UTType.binTypes, allowsMultipleSelection: true) {  urls in
                            UIView.makeLoading()
                            DispatchQueue.global().async {
                                var matchs = [(url: URL, fileName: String)]()
                                for url in urls {
                                    biosItems.forEach({ bios in
                                        if url.lastPathComponent.lowercased() == bios.fileName.lowercased() {
                                            matchs.append((url, bios.fileName))
                                        }
                                    })
                                }
                                if matchs.count > 0 {
                                    for match in matchs {
                                        try? FileManager.safeCopyItem(at: match.url, to: URL(fileURLWithPath: Constants.Path.BIOS.appendingPathComponent(match.fileName)), shouldReplace: true)
                                        var matchFilePath = Constants.Path.System.appendingPathComponent(match.fileName)
                                        if gameType == .dc {
                              //              matchFilePath = Constants.Path.Flycast.appendingPathComponent("dc/\(match.fileName)")
                                        }
                                        try? FileManager.safeCopyItem(at: match.url, to: URL(fileURLWithPath: matchFilePath), shouldReplace: true)
                                    }
                                }
                                DispatchQueue.main.async {
                                    UIView.hideLoading()
                                    if matchs.count > 0 {
                                        UIView.makeToast(message: R.string.localizable.biosImportSuccess(matchs.reduce("") { $0 + $1.fileName + "\n" }))
                                        importSuccess?()
                                    } else {
                                        UIView.makeToast(message: R.string.localizable.biosImportFailed())
                                    }
                                }
                            }
                        }
                    }
                } else {
                    itemView.isHidden = true
                }
            }
        }
    }
    
    static func CellHeight(gameType: GameType) -> Double {
        var itemCount = 0
        if gameType == .mcd {
            itemCount = Constants.BIOS.MegaCDBios.count
        } else if gameType == .ss {
            itemCount = Constants.BIOS.SaturnBios.count
        } else if gameType == .ds {
            itemCount = Constants.BIOS.DSBios.count
        } else if gameType == .ps1 {
            itemCount = Constants.BIOS.PS1Bios.count
        } else if gameType == .dc {
            itemCount = Constants.BIOS.DCBios.count
        }
        return (Double(itemCount) * Constants.Size.ItemHeightMax) + (Double(itemCount + 1) * Constants.Size.ContentSpaceMid)
    }
}
