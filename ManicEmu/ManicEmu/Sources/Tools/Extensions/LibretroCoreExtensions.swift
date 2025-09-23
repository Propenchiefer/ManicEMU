//
//  LibretroCoreExtensions.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

extension LibretroCore {
    enum Cores {
        case Nestopia, Snes9x, PicoDrive, Yabause, BeetleSaturn, Mupen64PlushNext, BeetleVB, PokeMini, BeetlePSXHW, bsnes, Gambatte, VBAM, mGBA, Flycast, Gearsystem, ClownMDEmu, bsnesJG
        
        var name: String {
            switch self {
            case .Nestopia:
                "Nestopia"
            case .Snes9x:
                "Snes9x"
            case .PicoDrive:
                "PicoDrive"
            case .Yabause:
                "Yabause"
            case .BeetleSaturn:
                "Beetle Saturn"
            case .Mupen64PlushNext:
                "Mupen64Plus-Next"
            case .BeetleVB:
                "Beetle VB"
            case .PokeMini:
                "PokeMini"
            case .BeetlePSXHW:
                "Beetle PSX HW"
            case .bsnes:
                "bsnes"
            case .Gambatte:
                "Gambatte"
            case .VBAM:
                "VBA-M"
            case .mGBA:
                "mGBA"
            case .Flycast:
                "Flycast"
            case .ClownMDEmu:
                "ClownMDEmu"
            case .Gearsystem:
                "Gearsystem"
            case .bsnesJG:
                "bsnes-jg"
            }
        }
    }
}
