//
//  HttpJsonRequest.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/24/11.
//

#import "HttpJsonRequest.h"
#import "JSON.h"

typedef void (^JsonCompletionBlock)(NSUInteger httpStatusCode, NSObject *results, NSError *err);

// we'll create a new delegate object for each request, these collect up the response data
// parse it, and the run the completion block. This is the glue between NSURLRequest and
// HttpJsonRequest.
@interface JsonUrlConnectionDelegate : NSObject {
}
+(id)jsonUrlDelegateWithBlock:(JsonCompletionBlock)doneBlock mainThread:(BOOL)useMain;

@property (copy) JsonCompletionBlock completionBlock;
@property (retain) NSMutableData     *data;
@property (assign) BOOL              callbackOnMainThread;
@property (assign) NSUInteger        statusCode;
@end

@implementation JsonUrlConnectionDelegate

@synthesize completionBlock=_completionBlock, data=_data, callbackOnMainThread=_callbackOnMainThread, statusCode=_statusCode;

+(id)jsonUrlDelegateWithBlock:(JsonCompletionBlock) doneBlock mainThread:(BOOL)useMain {
    JsonUrlConnectionDelegate *d = [[JsonUrlConnectionDelegate alloc] init];
    d.completionBlock = doneBlock;
    d.callbackOnMainThread = useMain;
    return [d autorelease];
}

-(void)dealloc {
    [_completionBlock release];
    [_data release];
    [super dealloc];
}

// start collecting up the response data.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.statusCode = [(NSHTTPURLResponse *)response statusCode];
    self.data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
    [self.data appendData:d];
}

// we've gotten all the response data, parse the JSON data, and then run the completion block.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"didFinishLoading sc=%d bytes=%d", self.statusCode, self.data.length);
    SBJsonParser *p = [[[SBJsonParser alloc] init] autorelease];
    NSObject *result = [p objectWithData:self.data];
    self.data = nil;

    // which thread/queue do we want to run the completion block on.
    dispatch_queue_t queue = self.callbackOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // once we've called the block, we're all done, so we can release ourselves and cleanup.
    dispatch_async(queue, ^(void) {
        self.completionBlock(self.statusCode, result, nil);
        [self release];
    });
}

@end


@implementation HttpJsonRequest

@synthesize user=_user;

+(id)httpJsonRequestFor:(UserSession *)user {
    return [[[HttpJsonRequest alloc] initFor:user] autorelease];
}

-(id)initFor:(UserSession *)user {
    self = [super init];
    self.user = user;
    return self;
}

-(void)getJsonFromUrl:(NSURL *)url whenDone:(void (^)(NSUInteger httpStatusCode, NSObject * results, NSError *err)) doneBlock {
    [self getJsonFromUrl:url callbackOnMainThread:YES whenDone:doneBlock];
}

// builds an NSURLRequest, and a matching delegate instance, and then starts it off.
-(void)getJsonFromUrl:(NSURL *)url callbackOnMainThread:(BOOL)useMain whenDone:(void (^)(NSUInteger httpStatusCode, NSObject * results, NSError *err)) doneBlock{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req addValue:[NSString stringWithFormat:@"OAuth %@", [self.user accessToken]] forHTTPHeaderField:@"Authorization"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [NSURLConnection connectionWithRequest:req delegate:[[JsonUrlConnectionDelegate jsonUrlDelegateWithBlock:doneBlock mainThread:useMain] retain]];
}

// builds a NSURLRequest for a POST request, and a matching delegate instance, and then starts it off.
-(void)postAndGetJsonFromUrl:(NSURL *)url 
                 contentType:(NSString *)ct 
                        body:(NSData *)body 
                    whenDone:(void (^)(NSUInteger httpStatusCode, NSObject * results, NSError *err)) doneBlock {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:body];
    [req addValue:ct forHTTPHeaderField:@"Content-Type"];
    if ([[self.user accessToken] length] > 0)
        [req addValue:[NSString stringWithFormat:@"OAuth %@", [self.user accessToken]] forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection connectionWithRequest:req delegate:[[JsonUrlConnectionDelegate jsonUrlDelegateWithBlock:doneBlock mainThread:YES] retain]];
}

@end
