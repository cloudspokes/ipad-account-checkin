//
//  Salesforce_Account_CheckinAppDelegate.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/23/11.
//

#import <UIKit/UIKit.h>

@interface MyAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@property (retain) CLLocationManager *locationManager;

@end
