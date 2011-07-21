//
//  HttpJsonRequest.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/24/11.
//

#import <Foundation/Foundation.h>
#import "UserSession.h"

@class UserSession;

// Helper wrapper around executing asyncrounous http requests, parsing json response.
// We use obj-c blocks as our completion callback mechanism.
// this uses the open source json framework for parsing json responses.
@interface HttpJsonRequest : NSObject {    
}

+(id)httpJsonRequestFor:(UserSession *)user;
-(id)initFor:(UserSession *)user;

@property (retain) UserSession *user;

// start an async GET request to this URL and parse the returned JSON payload. the callback block will be executed on the main thread once parsing has completed
// unless you call the 2nd version and pass NO for callbackOnMainThread
-(void)getJsonFromUrl:(NSURL *)url whenDone:(void (^)(NSUInteger httpStatusCode, NSObject * results, NSError *err)) doneBlock;
-(void)getJsonFromUrl:(NSURL *)url callbackOnMainThread:(BOOL)useMain whenDone:(void (^)(NSUInteger httpStatusCode, NSObject * results, NSError *err)) doneBlock;

// start an async POST request with this content-type and body, and parse the returned JSON payload, the whenDone block will run on the main thread when we're done.
-(void)postAndGetJsonFromUrl:(NSURL *)url contentType:(NSString *)ct body:(NSData *)body whenDone:(void (^)(NSUInteger httpStatusCode, NSObject * results, NSError *err)) doneBlock;


@end
