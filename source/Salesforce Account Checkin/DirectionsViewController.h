//
//  DirectionsViewController.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/28/11.
//

#import <UIKit/UIKit.h>

@class AccountInfo;

// shows a google map view with directions from the current location, to the indicated Account
// the built in MapKit framework doesn't support directions, so we have an embeded webview
// and use the google maps API to show directions.
@interface DirectionsViewController : UIViewController <UIWebViewDelegate> {
    int loadingStep;
}

-(id)initWithRowPointOfInterest:(AccountInfo *)row;

@property (retain) IBOutlet UIWebView *webview;

@property (retain) AccountInfo *account;
@property (retain) CLLocation *current;

@end
