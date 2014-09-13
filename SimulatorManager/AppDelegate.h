//
//  AppDelegate.h
//  SimulatorManager
//

#import <Cocoa/Cocoa.h>
#import "LaunchAtLoginController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>{
    IBOutlet NSMenu *menu;
    IBOutlet NSArrayController *arrayController;
    NSStatusItem *statusItem;
    LaunchAtLoginController *launchAtLoginController;
}

- (void)menuWillOpen:(NSMenu *)menu;

@end