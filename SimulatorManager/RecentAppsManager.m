//
//  RecentAppsManager.m
//  SimulatorManager
//
//  Created by Tue Nguyen on 10/9/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import "RecentAppsManager.h"
#import "Simulator.h"
#import "SimulatorApp.h"

#define RecentAppsKey @"RecentApps"
#define MAX_RECENT    5


NSString *const RecentAppUpdateNotification = @"RecentAppUpdateNotification";


@interface RecentAppsManager()
@property (nonatomic, strong) NSMutableArray *recentData;
@property (nonatomic, strong) NSMutableArray *recentSimulatorApps;

@end
@implementation RecentAppsManager
- (instancetype)initWithSimulators:(NSArray *)simulators {
    self  = [super init];
    if (self) {
        self.simulators = simulators;
    }
    return self;
}
- (void)setSimulators:(NSArray *)simulators {
    _simulators = simulators;
    self.recentData = nil;//Reset it to nil to refresh simulatos
}
- (void)_loadRecentData {
    if (self.recentData) return;
    
    NSArray *savedData = [[NSUserDefaults standardUserDefaults] objectForKey:RecentAppsKey];
    if (savedData) {
        self.recentData = [savedData mutableCopy];
    } else {
        self.recentData = [NSMutableArray array];
    }
    //TODO: update this
    self.recentSimulatorApps = [NSMutableArray array];
    for (NSDictionary *dict in self.recentData) {
        NSString *simulatorPath = dict[@"SimulatorPath"];
        NSString *appBundleID = dict[@"AppBundleID"];
        for (Simulator *simulator in self.simulators) {
            if ([simulator.path isEqualToString:simulatorPath]) {
                for (SimulatorApp *app in simulator.applications) {
                    if ([app.bundleID isEqualToString:appBundleID]) {
                        [self.recentSimulatorApps addObject:app];
                        break;
                    }
                }
                break;
            }
        }
    }
}

- (void)addRecentApp:(SimulatorApp *)app {
    [self _loadRecentData];
    NSString *simulatorPath = app.simulator.path;
    NSString *appBundleID = app.bundleID;
    
    if (!simulatorPath && !appBundleID) return;
    
    //Check for existing
    NSInteger index = 0;
    for (NSDictionary *recentDict in self.recentData) {
        if ([recentDict[@"SimulatorPath"] isEqual:simulatorPath] && [recentDict[@"AppBundleID"] isEqual:appBundleID]) {
            if (index == 0) return;
            
            //move recent to first position
            [self.recentData removeObject:recentDict];
            [self.recentData insertObject:recentDict atIndex:0];
            //move simulator app object to front
            SimulatorApp *app = [self.recentSimulatorApps objectAtIndex:index];
            [self.recentSimulatorApps removeObjectAtIndex:index];
            [self.recentSimulatorApps addObject:app];
            
            [[NSUserDefaults standardUserDefaults] setObject:self.recentData forKey:RecentAppsKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:RecentAppUpdateNotification object:self];
            return;
        }
        index++;
    }
    
    //Insert to recent list
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"SimulatorPath"] = simulatorPath;
    dict[@"AppBundleID"] = appBundleID;
    [self.recentData insertObject:dict atIndex:0];
    [self.recentSimulatorApps insertObject:app atIndex:0];
    
    if (self.recentData.count > MAX_RECENT) {
        [self.recentData removeLastObject];
        [self.recentSimulatorApps removeLastObject];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.recentData forKey:RecentAppsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RecentAppUpdateNotification object:self];
    
}

- (NSArray *)recentApps {
    [self _loadRecentData];
    
    return self.recentSimulatorApps;
}
@end
