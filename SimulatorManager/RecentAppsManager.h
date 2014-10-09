//
//  RecentAppsManager.h
//  SimulatorManager
//
//  Created by Tue Nguyen on 10/9/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Simulator;
@class SimulatorApp;
@interface RecentAppsManager : NSObject
- (void)addRecentApp:(SimulatorApp *)app;
- (NSArray *)recentApps;
@end
