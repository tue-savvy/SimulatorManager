//
//  SimulatorApp.h
//  SimulatorManager
//
//  Created by Tue Nguyen on 9/13/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Simulator;
@interface SimulatorApp : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSImage *appIcon;
@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, weak) Simulator *simulator;
@property (strong, nonatomic) NSString *bundlePath;
@property (strong, nonatomic) NSString *sandboxPath;

- (instancetype)initWithBundleID:(NSString *)bundleID simulator:(Simulator *)simulator;

- (void) updateFromLastLaunchMapInfo: (NSDictionary *) inMapInfo;
- (void) updateFromAppStateInfo: (NSDictionary *) inStateInfo;
- (void) refinePaths;

- (BOOL) hasValidPath;
@end
