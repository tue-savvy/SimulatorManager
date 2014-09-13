//
//  SimulatorApp.m
//  SimulatorManager
//
//  Created by Sky Dev on 9/13/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import "SimulatorApp.h"
#import "Simulator.h"

@implementation SimulatorApp
- (instancetype)initWithPath:(NSString *)path  simulator:(Simulator *)simulator {
    self = [super init];
    if (self) {
        self.path = path;
        self.simulator = simulator;
        [self loadAppInfo];
    }
    return self;
}
- (NSString *)bundlePath {
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    
    for (NSString *name in contents) {
        if ([name.pathExtension isEqualToString:@"app"]) {
            return [self.path stringByAppendingPathComponent:name];
        }
    }
    return nil;
}
- (NSString *)dataPath {
    return [self.simulator appDataPath:self];
}
- (void)loadAppInfo {
    NSString *plistFile = [[self bundlePath] stringByAppendingPathComponent:@"Info.plist"];
    if (!plistFile) return;
    
    NSDictionary *appInfoDict = [NSDictionary dictionaryWithContentsOfFile:plistFile];
    NSString *displayName = appInfoDict[@"CFBundleDisplayName"];
    if (!displayName) {
        displayName = appInfoDict[@"CFBundleName"];
    }
    self.bundleID = appInfoDict[(NSString *)kCFBundleIdentifierKey];
    self.name = displayName;
}


@end
