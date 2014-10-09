//
//  Simulator.m
//  SimulatorManager
//
//  Created by Tue Nguyen on 9/13/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import "Simulator.h"
#import "SimulatorApp.h"

#define SIMULATOR_INFO_FILE_NAME  @"device.plist"

@implementation Simulator
- (instancetype)initWithPath:(NSString *)pathToSimulator {
    self = [super init];
    if (self) {
        if (![[self class] isSimulatorDirectory:pathToSimulator]) return nil;
        
        self.path = pathToSimulator;
        
        [self loadSimulatorInfo];
    }
    return self;
}
+ (BOOL)isSimulatorDirectory:(NSString *)directory {
    NSString *infoPlist = [directory stringByAppendingPathComponent:SIMULATOR_INFO_FILE_NAME];
    return [[NSFileManager defaultManager] fileExistsAtPath:infoPlist isDirectory:NULL];
}

- (void)loadSimulatorInfo {
    NSString *infoPlist = [self.path stringByAppendingPathComponent:SIMULATOR_INFO_FILE_NAME];
    NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPlist];
    
    self.name = infoDict[@"name"];
    self.UDID = infoDict[@"UDID"];
    self.deviceType = infoDict[@"deviceType"];
    self.runtime = infoDict[@"runtime"];
    self.state = infoDict[@"state"];
}

- (NSArray *)applications {
    NSString *applicationFolder = [self.path stringByAppendingPathComponent:@"data/Containers/Bundle/Application"];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:applicationFolder error:nil];
    NSMutableArray *apps = [NSMutableArray array];
    for (NSString *folderName in contents) {
        //Ignore hidden file
        if ([folderName hasPrefix:@"."]) continue;
        
        NSString *appPath = [applicationFolder stringByAppendingPathComponent:folderName];
        SimulatorApp *simulatorApp = [[SimulatorApp alloc] initWithPath:appPath simulator:self];
        [apps addObject:simulatorApp];
    }
    
    return apps;
}

- (NSString *)appDataPath:(SimulatorApp *)app {
    NSString *dataFolder = [self.path stringByAppendingPathComponent:@"data/Containers/Data/Application"];
    NSString *bundleID = app.bundleID;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *content = [fm contentsOfDirectoryAtPath:dataFolder error:nil];
    
    //We have to find in all app data folder to looking for a cache folder with app bundle id
    for (NSString *appDataName in content) {
        NSString *appDataPath = [dataFolder stringByAppendingPathComponent:appDataName];
        NSString *cache = [appDataPath stringByAppendingPathComponent:@"Library/Caches"];
        NSString *cacheWithBundleID = [cache stringByAppendingPathComponent:bundleID];
        if ([fm fileExistsAtPath:cacheWithBundleID isDirectory:NULL]) {
            return appDataPath;
        }
    }
    return nil;
}
- (NSString *)runtimeVersion {
    NSString *version = [self.runtime stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimRuntime." withString:@""];
    version = [version stringByReplacingOccurrencesOfString:@"iOS-" withString:@"iOS "];
    version = [version stringByReplacingOccurrencesOfString:@"-" withString:@"."];
    return version;
}
@end
