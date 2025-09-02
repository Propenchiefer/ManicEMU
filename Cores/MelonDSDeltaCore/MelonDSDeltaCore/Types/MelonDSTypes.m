//
//  MelonDSTypes.m
//  MelonDSDeltaCore
//
//  Created by Riley Testut on 4/2/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

#import "MelonDSTypes.h"

GameType const GameTypeDS = @"public.aoshuang.game.ds";

CheatType const CheatTypeActionReplay = @"ActionReplay";

NSNotificationName const MelonDSDidConnectToWFCNotification = @"MelonDSDidConnectToWFCNotification";
NSNotificationName const MelonDSDidDisconnectFromWFCNotification = @"MelonDSDidDisconnectFromWFCNotification";

NSString *MelonDSWFCIDUserDefaultsKey = @"MelonDSDeltaCore.WFC.ID";
NSString *MelonDSWFCFlagsUserDefaultsKey = @"MelonDSDeltaCore.WFC.Flags";
