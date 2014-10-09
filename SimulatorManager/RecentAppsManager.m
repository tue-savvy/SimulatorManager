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
- (void)_loadRecentData {
    if (self.recentData) return;
    
    NSArray *savedData = [[NSUserDefaults standardUserDefaults] objectForKey:RecentAppsKey];
    if (savedData) {
        self.recentData = [savedData mutableCopy];
    } else {
        self.recentData = [NSMutableArray array];
    }
    
    self.recentSimulatorApps = [NSMutableArray array];
    for (NSDictionary *dict in self.recentData) {
        NSString *simulatorPath = dict[@"SimulatorPath"];
        NSString *appPath = dict[@"AppPath"];
        Simulator *simulator = [[Simulator alloc] initWithPath:simulatorPath];
        SimulatorApp *app = [[SimulatorApp alloc] initWithPath:appPath simulator:simulator];
        [self.recentSimulatorApps addObject:app];
    }
}

- (void)addRecentApp:(SimulatorApp *)app {
    [self _loadRecentData];
    NSString *simulatorPath = app.simulator.path;
    NSString *appPath = app.path;
    
    //Check for existing
    NSInteger index = 0;
    for (NSDictionary *recentDict in self.recentData) {
        if ([recentDict[@"SimulatorPath"] isEqual:simulatorPath] && [recentDict[@"AppPath"] isEqual:appPath]) {
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
    dict[@"AppPath"] = appPath;
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
