//
//  RootViewController.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/23/11.
//

#import "AccountListController.h"
#import "UserSession.h"
#import "MyAppDelegate.h"
#import "HttpJsonRequest.h"
#import "Geo.h"
#import "AccountInfo.h"
#import "AccountDetailViewController.h"
#import "LoadingViewController.h"
#import "DistanceUnit.h"
#import "TableColumnsCell.h"

@interface AccountListController ()
-(MKCoordinateRegion)regionForSelfAndAccounts:(NSArray *)accounts;
@end

@implementation AccountListController

static NSString *DISTANCE_UNIT =  @"DistanceUnit";

@synthesize tableView=_tableView, mapView=_mapView;
@synthesize accounts=_accounts, searchDistance=_searchDistance;
@synthesize searchButton=_searchButton, searchProgress=_searchProgress;
@synthesize distanceLabel=_distanceLabel, savedSearchDistance=_savedSearchDistance;
@synthesize mapViewButton=_mapViewButton, tableViewButton=_tableViewButton;
@synthesize resultsRegion=_resultsRegion, mapViewIsShown=_mapViewIsShown;

-(id)initWithSession:(UserSession *)theSession {
    self = [super initWithNibName:@"AccountListController" bundle:nil];
    session = [theSession retain];
    self.mapViewIsShown = NO;
    return self;
}

// This takes the list of accounts returned by the SOQL query and does some post processing before display them to the user
// it specifically,
//  1) it builds an AccountInfo object for each row, which encapsulates some common helpers/accessors.
//  2) calculates if the result is within the search radius (the query uses a square location filter, so we need to filter the corners out)
//  3) it sorts the results by distance, then name.
//  4) finally, it updates the UI with the post processed results.
-(void)postProcessQueryResults:(NSDictionary *)queryResult withLocation:(CLLocation *)location andRadius:(double)radiusInUnits {
    NSArray *rows = [queryResult objectForKey:@"records"];

    // check distance from location and filter if needed.
    NSMutableArray *filteredRows = [NSMutableArray arrayWithCapacity:[rows count]];
    CLLocationDistance radius = [[[Geo geoConfig] distanceUnit] toMeters:radiusInUnits];
    for (NSDictionary *row in rows) {
        AccountInfo *account = [AccountInfo accountInfo:row withDistanceFrom:location];
        if ([account distance] > radius) continue;
        [filteredRows addObject:account];
    }
    // sort by distance desc.
    NSSortDescriptor *sortDistance = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    NSSortDescriptor *sortName = [NSSortDescriptor sortDescriptorWithKey:@"sobject.Name" ascending:YES];
    [filteredRows sortUsingDescriptors:[NSArray arrayWithObjects:sortDistance, sortName, nil]];

    // calculate the map region to display
    MKCoordinateRegion region = [self regionForSelfAndAccounts:filteredRows];

    // update UI
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.searchButton.enabled = YES;
        [self.searchProgress stopAnimating];
        
        // remove the old pins
        [self.mapView removeAnnotations:self.accounts];

        self.resultsRegion = region;
        self.accounts = filteredRows;
        [self.tableView reloadData];

        // if the map is showing, update it.
        if (self.mapView.alpha == 1.0)
            [self.mapView setRegion:region animated:YES];

        // show all the account pins
        [self.mapView addAnnotations:self.accounts];

        // if this is the first search, turn on the map view button
        if (self.navigationItem.rightBarButtonItem == nil)
            self.navigationItem.rightBarButtonItem = self.mapViewButton;
    });
}

// this is called to start a search, we get our current location, buuld a soql query and start a http request for it.
-(IBAction)searchAccounts:(id)sender {
    self.searchButton.enabled = NO;
    [self.searchProgress startAnimating];

    CLLocation *location = locationManager.location;
    double distanceInUnits = [self.searchDistance.text doubleValue];
    
    Geo *g = [Geo geoConfig];
    NSString *soql = [NSString stringWithFormat:@"select id,name,%@,%@,%@ from account where %@",
                      g.longitudeFieldName, g.latitudeFieldName, g.addressFieldName,
                      [g buildFilter:distanceInUnits center:location.coordinate]];
    
    NSString *query = [NSString stringWithFormat:@"/services/data/v21.0/query?q=%@", [soql stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *queryUrl = [NSURL URLWithString:query relativeToURL:session.instanceUrl];
    
    [[HttpJsonRequest httpJsonRequestFor:session] getJsonFromUrl:queryUrl 
                                            callbackOnMainThread:NO 
                                                        whenDone:^(NSUInteger httpStatusCode, NSObject *results, NSError *err) {
        [self postProcessQueryResults:(NSDictionary *)results withLocation:location andRadius:distanceInUnits];
    }];
}

// Core Location will make calls to this to tell us about location changes, we update the Search Button to say search instead of waiting for location
// once we get a location
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"location update from %@ to %@", oldLocation, newLocation);
    self.searchButton.enabled = YES;
    [self.searchButton setTitle:@"Search" forState:UIControlStateDisabled];
    [self.searchProgress stopAnimating];
    [self.searchDistance becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Search Results";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.accounts count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ListCell";
    
    TableColumnsCell *cell = (TableColumnsCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[TableColumnsCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                        reuseIdentifier:CellIdentifier 
                                            columnSizes:[NSArray arrayWithObjects:
                                                         [NSNumber numberWithInt:0],    // zero gives you a flexible width column
                                                         [NSNumber numberWithInt:280],
                                                         [NSNumber numberWithInt:100], 
                                                         nil]] autorelease];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [[[cell columnLabels] objectAtIndex:1] setNumberOfLines:2];
    }

    // Configure the cell.
    AccountInfo *row = [self.accounts objectAtIndex:indexPath.row];
    [cell setColumn:0 text:row.name];
    [cell setColumn:1 text:row.address];
    [cell setColumn:2 text:[row formattedDistanceInUnits:[[Geo geoConfig] distanceUnit]]];
    return cell;
}

// the user selected an account, either from the table or the mapview, drill down to the detail view.
-(void)userSelectedAnAccount:(AccountInfo *)account {
    AccountDetailViewController *detailViewController = [[[AccountDetailViewController alloc] initWithSession:session 
                                                                                                   andAccount:account] autorelease];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

// the user selected a row in the results table, show the detail view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AccountInfo *account = [self.accounts objectAtIndex:indexPath.row];
    [self userSelectedAnAccount:account];
}

// the user clicked the logout button, remove the saved oauth info, and go back to the start.
-(void)logout:(id)sender {
    [UserSession removedPersistedUserSession];
    LoadingViewController *lvc = [[[LoadingViewController alloc] initWithNibName:@"LoadingViewController" bundle:nil] autorelease];
    [self.navigationController setViewControllers:[NSArray arrayWithObject:lvc] animated:YES];
}

-(void)setDistanceUnit:(NSObject<DistanceUnit> *)unit {
    [[Geo geoConfig] setDistanceUnit:unit];
    self.distanceLabel.text = [unit displayLong];
    [self.tableView reloadData];
}

-(void)setUnits:(id)sender {
    NSObject<DistanceUnit> *selected = [[DistanceUnits units] objectAtIndex:[sender tag]];
    [[NSUserDefaults standardUserDefaults] setObject:[selected displayShort] forKey:DISTANCE_UNIT];
    [self setDistanceUnit:selected];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.title = @"Nearby Accounts";
    // button for navigation bar
    if (self.mapViewButton == nil) {
        self.mapViewButton = [[[UIBarButtonItem alloc] initWithTitle:@"Map View" 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:self 
                                                                  action:@selector(showMapView:)] autorelease];
    }
    if (self.tableViewButton == nil) {
        self.tableViewButton = [[[UIBarButtonItem alloc] initWithTitle:@"Table View" 
                                                                 style:UIBarButtonItemStyleBordered 
                                                                target:self 
                                                                action:@selector(showTableView:)] autorelease];
    }
    
    // build the buttons for the toolbar at the bottom, there's a button for each distance unit, and then a logout button on the right.
    NSMutableArray *buttons = [NSMutableArray array];
    NSUInteger idx = 0;
    for (NSObject<DistanceUnit> *u in [DistanceUnits units]) {
        UIBarButtonItem *b = [[[UIBarButtonItem alloc] initWithTitle:[u displayLong] 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(setUnits:)] autorelease];
        b.tag = idx++;
        [buttons addObject:b];
    }
    UIBarButtonItem *sp = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    UIBarButtonItem *lo = [[[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logout:)] autorelease];
    [buttons addObject:sp];
    [buttons addObject:lo];
    self.toolbarItems = buttons;

    // restore the distance type that the user last selected.
    NSString *distanceType = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT];
    NSObject<DistanceUnit> *unit = [DistanceUnits unitWithDisplayShort:distanceType];
    if (unit == nil) unit = [[DistanceUnits units] objectAtIndex:0];
    [self setDistanceUnit:unit];
    
    // because viewDidLoad can get called multiple times (under memory pressure while the user is on a view further down)
    // we have to reset out UI state to where  we are WRT to finding out our location.
    if (self.savedSearchDistance != nil)
        self.searchDistance.text = self.savedSearchDistance;
    
    if (locationManager == nil) {
        [self.searchProgress startAnimating];
        [self.searchButton setTitle:@"Waiting for location ..." forState:UIControlStateDisabled];
        self.searchButton.enabled = NO;
    } else {
        [self.searchButton setTitle:@"Search" forState:UIControlStateDisabled];
        self.searchButton.enabled = YES;
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [[[[UIAlertView alloc] initWithTitle:@"Location Services" 
                                     message:@"This application requires Location Services to be enabled, please enable them in the Settings application" 
                                    delegate:nil 
                           cancelButtonTitle:@"Close" 
                           otherButtonTitles:nil] autorelease] show];
    }
    
    if (self.accounts != nil) {
        // setup the map view if we're coming back to it, but its been unloaded.
        [self.mapView setRegion:self.resultsRegion animated:NO];
        [self.mapView addAnnotations:self.accounts];
        self.mapView.hidden = NO;
        self.mapView.alpha   = self.mapViewIsShown ? 1.0 : 0.0;
        self.tableView.alpha = self.mapViewIsShown ? 0.0 : 1.0;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    if (locationManager == nil) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locationManager.distanceFilter = 50;
        [locationManager startUpdatingLocation];
        [(MyAppDelegate *)[[UIApplication sharedApplication] delegate] setLocationManager:locationManager];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    self.savedSearchDistance = [self.searchDistance text];
}

CLLocationDegrees mid(CLLocationDegrees a, CLLocationDegrees b) {
    return (a + b) / 2;
}

// calculates the region that encloses all the accounts and the current location.
-(MKCoordinateRegion)regionForSelfAndAccounts:(NSArray *)accounts {
    CLLocationCoordinate2D user = [[locationManager location] coordinate];
    CLLocationCoordinate2D min = user, max = user;
    // loop through all the accounts, expand the min..max region as we find points outside it.
    for (AccountInfo *acc in accounts) {
        CLLocationCoordinate2D p = [acc coordinate];
        min.longitude = MIN(min.longitude, p.longitude);
        min.latitude = MIN(min.latitude, p.latitude);
        max.longitude = MAX(max.longitude, p.longitude);
        max.latitude = MAX(max.latitude, p.latitude);
    }
    // calculate the center point.
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(mid(min.latitude, max.latitude), mid(min.longitude, max.longitude));
    // calculate the span (size) of the region
    MKCoordinateSpan span = MKCoordinateSpanMake(ABS(max.latitude - min.latitude), ABS(max.longitude - min.longitude));
    // and we're done.
    return MKCoordinateRegionMake(center, span);
}

-(void)showTableView:(id)sender {
    [self.navigationItem setRightBarButtonItem:self.mapViewButton animated:YES];
    [UIView animateWithDuration:0.6 animations:^(void) {
        self.mapView.alpha = 0.0;
        self.tableView.alpha = 1.0;
    }];
    self.mapViewIsShown = NO;
}

-(void)showMapView:(id)sender {
    [self.mapView setAlpha:0];
    [self.mapView setHidden:NO];
    [self.mapView setRegion:self.resultsRegion animated:YES];
    [self.navigationItem setRightBarButtonItem:self.tableViewButton animated:YES];
    
    [UIView animateWithDuration:0.6 animations:^(void) {
        self.mapView.alpha = 1.0;
        self.tableView.alpha = 0.0;
    }];
    self.mapViewIsShown = YES;
}

// the user tapped the disclouse button in the map annotation. (aka they selected that account)
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    AccountInfo *account = [view annotation];
    [self userSelectedAnAccount:account];
}

// we implement this MKMapViewDelegate method so that we can set a disclouse button on the right of the callout.
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    
    // try to dequeue an existing pin view first
    static NSString* AnnotationIdentifier = @"AccountAnnotationIdentifier";
    MKPinAnnotationView* pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    if (pinView == nil) {
        // create one
        pinView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier] autorelease];
        pinView.canShowCallout = YES;
        // create a disclose button to appear in the right hand side of the callout
        UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        pinView.rightCalloutAccessoryView = button;
    } else {
        // just update the annotation for the view
        pinView.annotation = annotation;
    }
    return pinView;
}

- (void)dealloc {
    [_mapViewButton release];
    [_tableViewButton release];
    [_tableView release];
    [_mapView release];
    [_savedSearchDistance release];
    [_searchDistance release];
    [_accounts release];
    [_searchButton release];
    [_searchProgress release];
    [_distanceLabel release];
    [locationManager release];
    [session release];
    [super dealloc];
}

@end
