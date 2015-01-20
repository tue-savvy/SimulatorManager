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
@interface Simulator()
@property (strong, nonatomic) NSMutableArray *appList;
@property (assign, nonatomic) BOOL needRefreshAppList;
@end
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
- (void)setNeedRefreshAppList {
    self.needRefreshAppList = YES;
}
//Lazy load AppList
- (NSArray *)applications {
    if (self.appList && !self.needRefreshAppList) return self.appList;
    
    self.needRefreshAppList = NO;
    self.appList = [NSMutableArray array];
    [self gatherAppInfoFromLastLaunchMap];
    [self gatherAppInfoFromAppState];
    [self gatherAppInfoFromInstallLogs];
    [self cleanupAndRefineAppList];
    return self.appList;
}

- (NSString *)appDataPath {
    NSString *dataFolder = [self.path stringByAppendingPathComponent:@"data/Containers/Data/Application"];
    return dataFolder;
}
- (NSString *)runtimeVersion {
    NSString *version = [self.runtime stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimRuntime." withString:@""];
    version = [version stringByReplacingOccurrencesOfString:@"iOS-" withString:@"iOS "];
    version = [version stringByReplacingOccurrencesOfString:@"-" withString:@"."];
    return version;
}


// LastLaunchServicesMap.plist seems to be the most reliable location to gather app info. Got it from https://github.com/somegeekintn/SimDirs
- (void) gatherAppInfoFromLastLaunchMap
{
    NSFileManager	*fileManager = [NSFileManager defaultManager];
    NSString			*launchMapInfoPath = [self.path stringByAppendingPathComponent: @"data/Library/MobileInstallation/LastLaunchServicesMap.plist"];
    
    if (launchMapInfoPath != nil && [fileManager fileExistsAtPath:launchMapInfoPath]) {
        NSDictionary	*launchInfo;
        NSDictionary	*userInfo;
        
        launchInfo = [NSDictionary dictionaryWithContentsOfFile:launchMapInfoPath];
        userInfo = launchInfo[@"User"];
        
        for (NSString *bundleID in userInfo) {
            SimulatorApp			*appInfo = [self appInfoWithBundleID: bundleID];
            
            if (appInfo != nil) {
                [appInfo updateFromLastLaunchMapInfo: userInfo[bundleID]];
            }
        }
    }
}

// applicationState.plist sometimes has info that LastLaunchServicesMap.plist doesn't. Got it from https://github.com/somegeekintn/SimDirs
- (void) gatherAppInfoFromAppState
{
    NSFileManager	*fileManager = [NSFileManager defaultManager];
    NSString			*appStateInfoPath = [self.path stringByAppendingPathComponent: @"data/Library/BackBoard/applicationState.plist"];
    
    if (appStateInfoPath != nil && [fileManager fileExistsAtPath:appStateInfoPath]) {
        NSDictionary	*stateInfo;
        
        stateInfo = [NSDictionary dictionaryWithContentsOfFile:appStateInfoPath];
        
        for (NSString *bundleID in stateInfo) {
            if ([bundleID rangeOfString: @"com.apple"].location == NSNotFound) {
                SimulatorApp *appInfo = [self appInfoWithBundleID: bundleID];
                
                if (appInfo != nil) {
                    [appInfo updateFromAppStateInfo: stateInfo[bundleID]];
                }
            }
        }
    }
}

// mobile_installation.log.0 is my least favorite, most fragile way to scan for app installations. Got it from https://github.com/somegeekintn/SimDirs
// try this after everything else
- (void) gatherAppInfoFromInstallLogs
{
    NSFileManager	*fileManager = [NSFileManager defaultManager];
    NSString			*installLogURL = [self.path stringByAppendingPathComponent: @"data/Library/Logs/MobileInstallation/mobile_installation.log.0"];
    
    if (installLogURL != nil && [fileManager fileExistsAtPath:installLogURL]) {
        NSString		*installLog = [[NSString alloc] initWithContentsOfFile:installLogURL usedEncoding: nil error: nil];
        
        if (installLog != nil) {
            // check these from most recent to oldest
            for (NSString *line in [[installLog componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] reverseObjectEnumerator]) {
                if ([line rangeOfString: @"com.apple"].location == NSNotFound) {
                    NSRange		logHintRange;
                    
                    logHintRange = [line rangeOfString: @"makeContainerLiveReplacingContainer"];
                    if (logHintRange.location != NSNotFound) {
                        [self extractBundleLocationFromLogEntry: line];
                    }
                    
                    logHintRange = [line rangeOfString: @"_refreshUUIDForContainer"];
                    if (logHintRange.location != NSNotFound) {
                        [self extractSandboxLocationFromLogEntry: line];
                    }
                }
            }
        }
    }
}

- (void) extractBundleLocationFromLogEntry: (NSString *) inLine
{
    NSArray		*logComponents = [inLine componentsSeparatedByString: @" "];
    NSString	*bundlePath = [logComponents lastObject];
    
    if (bundlePath != nil) {
        NSInteger	bundleIDIndex = [logComponents count] - 3;
        
        if (bundleIDIndex >= 0) {
            NSString		*bundleID = [logComponents objectAtIndex: bundleIDIndex];
            SimulatorApp	*appInfo = [self appInfoWithBundleID: bundleID];
            
            if (appInfo != nil && !appInfo.bundlePath) {
                appInfo.bundlePath = bundlePath;
            }
        }
    }
}

- (void) extractSandboxLocationFromLogEntry: (NSString *) inLine
{
    NSArray		*logComponents = [inLine componentsSeparatedByString: @" "];
    NSString	*sandboxPath = [logComponents lastObject];
    
    if (sandboxPath != nil) {
        NSInteger	bundleIDIndex = [logComponents count] - 5;
        
        if (bundleIDIndex >= 0) {
            NSString		*bundleID = [logComponents objectAtIndex: bundleIDIndex];
            SimulatorApp	*appInfo = [self appInfoWithBundleID: bundleID];
            
            if (appInfo != nil && !appInfo.sandboxPath) {
                appInfo.sandboxPath = sandboxPath;
            }
        }
    }
}

- (void) cleanupAndRefineAppList
{
    NSMutableArray		*mysteryApps = [NSMutableArray array];
    
    for (SimulatorApp *appInfo in self.appList) {
        if (!appInfo.hasValidPath) {
            [mysteryApps addObject: appInfo];
        }
    }
    
    [self.appList removeObjectsInArray: mysteryApps];
    [self.appList sortUsingDescriptors: @[ [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES ]]];
    
    for (SimulatorApp *appInfo in self.appList) {
        [appInfo refinePaths];
    }
}

- (SimulatorApp *) appInfoWithBundleID: (NSString *) inBundleID
{
    SimulatorApp	*appInfo = nil;
    NSInteger		appIndex;
    
    appIndex = [self.appList indexOfObjectPassingTest: ^(id inObject, NSUInteger inIndex, BOOL *outStop) {
        SimulatorApp		*appInfo = inObject;
        
        *outStop = [appInfo.bundleID isEqualToString: inBundleID];
        
        return *outStop;
    }];
    
    if (appIndex == NSNotFound) {
        appInfo = [[SimulatorApp alloc] initWithBundleID:inBundleID simulator:self];
        [self.appList addObject: appInfo];
    }
    else {
        appInfo = [self.appList objectAtIndex: appIndex];
    }
    
    return appInfo;
}
@end
