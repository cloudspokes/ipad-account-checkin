//
//  DirectionsViewController.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/28/11.
//

#import "DirectionsViewController.h"
#import "AccountInfo.h"
#import "MyAppDelegate.h"

@implementation DirectionsViewController

@synthesize account=_account, current=_current, webview=_webview;

-(id)initWithRowPointOfInterest:(AccountInfo *)row {
    self = [super initWithNibName:@"DirectionsViewController" bundle:nil];
    self.account = row;
    return self;
}

- (void)dealloc {
    [_account release];
    [_webview release];
    [_current release];
    [super dealloc];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"wb error : %@", error);
}

// we need to tell the html/javascript about the particulars of the locations we care about, we could
// of either manipulated the html/javascript before loading it, but that can get messy, so we leave it
// alone and instead inject javascript requests into the webview once its loaded the html.
// the first one to initialize does the initial map creation and wire up.
// and the 2nd one actually gets it to calculate and show the route between the 2 points.
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (loadingStep == 1) {
        NSString *js = [NSString stringWithFormat:@"calcRoute(%f,%f,%f,%f);",
            self.current.coordinate.latitude, self.current.coordinate.longitude,
            self.account.coordinate.latitude, self.account.coordinate.longitude];
        NSLog(@"js : %@", js);
        [self.webview stringByEvaluatingJavaScriptFromString:js];
        loadingStep = 2;
    }
    if (loadingStep == 0) {
        NSString *js = [NSString stringWithFormat:@"initialize(%f,%f);", self.current.coordinate.latitude, self.current.coordinate.longitude];
        NSLog(@"js : %@", js);
        [self.webview stringByEvaluatingJavaScriptFromString:js];
        loadingStep = 1;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Directions";
    self.current = [[(MyAppDelegate *)[[UIApplication sharedApplication] delegate] locationManager] location];
    
    // load the html/javascript file from our local resource bundle.
    NSString *fn = [[NSBundle mainBundle] pathForResource:@"directions" ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:fn encoding:NSUTF8StringEncoding error:nil];
    self.webview.delegate = self;
    loadingStep = 0;
    [self.webview loadHTMLString:html baseURL:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
