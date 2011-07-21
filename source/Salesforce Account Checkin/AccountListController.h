//
//  RootViewController.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/23/11.
//

#import <UIKit/UIKit.h>

@class UserSession;

// this is the account search / results list view.
// this controller is also responsible for getting the current location from the Core Location framework.
@interface AccountListController : UIViewController <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate> {
    CLLocationManager   *locationManager;
    UserSession         *session;
}

-(id)initWithSession:(UserSession *)session;

@property (retain) IBOutlet UITextField *searchDistance;
@property (retain) IBOutlet UILabel     *distanceLabel;
@property (retain) IBOutlet UIButton    *searchButton;
@property (retain) IBOutlet UIActivityIndicatorView *searchProgress;

@property (retain) IBOutlet UITableView *tableView;
@property (retain) IBOutlet MKMapView   *mapView;

@property (retain) NSArray  *accounts;
@property (retain) NSString *savedSearchDistance;
@property (assign) MKCoordinateRegion resultsRegion;
@property (assign) BOOL mapViewIsShown;

@property (retain) UIBarButtonItem *mapViewButton;
@property (retain) UIBarButtonItem *tableViewButton;

-(IBAction)searchAccounts:(id)sender;

@end
