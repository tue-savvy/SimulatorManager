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
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSImage *appIcon;
@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, weak) Simulator *simulator;

- (instancetype)initWithPath:(NSString *)path simulator:(Simulator *)simulator;

- (NSString *)dataPath;
- (NSString *)bundlePath;

@end
