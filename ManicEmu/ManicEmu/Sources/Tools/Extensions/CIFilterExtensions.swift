//
//  CIFilterExtensions.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/8.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import CoreImage

extension CIFilter {
    func preview(image: UIImage?) -> UIImage? {
        image?.applyFilter(filter: self)
    }
}
