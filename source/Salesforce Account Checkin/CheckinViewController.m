//
//  CheckinViewController.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/26/11.
//

#import <QuartzCore/QuartzCore.h>
#import "CheckinViewController.h"
#import "HttpJsonRequest.h"
#import "JSON.h"
#import "iToast.h"
#import "AccountInfo.h"

@implementation CheckinViewController

@synthesize comment=_comment, subject=_subject, account=_account, progress=_progress, session=_session;

-(id)initWithSession:(UserSession *)session account:(AccountInfo *)account {
    self = [super initWithNibName:@"CheckinViewController" bundle:nil];
    _session = [session retain];
    _account = [account retain];
    return self;
}

- (void)dealloc {
    [_account release];
    [_session release];
    [_subject release];
    [_comment release];
    [_progress release];
    [super dealloc];
}

// final setup of the UI, the large text view doesn't have a bordered mode, so we have to do with this alternative border style
// but at least we can apply it the same to both text entry boxes.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.subject.layer.borderWidth = 2.0f;
    self.subject.layer.borderColor = [[UIColor grayColor] CGColor];
    self.comment.layer.borderWidth = 2.0f;
    self.comment.layer.borderColor = [[UIColor grayColor] CGColor];

    // tell teh subject field to move you to comments when you're done.
    [self.subject addTarget:self.comment action:@selector(becomeFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.subject becomeFirstResponder];
}

-(IBAction)cancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

// build a dictionary that represents the checkin activity we want to create, then POST it to the rest API and wait for the response.
-(void)save:(id)sender {
    NSMutableDictionary *c = [NSMutableDictionary dictionary];
    [c setObject:self.comment.text forKey:@"Description"];
    [c setObject:self.subject.text forKey:@"Subject"];
    [c setObject:@"Meeting" forKey:@"Type"];
    [c setObject:@"Completed" forKey:@"Status"];
    [c setObject:self.account.recordId forKey:@"WhatId"];
    
    [self.progress startAnimating];
    
    HttpJsonRequest *req = [HttpJsonRequest httpJsonRequestFor:self.session];
    NSURL *taskUrl = [NSURL URLWithString:@"/services/data/v21.0/sobjects/task" relativeToURL:[self.session instanceUrl]];
    NSData *json = [[c JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
    [req postAndGetJsonFromUrl:taskUrl contentType:@"application/json" body:json whenDone:^(NSUInteger httpStatusCode, NSObject *results, NSError *err) {
        [self.progress stopAnimating];
        NSLog(@"save checkin result is %d : %@", httpStatusCode, results);
        iToast *toast = nil;
        BOOL shouldDismiss = NO;
        if (httpStatusCode == 201) {
            toast = [iToast makeText:@"Checkin saved."];
            shouldDismiss = YES;
        } else {
            NSDictionary *err = [(NSArray *)results objectAtIndex:0];
            toast = [iToast makeText:[NSString stringWithFormat:@"Error saving check-in: %@", [err objectForKey:@"message"]]];
        }
        [[[toast setGravity:iToastGravityTop offsetLeft:0 offsetTop:200] setDuration:iToastDurationNormal] show];
        if (shouldDismiss)
            [self dismissModalViewControllerAnimated:YES];
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

@end
