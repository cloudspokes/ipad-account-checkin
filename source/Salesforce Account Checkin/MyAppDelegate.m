//
//  Salesforce_Account_CheckinAppDelegate.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/23/11.
//

#import "MyAppDelegate.h"

@implementation MyAppDelegate

@synthesize window=_window;
@synthesize navigationController=_navigationController;
@synthesize locationManager=_locationManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Add the navigation controller's view to the window and display.
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)dealloc {
    [_window release];
    [_navigationController release];
    [_locationManager release];
    [super dealloc];
}

@end
