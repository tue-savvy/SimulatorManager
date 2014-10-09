//
//  AppDelegate.m
//  SimulatorManager
//

#import "AppDelegate.h"
#import "Simulator.h"
#import "RecentAppsManager.h"
@interface AppDelegate()
@property (nonatomic, strong) NSMutableArray *simulators;
@property (weak) IBOutlet NSMenuItem *launchAtLoginMenuItem;
@property (nonatomic, strong) NSDate *lastModDate;
@property (nonatomic, strong) RecentAppsManager *recentManager;
@property (assign, nonatomic) BOOL recentAppUpdate;
@end
@implementation AppDelegate

- (NSString *)simulatorDevicesDirectory {
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = array.firstObject;
    return [libraryPath stringByAppendingPathComponent:@"Developer/CoreSimulator/Devices/"];
}

- (void) awakeFromNib {
    self.recentManager = [RecentAppsManager new];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentAppUpdate:) name:RecentAppUpdateNotification object:self.recentManager];
    // Create the status bar item
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:25.0];
    [statusItem setMenu:menu];
    [statusItem setHighlightMode:YES];
    [statusItem setImage:[NSImage imageNamed:@"StatusIcon"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"StatusIconAlt"]];

    launchAtLoginController = [[LaunchAtLoginController alloc] init];
    self.launchAtLoginMenuItem.state = launchAtLoginController.launchAtLogin ? NSOnState : NSOffState;
    // Needed to trigger the menuWillOpen event
    [menu setDelegate:self];
}

- (NSDate*) getMTimeFor: (NSString*) file {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[file stringByExpandingTildeInPath]
                                                                                error:nil];
    return [attributes fileModificationDate];
}
- (BOOL)needUpdateMenu {
    NSDate *currentModDate = [self getMTimeFor:[self simulatorDevicesDirectory]];
    if (!self.lastModDate || [self.lastModDate compare:currentModDate] != NSOrderedSame || self.recentAppUpdate) {
        self.lastModDate = currentModDate;
        return YES;
    }
    return NO;
}
- (void)recentAppUpdate:(NSNotification *)notification {
    self.recentAppUpdate = YES;
}
- (void)menuWillOpen:(NSMenu *)menu {
    // Check when the config was last modified
    if ( [self needUpdateMenu]) {
        [self loadMenu];
    }
}

- (void) loadMenu {
    // Clear out the hosts so we can start over
    NSUInteger n = [[menu itemArray] count];
    for (int i=0;i<n-4;i++) {
        [menu removeItemAtIndex:0];
    }
    
    
    
    //Load Simulator
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *simulatorDevicesDirectory = [self simulatorDevicesDirectory];
    NSArray *directoryContent = [fm contentsOfDirectoryAtPath:simulatorDevicesDirectory error:nil];
    NSMutableArray *simulators = [NSMutableArray array];
    for (NSString *folderName in directoryContent) {
        NSString *simulatorPath = [simulatorDevicesDirectory stringByAppendingPathComponent:folderName];
        
        Simulator *simulator = [[Simulator alloc] initWithPath:simulatorPath];
        if (simulator) [simulators addObject:simulator];
    }

    self.simulators = simulators;
    [self.simulators sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    [self buildMenuForSimulator:self.simulators addToMenu:menu];
    
    //Load recent app
    [self buildMenuForRecentsAddToMenu:menu];
}

- (void)buildMenuForSimulator:(NSArray *)simulatorArray addToMenu:(NSMenu *)m {
    for (NSInteger menuIndex = 0; menuIndex < simulatorArray.count; menuIndex++) {
        Simulator *simulator = simulatorArray[menuIndex];
        NSMenu* subMenu = [[NSMenu alloc] init];
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setRepresentedObject:simulator];
        [menuItem setTitle:[simulator.name stringByAppendingFormat:@" (%@)", simulator.runtimeVersion]];
        [menuItem setSubmenu:subMenu];
        menuItem.target = self;
        menuItem.action = @selector(openSimulatorFolder:);
        [m insertItem:menuItem atIndex:menuIndex];
        [self buildApplicationMenu:[simulator applications] addToMenu:subMenu simulator:simulator];
    }
}
- (void)buildApplicationMenu:(NSArray *)apps addToMenu:(NSMenu *)m simulator:(Simulator *)simulator {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    {
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:@"App Data Folder"];
        [menuItem setRepresentedObject:simulator];
        menuItem.target = self;
        menuItem.action = @selector(openSimulatorDataFolder:);
        [m addItem:menuItem];
        NSMenuItem *separator = [NSMenuItem separatorItem];
        [m addItem:separator];
        NSString *dataPath = [simulator appDataPath:nil];
        if (![fileManager fileExistsAtPath:dataPath]) {
            menuItem.image  = [NSImage imageNamed:@"Warning"];
        }
    }
    
    apps = [apps sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    for (SimulatorApp *app in apps) {
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setRepresentedObject:app];
        [menuItem setTitle:app.name?:@"<Unknown>"];
        [menuItem setRepresentedObject:app];
        menuItem.target = self;
        menuItem.action = @selector(openSimulatorApp:);
        [m addItem:menuItem];
        NSString *dataPath = [app dataPath];
        if (![fileManager fileExistsAtPath:dataPath]) {
            menuItem.image  = [NSImage imageNamed:@"Warning"];
        }
        
    }
    
    if (apps.count == 0) {
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:@"No App"];
        [m addItem:menuItem];
    }
}

- (void)buildMenuForRecentsAddToMenu:(NSMenu *)m {
    self.recentAppUpdate = NO;
    
    NSInteger menuIndex = 0;
    NSMenuItem* menuItem = [[NSMenuItem alloc] init];
    [menuItem setEnabled:NO];
    [menuItem setTitle:@"Recent Apps"];
    [m insertItem:menuItem atIndex:menuIndex++];
    
    NSArray *recentApps = [self.recentManager recentApps];
    
    for (SimulatorApp *app in recentApps) {
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setRepresentedObject:app];
        [menuItem setTitle:app.name?:@"<Unknown>"];
        [menuItem setRepresentedObject:app];
        menuItem.target = self;
        menuItem.action = @selector(openSimulatorApp:);
        [m insertItem:menuItem atIndex:menuIndex++];
    }
    
    if (recentApps.count == 0) {
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:@"No Recent"];
        [menuItem setEnabled:NO];
        [m insertItem:menuItem atIndex:menuIndex++];
    }
    
    //Add Separator
    [m insertItem:[NSMenuItem separatorItem] atIndex:menuIndex++];
}

- (void)openSimulatorApp:(NSMenuItem *)menuItem {
    SimulatorApp *simulatorApp = menuItem.representedObject;
    NSString *appDataPath = simulatorApp.dataPath;
    if (appDataPath) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:appDataPath]];
        [self.recentManager addRecentApp:simulatorApp];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Simulator Manager" defaultButton:@"Close" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Cannot find data folder for the app '%@'", simulatorApp.name];
        [alert runModal];
    }
}

- (void)openSimulatorFolder:(NSMenuItem *)menuItem {
    Simulator *simulator = menuItem.representedObject;
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:simulator.path]];
}

- (void)openSimulatorDataFolder:(NSMenuItem *)menuItem {
    Simulator *simulator = menuItem.representedObject;
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[simulator appDataPath:nil]]];
}
- (IBAction)launchAtLogin:(id)sender {
    NSMenuItem *menuItem = sender;
    if (menuItem.state == NSOffState) menuItem.state = NSOnState;
    else menuItem.state = NSOffState;
    
    launchAtLoginController.launchAtLogin = menuItem.state == NSOnState;
}

- (IBAction)showAbout:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://tue-savvy.github.io/"]];
}

- (IBAction)quit:(id)sender {
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [NSApp terminate:NSApp];
}

@end
