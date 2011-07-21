//
//  UserSession.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/23/11.
//

#import <Foundation/Foundation.h>


// This holds the users authentication/session info, includes the ability to get a new sessionId from the refresh token.
@interface UserSession : NSObject {
}

+(id)persistedUserSession;
+(void)removedPersistedUserSession;

@property (retain) NSString *refreshToken;
@property (retain) NSString *accessToken;
@property (retain) NSString *loginHost;
@property (retain) NSString *instanceHost;

@property (readonly) NSURL *instanceUrl;

-(void)persist;

-(void)refreshWithClientId:(NSString *)oAuthClientId whenDone:(void (^)(NSError *error)) doneBlock;

@end
