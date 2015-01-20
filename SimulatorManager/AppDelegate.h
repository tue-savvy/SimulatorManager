//
//  AppDelegate.h
//  SimulatorManager
//

#import <Cocoa/Cocoa.h>
#import "LaunchAtLoginController.h"

#define RecentAppsOnKey @"RecentAppsOn"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>{
    IBOutlet NSMenu *menu;
    IBOutlet NSArrayController *arrayController;
    NSStatusItem *statusItem;
    LaunchAtLoginController *launchAtLoginController;
}

@end