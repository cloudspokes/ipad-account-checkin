//
//  UserSession.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/23/11.
//

#import "UserSession.h"
#import "HttpJsonRequest.h"
#import "SFHFKeychainUtils.h"

@implementation UserSession
    
@synthesize refreshToken=_refreshToken, accessToken=_accessToken, loginHost=_loginHost, instanceHost=_instanceHost;

static NSString *SVC_NAME = @"com.pocketsoap.cloudspokes.accountcheckin";
static NSString *HOST = @"login_host";
static NSString *TOKEN = @"refresh_token";

+(void)removedPersistedUserSession {
    NSError *error = nil;
    UserSession *s = [UserSession persistedUserSession];
    if (s != nil) {
        [SFHFKeychainUtils deleteItemForUsername:HOST  andServiceName:SVC_NAME error:&error];
        [SFHFKeychainUtils deleteItemForUsername:TOKEN andServiceName:SVC_NAME error:&error];
    }
}

+(id)persistedUserSession {
    NSError *error = nil;
    NSString *auth = [SFHFKeychainUtils getPasswordForUsername:HOST andServiceName:SVC_NAME error:&error];
    NSString *tkn  = [SFHFKeychainUtils getPasswordForUsername:TOKEN andServiceName:SVC_NAME error:&error];
    if (tkn == nil || auth == nil) return nil;
    
    UserSession *s = [[[UserSession alloc] init] autorelease];
    s.refreshToken = tkn;
    s.loginHost = auth;
    return s;
}

-(void)dealloc {
    [_refreshToken release];
    [_accessToken release];
    [_loginHost release];
    [_instanceHost release];
    [super dealloc];
}

-(NSURL *)instanceUrl {
    return [NSURL URLWithString:self.instanceHost];
}

-(void)persist {
    NSError *error = nil;
    [SFHFKeychainUtils storeUsername:TOKEN
                         andPassword:self.refreshToken 
                      forServiceName:SVC_NAME
                      updateExisting:YES 
                               error:&error];
    [SFHFKeychainUtils storeUsername:HOST
                         andPassword:self.loginHost
                      forServiceName:SVC_NAME
                      updateExisting:YES 
                               error:&error];
}

// make a HTTP POST request to the token endpoint to get a new sessionId from our saved refresh token.
-(void)refreshWithClientId:(NSString *)clientId whenDone:(void (^)(NSError *error)) doneBlock {
    
    NSURL *tokenUrl = [NSURL URLWithString:@"/services/oauth2/token" relativeToURL:[NSURL URLWithString:self.loginHost]];
    NSString *params = [NSString stringWithFormat:@"grant_type=refresh_token&refresh_token=%@&client_id=%@&format=json",
                        [self.refreshToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], 
                        [clientId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    HttpJsonRequest *req = [[[HttpJsonRequest alloc] initFor:self] autorelease];
    [req postAndGetJsonFromUrl:tokenUrl 
                   contentType:@"application/x-www-form-urlencoded; charset=UTF-8" 
                          body:[params dataUsingEncoding:NSUTF8StringEncoding]
                      whenDone:^(NSUInteger httpStatusCode, NSObject *results, NSError *err) {

                          NSString *newSid = [(NSDictionary *)results objectForKey:@"access_token"];
                          NSString *newInst= [(NSDictionary *)results objectForKey:@"instance_url"];
                          if (newSid != nil) {
                              self.accessToken = newSid;
                              self.instanceHost = newInst;
                          }
                          doneBlock(err);
                      }];
}

@end
