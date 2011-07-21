//
//  NSDictionary+Path.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/25/11.
//

#import "NSDictionary+Path.h"


@implementation NSDictionary (NSDictionary_Path)

// maps values of NSNull back to nil.
-(id)mapNilObjectForKey:(id)key {
    id v = [self objectForKey:key];
    return v == [NSNull null] ? nil : v;
}

// key returns a dictionary, which we look for childKey in
-(id)mapNilObjectForKey:(id)key andChildKey:(id)childKey {
    id v = [self mapNilObjectForKey:key];
    return [v mapNilObjectForKey:childKey];
}

@end
