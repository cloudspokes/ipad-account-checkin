//
//  LoadingViewController.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/27/11.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"

// This ViewController shows the splash screen, and then checks for a saved
// oauth token, if there isn't one, or its invalid, show the login view
// otherwise move onto the account search/list view.
@interface LoadingViewController : UIViewController <LoginViewControllerDelegate> {
    
}

@end
