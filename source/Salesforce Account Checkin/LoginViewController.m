//
//  LoginViewController.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/23/11.
//

#import "LoginViewController.h"
#import "UserSession.h"
#import "MyAppDelegate.h"
#import "OAuth.h"

@implementation LoginViewController

static NSString *OAUTH_CALLBACK  = @"https://login.salesforce.com/services/oauth2/success";

@synthesize delegate=_delegate;

- (void)dealloc {
    [webview release];
    [super dealloc];
}

// extract the data we need out of the callback #fragment, create a UserSession from it, and off we go.
-(void)authComplete:(NSURL *)callbackUri {
    NSString *fragment = [callbackUri fragment];
    NSArray * parts = [fragment componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString *p in parts) {
        NSArray *kn = [p componentsSeparatedByString:@"="];
        if ([kn count] == 1)
            [params setObject:@"" forKey:[kn objectAtIndex:0]];
        else
            [params setObject:[[kn objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[kn objectAtIndex:0]];
    }
    NSLog(@"callback params : %@", params);
    UserSession *s = [[[UserSession alloc] init] autorelease];
    s.refreshToken = [params objectForKey:@"refresh_token"];
    s.accessToken  = [params objectForKey:@"access_token"];
    s.loginHost    = @"https://login.salesforce.com";
    s.instanceHost = [params objectForKey:@"instance_url"];
    [s persist];
    
    [self dismissModalViewControllerAnimated:YES];
    [self.delegate LoginViewController:self userAuthenticated:s];
}

// check to see if this is the oauth completion callback with our authentication info.
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[[request URL] absoluteString] hasPrefix:OAUTH_CALLBACK]) {
        [self authComplete:[request URL]];
        return FALSE;
    }
    return TRUE;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // build the URL to the start of the OAuth flow, then get the webview to load it.
    NSString *p = [NSString stringWithFormat:@"https://%@/services/oauth2/authorize?response_type=token&display=touch&client_id=%@&redirect_uri=%@",
                   @"login.salesforce.com",
                   [[OAuth consumerKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                   [OAUTH_CALLBACK stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:p]];
    [webview loadRequest:req];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
