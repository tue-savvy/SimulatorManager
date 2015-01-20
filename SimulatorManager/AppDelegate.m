//
//  AppDelegate.m
//  SimulatorManager
//

#import "AppDelegate.h"
#import "Simulator.h"
#import "RecentAppsManager.h"
@interface AppDelegate()<NSUserNotificationCenterDelegate>

@property (nonatomic, strong) NSMutableArray *simulators;
@property (weak) IBOutlet NSMenuItem *launchAtLoginMenuItem;
@property (nonatomic, strong) NSDate *lastModDate;
@property (nonatomic, strong) RecentAppsManager *recentManager;
@property (assign, nonatomic) BOOL recentAppUpdate;
@property (weak) IBOutlet NSMenuItem *eraseMenuItem;

@property (nonatomic, assign) BOOL recentAppDisabled;
@property (nonatomic, weak) IBOutlet NSMenuItem *recentAppMenuItem;

@end
@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

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
    
    NSImage * image = [NSImage imageNamed:@"StatusIcon"];
    [image setTemplate:YES];
    NSImage * alternateImage = [NSImage imageNamed:@"StatusIconAlt"];
    [alternateImage setTemplate:YES];
    
    [statusItem setImage:image];
    [statusItem setAlternateImage:alternateImage];
  
    self.recentAppDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:RecentAppsOnKey];
    if (self.recentAppDisabled)
      self.recentAppMenuItem.title = @"Enable Recent Apps";
    else
      self.recentAppMenuItem.title = @"Disable Recent Apps";

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
- (void)menuNeedsUpdate:(NSMenu *)menu {
    // Check when the config was last modified
    if ( [self needUpdateMenu]) {
        [self loadMenu];
    }
}

- (void) loadMenu {
    // Clear out the hosts so we can start over
    NSUInteger n = [[menu itemArray] count];
    for (int i=0;i<n-7;i++) {
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
    self.recentManager.simulators = simulators;
    [self.simulators sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    [self buildMenuForSimulator:self.simulators addToMenu:menu];
    
    //Load recent app
    BOOL recentAppDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:RecentAppsOnKey];
    if (!recentAppDisabled)
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
        menuItem.action = nil;//@selector(openSimulatorFolder:);
        [m insertItem:menuItem atIndex:menuIndex];
        [self buildApplicationMenu:[simulator applications] addToMenu:subMenu simulator:simulator];
    }
}
- (void)buildApplicationMenu:(NSArray *)apps addToMenu:(NSMenu *)m simulator:(Simulator *)simulator {
    NSFileManager *fileManager = [NSFileManager defaultManager];
  
      NSMenuItem* menuItem = [[NSMenuItem alloc] init];
      [menuItem setTitle:@"Simulator Folder"];
      [menuItem setRepresentedObject:simulator];
      menuItem.target = self;
      menuItem.action = @selector(openSimulatorFolder:);
      [m addItem:menuItem];
      NSString *rootPath = simulator.path;
      if (![fileManager fileExistsAtPath:rootPath]) {
        menuItem.image  = [NSImage imageNamed:@"warning"];
      }
  
    {
        
        NSString *dataPath = [simulator appDataPath];
        if ([fileManager fileExistsAtPath:dataPath]) {
            NSMenuItem* menuItem = [[NSMenuItem alloc] init];
            [menuItem setTitle:@"App Data Folder"];
            [menuItem setRepresentedObject:simulator];
            menuItem.target = self;
            menuItem.action = @selector(openSimulatorDataFolder:);
            [m addItem:menuItem];
        }
        
        NSMenuItem *separator = [NSMenuItem separatorItem];
        [m addItem:separator];
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
        NSString *dataPath = [app sandboxPath];
        if (![fileManager fileExistsAtPath:dataPath]) {
            menuItem.image  = [NSImage imageNamed:@"warning"];
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
    NSString *appDataPath = simulatorApp.sandboxPath;
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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[simulator appDataPath]]];
}
- (IBAction)eraseAllSimulators:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Are you sure you want to reset content and settings from all iOS Simulators?";
    alert.informativeText = @"All installed applications, content, and settings will be erased.\n\nPlease quit running Simulator before continue.";
    
    alert.alertStyle = NSWarningAlertStyle;
    
    [alert addButtonWithTitle:@"Reset"];
    [alert addButtonWithTitle:@"Don't Reset"];
    
    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        [self performEraseSimulators];
    }
}
- (void)performEraseSimulators {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Simulator Manager";
    notification.informativeText = @"Erasing Simulator...";
    [self.eraseMenuItem setEnabled:NO];
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *commandPath = [[NSBundle mainBundle] pathForResource:@"SimulatorErase" ofType:@"sh"];
        
        for (Simulator *simulator in self.simulators) {
            NSTask *eraseTask = [[NSTask alloc] init];
            [eraseTask setLaunchPath:commandPath];
            [eraseTask setArguments:@[simulator.UDID]];
            [eraseTask launch];
            [eraseTask waitUntilExit];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            notification.informativeText = @"All Simulators are erased";
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            [self.eraseMenuItem setEnabled:YES];
        });
    });
}

- (IBAction)toggleRecentApps:(id)sender
{
  NSMenuItem *menuItem = sender;
  if ([menuItem.title rangeOfString:@"Disable"].length > 0)
    menuItem.title = @"Enable Recent Apps";
  else
    menuItem.title = @"Disable Recent Apps";
  
  self.recentAppDisabled = !self.recentAppDisabled;
  [[NSUserDefaults standardUserDefaults] setBool:self.recentAppDisabled forKey:RecentAppsOnKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self loadMenu];
  
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
