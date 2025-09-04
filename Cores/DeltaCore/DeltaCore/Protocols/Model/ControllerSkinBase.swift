//
//  ControllerSkinProtocol.swift
//  DeltaCore
//
//  Created by Riley Testut on 10/13/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//

import UIKit

public protocol ControllerSkinBase
{
    var name: String { get }
    var identifier: String { get }
    var gameType: GameType { get }
    var isDebugMode: Bool { get }
    
    func supports(_ traits: ControllerSkin.Traits) -> Bool
    
    func image(for traits: ControllerSkin.Traits, preferredSize: ControllerSkin.Size) -> UIImage?
    func thumbstick(for item: ControllerSkin.Item, traits: ControllerSkin.Traits, preferredSize: ControllerSkin.Size) -> (UIImage, CGSize)?
    
    func items(for traits: ControllerSkin.Traits) -> [ControllerSkin.Item]?
    
    func isTranslucent(for traits: ControllerSkin.Traits) -> Bool?
    
    func gameScreenFrame(for traits: ControllerSkin.Traits) -> CGRect?
    func screens(for traits: ControllerSkin.Traits) -> [ControllerSkin.Screen]?
    
    func aspectRatio(for traits: ControllerSkin.Traits) -> CGSize?
    func contentSize(for traits: ControllerSkin.Traits) -> CGSize?
    
    func menuInsets(for traits: ControllerSkin.Traits) -> UIEdgeInsets?
    
    func supportedTraits(for traits: ControllerSkin.Traits) -> ControllerSkin.Traits?
}

public extension ControllerSkinBase
{
    func supportedTraits(for traits: ControllerSkin.Traits) -> ControllerSkin.Traits?
    {
        var traits = traits
        
        while !self.supports(traits)
        {
            if traits.device == .iphone && traits.displayType == .edgeToEdge
            {
                traits.displayType = .standard
            }
            else if traits.device == .ipad
            {
                traits.device = .iphone
                traits.displayType = .edgeToEdge
            }
            else
            {
                return nil
            }
        }
        
        return traits
    }
    
    func gameScreenFrame(for traits: ManicEmuCore.ControllerSkin.Traits) -> CGRect?
    {
        return self.screens(for: traits)?.first?.outputFrame
    }
}

public func ==(lhs: ControllerSkinBase?, rhs: ControllerSkinBase?) -> Bool
{
    return lhs?.identifier == rhs?.identifier
}

public func !=(lhs: ControllerSkinBase?, rhs: ControllerSkinBase?) -> Bool
{
    return !(lhs == rhs)
}

public func ~=(pattern: ControllerSkinBase?, value: ControllerSkinBase?) -> Bool
{
    return pattern == value
}
