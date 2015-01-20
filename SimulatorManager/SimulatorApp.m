//
//  SimulatorApp.m
//  SimulatorManager
//
//  Created by Tue Nguyen on 9/13/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import "SimulatorApp.h"
#import "Simulator.h"
@interface SimulatorApp()

@end
@implementation SimulatorApp

- (instancetype)initWithBundleID:(NSString *)bundleID simulator:(Simulator *)simulator {
    self = [super init];
    if (self) {
        self.bundleID = bundleID;
        self.simulator = simulator;
    }
    return self;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ (%@, %@)", self.bundleID, self.name, self.bundlePath];
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

- (void) updateFromLastLaunchMapInfo: (NSDictionary *) inMapInfo
{
    self.bundlePath = inMapInfo[@"BundleContainer"];
    self.sandboxPath = inMapInfo[@"Container"];
}

- (void) updateFromAppStateInfo: (NSDictionary *) inStateInfo
{
    NSDictionary	*compatInfo = inStateInfo[@"compatibilityInfo"];
    
    if (compatInfo != nil) {
        self.bundlePath = compatInfo[@"bundlePath"];
        self.sandboxPath = compatInfo[@"sandboxPath"];
    }
}

- (void) refinePaths
{
    NSFileManager	*fileManager = [NSFileManager defaultManager];
    NSURL			*infoURL;
    
    if (self.bundlePath != nil) {
        if ([[self.bundlePath lastPathComponent] rangeOfString: @".app"].location == NSNotFound) {
            NSURL					*bundleURL = [[NSURL alloc] initFileURLWithPath: self.bundlePath];
            NSURL					*appURL;
            NSDirectoryEnumerator	*dirEnum = [fileManager enumeratorAtURL: bundleURL includingPropertiesForKeys: nil
                                                                  options: NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler: nil];
            
            while ((appURL = [dirEnum nextObject])) {
                NSString	*appPath = [appURL path];
                
                if ([[appPath lastPathComponent] rangeOfString: @".app"].location != NSNotFound) {
                    // setter won't let us reset so access ivar directly
                    self.bundlePath = appPath;
                    break;
                }
            }
        }
        
        infoURL = [[NSURL alloc] initFileURLWithPath: self.bundlePath];
        infoURL = [infoURL URLByAppendingPathComponent: @"Info.plist"];
        if (infoURL != nil && [fileManager fileExistsAtPath: [infoURL path]]) {
            NSData		*plistData = [NSData dataWithContentsOfURL: infoURL];
            
            if (plistData != nil) {
                NSDictionary	*plistInfo;
                
                plistInfo = [NSPropertyListSerialization propertyListWithData: plistData options: NSPropertyListImmutable format: nil error: nil];
                if (plistInfo != nil) {
                    [self discoverAppInfoFromPList: plistInfo];
                }
            }
        }
    }
}

- (void) discoverAppInfoFromPList: (NSDictionary *) inPListInfo
{
    NSDictionary	*bundleIcons = inPListInfo[@"CFBundleIcons"];
    
    NSString *displayName = inPListInfo[@"CFBundleDisplayName"];
    if (!displayName) {
        displayName = inPListInfo[@"CFBundleName"];
    }
    
    self.name = displayName;
//    self.appShortVersion = inPListInfo[@"CFBundleShortVersionString"];
//    self.appVersion = inPListInfo[(__bridge NSString *)kCFBundleVersionKey];
    
    if (bundleIcons != nil) {
        NSArray			*bundleIconFiles = bundleIcons[@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"];
        
        if (bundleIconFiles) {
            for (NSString *iconName in bundleIconFiles) {
                NSString	*fullIconName = iconName;
                NSURL		*iconURL;
                
                if (![iconName.pathExtension length]) {
                    fullIconName = [iconName stringByAppendingPathExtension: @"png"];
                }
                iconURL = [[[NSURL alloc] initFileURLWithPath: self.bundlePath] URLByAppendingPathComponent: fullIconName];
                self.appIcon = [self imageAtURL: iconURL withMinimumWidth: 57.0];
                
                if (self.appIcon == nil) {
                    fullIconName = [NSString stringWithFormat: @"%@@2x.png", iconName];
                    iconURL = [[[NSURL alloc] initFileURLWithPath: self.bundlePath] URLByAppendingPathComponent: fullIconName];
                    self.appIcon = [self imageAtURL: iconURL withMinimumWidth: 57.0];
                    if (self.appIcon != nil) {
                        break;
                    }
                }
                else {
                    break;
                }
            }
        }
    }
    
    if (self.appIcon == nil) {
        self.appIcon = [NSImage imageNamed: @"defaultIcon"];
    }
}

- (NSImage *) imageAtURL: (NSURL *) inImageURL
        withMinimumWidth: (CGFloat) inMinWidth
{
    NSImage		*image = nil;
    
    if (inImageURL != nil && [[NSFileManager defaultManager] fileExistsAtPath: [inImageURL path]]) {
        image = [[NSImage alloc] initWithContentsOfURL: inImageURL];
        if (image != nil) {
            if (image.size.width < inMinWidth) {
                image = nil;
            }
        }
    }
    
    return image;
}
- (BOOL)hasValidPath {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.bundlePath];
}
@end
