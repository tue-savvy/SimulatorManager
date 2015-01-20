//
//  RecentAppsManager.h
//  SimulatorManager
//
//  Created by Tue Nguyen on 10/9/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const RecentAppUpdateNotification;

@class Simulator;
@class SimulatorApp;
@interface RecentAppsManager : NSObject
@property (strong, nonatomic) NSArray *simulators;
- (instancetype)initWithSimulators:(NSArray *)simulators;
- (void)addRecentApp:(SimulatorApp *)app;
- (NSArray *)recentApps;
@end
