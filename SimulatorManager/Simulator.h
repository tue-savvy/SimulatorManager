//
//  Simulator.h
//  SimulatorManager
//
//  Created by Tue Nguyen on 9/13/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimulatorApp.h"

@interface Simulator : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *UDID;
@property (nonatomic, strong) NSString *deviceType;
@property (nonatomic, strong) NSString *runtime;
@property (nonatomic, strong) NSNumber *state;

@property (nonatomic, strong) NSString *path;

- (instancetype)initWithPath:(NSString *)path;

- (NSArray *)applications;

- (NSString *)appDataPath:(SimulatorApp *)app;
@end
