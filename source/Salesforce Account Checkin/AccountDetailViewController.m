//
//  AccountDetailViewController.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/24/11.
//

#import "AccountDetailViewController.h"
#import "Geo.h"
#import "HttpJsonRequest.h"
#import "UserSession.h"
#import "TableColumnsCell.h"
#import "NSDictionary+Path.h"
#import "CheckinViewController.h"
#import "DirectionsViewController.h"
#import "AccountInfo.h"

@interface AccountDetailViewController()

@property (retain, nonatomic) NSDictionary *account;
@property (retain, nonatomic) NSArray *opportunities;
@property (retain, nonatomic) NSArray *activities;

@property (retain) NSArray *detailFieldNames;
@property (retain) NSArray *detailFieldLabels;

@property (retain) NSNumberFormatter *numberFormatter;
@property (retain) NSDateFormatter *dateFormatter;
@property (retain) NSDateFormatter *iso8601dateFormatter;

-(void)startQuery;
@end

@implementation AccountDetailViewController

@synthesize accountInfo=_accountInfo, session=_session, account=_account;
@synthesize opportunities=_opportunities, activities=_activities;
@synthesize detailFieldNames=_detailFieldNames, detailFieldLabels=_detailFieldLabels;
@synthesize numberFormatter=_numberFormatter, dateFormatter=_dateFormatter;
@synthesize iso8601dateFormatter=_iso8601dateFormatter;

-(id)initWithSession:(UserSession *)session andAccount:(AccountInfo *)account {
    self = [super initWithNibName:@"AccountDetailViewController" bundle:nil];
    _session = [session retain];
    _accountInfo = [account retain];
    // these are the field names, and labels that we show for the primary account data.
    self.detailFieldNames = [NSArray arrayWithObjects:@"Name", @"Description", @"Industry", @"Phone", @"Type", [[Geo geoConfig] addressFieldName], nil];
    self.detailFieldLabels = [NSArray arrayWithObjects:@"Name", @"Description", @"Industry", @"Phone", @"Type", @"Address", nil];

    // formatters use to translate the json numbers/dates into local formats.
    self.numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    self.dateFormatter.dateStyle = kCFDateFormatterMediumStyle;
    self.iso8601dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    self.iso8601dateFormatter.dateFormat = @"yyyy-MM-dd";
    [self startQuery];
    return self;
}

- (void)dealloc {
    [_session release];
    [_accountInfo release];
    [_account release];
    [_opportunities release];
    [_activities release];
    [_detailFieldNames release];
    [_detailFieldLabels release];
    [_numberFormatter release];
    [_dateFormatter release];
    [_iso8601dateFormatter release];
    [super dealloc];
}

-(void)startQuery {
    // start the query that gets all the data to populate the detail view, when the data turns up, update the UI
    NSString *soql = [NSString stringWithFormat:@"select id,%@,(select name,amount,stagename,closedate from opportunities where isClosed=false),(select subject,activityDate,status,priority,owner.name,who.name from openActivities) from account where id='%@'",
                      [self.detailFieldNames componentsJoinedByString:@","],
                      self.accountInfo.recordId];

    NSURL *query = [NSURL URLWithString:[NSString stringWithFormat:@"/services/data/v21.0/query?q=%@",
                                         [soql stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] relativeToURL:[self.session instanceUrl]];
    
    HttpJsonRequest *req = [[[HttpJsonRequest alloc] initFor:self.session] autorelease];
    [req getJsonFromUrl:query whenDone:^(NSUInteger httpStatusCode, NSObject *results, NSError *err) {
        
        self.account = [[(NSDictionary *)results objectForKey:@"records"] objectAtIndex:0];
        id opps = [self.account objectForKey:@"Opportunities"];
        if (opps != nil && opps != [NSNull null])
            self.opportunities = [opps objectForKey:@"records"];
        id acts = [self.account objectForKey:@"OpenActivities"];
        if (acts != nil && acts != [NSNull null])
            self.activities = [acts objectForKey:@"records"];

        [self.tableView reloadData];
        // can't checkin until we've loaded the data.
        UIBarButtonItem *checkin = [[UIBarButtonItem alloc] initWithTitle:@"Check-In" style:UIBarButtonItemStylePlain target:self action:@selector(checkin:)];
        [self.navigationItem setRightBarButtonItem:checkin animated:YES];
        [checkin release];
    }];
}

// launch the directions view.
-(void)showDirections:(id)sender {
    DirectionsViewController *c = [[[DirectionsViewController alloc] initWithRowPointOfInterest:self.accountInfo] autorelease];
    [self.navigationController pushViewController:c animated:YES];
}

// start the checkin view controller
-(void)checkin:(id)sender {
    CheckinViewController *checkin = [[[CheckinViewController alloc] initWithSession:self.session account:self.accountInfo] autorelease];
    checkin.modalPresentationStyle = UIModalPresentationFormSheet;
    checkin.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:checkin animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Details";
    self.tableView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

// Table data binding.

// 3 sections account details, opportuntities & activities
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Details";
        case 1: return @"Open Opportunities";
        case 2: return @"Open Activities";
    }
    return @"Who Knows?";
}

// Return the number of rows in the particular section.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return [self.detailFieldNames count];
        case 1: return [self.opportunities count] + 1;
        case 2: return [self.activities count] + 1;
    }
    return 0;
}

// futz with the height of the table rows depending on which row it is, allow more space for name, description
// and the related lists.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: 
            switch (indexPath.row) {
                case 0: return tableView.rowHeight * 1.5;
                case 1: return tableView.rowHeight * 3;
            }
            break;
        case 2: return tableView.rowHeight * 1.4;
    }
    return tableView.rowHeight;
}

// builds a table row cell for one of the account detail fields.
- (UITableViewCell *)tableView:(UITableView *)tableView accountDetailCellAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *DetailCellIdentifier = @"DetailCell";

    TableColumnsCell *cell = (TableColumnsCell *)[tableView dequeueReusableCellWithIdentifier:DetailCellIdentifier];
    if (cell == nil) {
        cell = [[[TableColumnsCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                        reuseIdentifier:DetailCellIdentifier 
                                            columnSizes:[NSArray arrayWithObjects:
                                                         [NSNumber numberWithInt:110],
                                                         [NSNumber numberWithInt:0], nil]] autorelease];
    }
    int numLines = indexPath.row == 0 ? 2 : indexPath.row == 1 ? 5 : 1;
    NSString *fn = [self.detailFieldNames objectAtIndex:indexPath.row];
    id v = [self.account objectForKey:fn];
    [cell setColumn:0 text:[self.detailFieldLabels objectAtIndex:indexPath.row]];
    [[cell setColumn:1 text:v] setNumberOfLines:numLines];
    [cell setAccessoryType:indexPath.row == 5 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone];
    return cell;
}

// looks for a date field in the dictionary with key 'k', and converts to the local date display format.
// the source data from the json data will be in iso8601 format, e.g. 2011-05-03
-(NSString *)formattedDateWithKey:(NSString *)k inDictionary:(NSDictionary *)d {
    id v = [d objectForKey:k];
    if (v == nil || v == [NSNull null]) return @"";
    NSDate *date = [self.iso8601dateFormatter dateFromString:v];
    return [self.dateFormatter stringFromDate:date];
}

// builds a table row cell for the opportunities related list.
// the first row in the section is a table header row that shows the field labels for the related list.
- (UITableViewCell *)tableView:(UITableView *)tableView opportunityCellAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *OpptyCellIdentifier = @"OpptyCell";
    TableColumnsCell *cell = (TableColumnsCell *)[tableView dequeueReusableCellWithIdentifier:OpptyCellIdentifier];
    if (cell == nil) {
        cell = [[[TableColumnsCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                        reuseIdentifier:OpptyCellIdentifier 
                                            columnSizes:[NSArray arrayWithObjects:
                                                         [NSNumber numberWithInt:0],
                                                         [NSNumber numberWithInt:90],
                                                         [NSNumber numberWithInt:10],
                                                         [NSNumber numberWithInt:200], 
                                                         [NSNumber numberWithInt:120], nil]] autorelease];
        [[[cell columnLabels] objectAtIndex:1] setTextAlignment:UITextAlignmentRight];
    }
    if (indexPath.row == 0) {
        // show header row
        cell.backgroundColor = [UIColor grayColor];
        [cell setColumn:0 text:@"Name"];
        [cell setColumn:1 text:@"Amount"];
        [cell setColumn:3 text:@"Stage"];
        [cell setColumn:4 text:@"Close Date"];
    } else {
        // show data row
        cell.backgroundColor = [UIColor whiteColor];
        NSDictionary *oppty = [self.opportunities objectAtIndex:indexPath.row - 1];
        [cell setColumn:0 text:[oppty objectForKey:@"Name"]];
        [cell setColumn:1 text:[self.numberFormatter stringFromNumber:[oppty objectForKey:@"Amount"]]];
        [cell setColumn:3 text:[oppty objectForKey:@"StageName"]];
        [cell setColumn:4 text:[self formattedDateWithKey:@"CloseDate" inDictionary:oppty]];
    }
    return cell;
}

// builds a 2 line text string from 2 source strings, handling nils along the way.
-(NSString *)formatted2Row:(NSString *)l1 line2:(NSString *)l2 {
    l1 = l1 == nil ? @"" : l1;
    l2 = l2 == nil ? @"" : l2;
    return [NSString stringWithFormat:@"%@\r\n%@", l1, l2];
}

// builds a table row for the activity related list
// the first row in this section is a header row with the column labels.
// some of the columns in this section are double decker, a single label with a 2 line text value stuck in it.
- (UITableViewCell *)tableView:(UITableView *)tableView activityCellAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ActivityCellIdentifier = @"ActivityCell";
    TableColumnsCell *cell = (TableColumnsCell *)[tableView dequeueReusableCellWithIdentifier:ActivityCellIdentifier];
    if (cell == nil) {
        cell = [[[TableColumnsCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                        reuseIdentifier:ActivityCellIdentifier 
                                            columnSizes:[NSArray arrayWithObjects:
                                                         [NSNumber numberWithInt:0],
                                                         [NSNumber numberWithInt:125],
                                                         [NSNumber numberWithInt:125],
                                                         [NSNumber numberWithInt:125], nil]] autorelease];
        [[cell.columnLabels objectAtIndex:0] setNumberOfLines:2];
        [[cell.columnLabels objectAtIndex:1] setNumberOfLines:2];
        [[cell.columnLabels objectAtIndex:2] setNumberOfLines:2];
    }
    if (indexPath.row == 0) {
        // show header row
        cell.backgroundColor = [UIColor grayColor];
        [cell setColumn:0 text:@"Subject"];
        [cell setColumn:1 text:[self formatted2Row:@"Name" line2:@"Date"]];
        [cell setColumn:2 text:[self formatted2Row:@"Status" line2:@"Priority"]];
        [cell setColumn:3 text:@"Assigned To"];
    } else {
        // show data row
        cell.backgroundColor = [UIColor whiteColor];
        NSDictionary *activity = [self.activities objectAtIndex:indexPath.row - 1];
        [cell setColumn:0 text:[activity objectForKey:@"Subject"]];
        [cell setColumn:1 text:[self formatted2Row:[activity mapNilObjectForKey:@"Who" andChildKey:@"Name"] 
                                             line2:[self formattedDateWithKey:@"ActivityDate" inDictionary:activity]]];
        [cell setColumn:2 text:[self formatted2Row:[activity mapNilObjectForKey:@"Status"] 
                                             line2:[activity mapNilObjectForKey:@"Priority"]]];
        [cell setColumn:3 text:[activity mapNilObjectForKey:@"Owner" andChildKey:@"Name"]];
    }
    return cell;
}

// build a table row cell, delegate to different types of cells based on which section they're in.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0 : return [self tableView:tableView accountDetailCellAtIndexPath:indexPath];
        case 1 : return [self tableView:tableView opportunityCellAtIndexPath:indexPath];
        case 2 : return [self tableView:tableView activityCellAtIndexPath:indexPath];
    }
    return nil;
}

// helper that determines if this is the section/row for the address row. (which is the only selectable one)
- (BOOL)isAddressRow:(NSIndexPath *)path {
    return path.section == 0 && path.row == 5;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self isAddressRow:indexPath] ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isAddressRow:indexPath])
        [self showDirections:self];
}

@end
