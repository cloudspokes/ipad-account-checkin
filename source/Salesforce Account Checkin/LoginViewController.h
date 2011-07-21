//
//  LoginViewController.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/23/11.
//

#import <UIKit/UIKit.h>

@class UserSession;
@class LoginViewController;

@protocol LoginViewControllerDelegate <NSObject>
-(void)LoginViewController:(LoginViewController *)loginController userAuthenticated:(UserSession *)userSession;
@end

// this view controller hosts the login UI, we just have a UIWebView
// and start it on the oauth dance, keeping an eye out for when its 
// done. When its done, we flag the delegate defined above.
@interface LoginViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView   *webview;
}

@property (assign) NSObject<LoginViewControllerDelegate> *delegate;

@end
