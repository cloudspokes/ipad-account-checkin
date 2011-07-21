//
//  CheckinViewController.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/26/11.
//

#import <UIKit/UIKit.h>

@class UserSession;
@class AccountInfo;

// This shows the check-in form with the subject & comments, and creates the activity when the hit save.
@interface CheckinViewController : UIViewController {
    
}
-(id)initWithSession:(UserSession *)session account:(AccountInfo *)record;

@property (retain) IBOutlet UITextView *comment;
@property (retain) IBOutlet UITextField *subject;
@property (retain) IBOutlet UIActivityIndicatorView *progress;

@property (readonly) AccountInfo *account;
@property (readonly) UserSession *session;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

@end
