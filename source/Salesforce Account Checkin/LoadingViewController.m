//
//  LoadingViewController.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/27/11.
//

#import "LoadingViewController.h"
#import "UserSession.h"
#import "LoginViewController.h"
#import "AccountListController.h"
#import "OAuth.h"

@implementation LoadingViewController

// switches to teh account search/listview, we use setViewControllers so that the this
// view controller is removed from the navigation heiracrchy, and the account list becomes the root view.
-(void)startList:(UserSession *)session {
    AccountListController *ac = [[[AccountListController alloc] initWithSession:session] autorelease];
    [self.navigationController setViewControllers:[NSArray arrayWithObject:ac] animated:YES];
}

// called by the LoginViewController once its finished authenticating the user.
-(void)LoginViewController:(LoginViewController *)loginController userAuthenticated:(UserSession *)userSession {
    [self startList:userSession];
}

// pop the login UI
-(void)startLoginUi {
    LoginViewController *login = [[[LoginViewController alloc] init] autorelease];
    login.modalPresentationStyle = UIModalPresentationFormSheet;
    login.delegate = self;
    [self presentModalViewController:login animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setToolbarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES];
    
    // Do any additional setup after loading the view from its nib.
    UserSession *session = [UserSession persistedUserSession];
    if (session == nil) {
        [self startLoginUi];
    } else {
        [session refreshWithClientId:[OAuth consumerKey] whenDone:^(NSError *error) {
            if (error == nil) {
                [self startList:session];
            } else {
                [self startLoginUi];
            }
        }];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

@end
