//
//  AccountDetailViewController.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/24/11.
//

#import <UIKit/UIKit.h>

@class UserSession;
@class AccountInfo;

// the detail view, this shows account, opportunity and activity data, with the ability to 
// launch a checkin form, or a directions view
@interface AccountDetailViewController : UITableViewController {
    
}

-(id)initWithSession:(UserSession *)session andAccount:(AccountInfo *)account;

@property (retain, readonly) AccountInfo *accountInfo;
@property (retain, readonly) UserSession *session;

@end
