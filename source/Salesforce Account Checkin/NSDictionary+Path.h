//
//  NSDictionary+Path.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/25/11.
//

#import <Foundation/Foundation.h>

// Some helpers for NSDictionary that help converting NSNull back to nil. (the JSON framework maps json null to NSNull)
@interface NSDictionary (NSDictionary_Path)

-(id)mapNilObjectForKey:(id)key;   // maps values of NSNull back to nil.
-(id)mapNilObjectForKey:(id)key andChildKey:(id)childKey;   // key returns a dictionary, which we look for childKey in

@end
