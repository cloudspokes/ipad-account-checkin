//
//  DistanceUnit.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/27/11.
//

#import "DistanceUnit.h"


@implementation DistanceUnitKm

-(NSString *)displayShort {
    return @"Km";
}

-(NSString *)displayLong {
    return @"Kilometers";
}

-(CLLocationDistance)toMeters:(double)value {
    return value * 1000;
}

-(double)fromMeters:(CLLocationDistance)meters {
    return meters / 1000;
}

@end

@implementation DistanceUnitMile

static const double METERS_IN_ONE_MILE = 1609.344;

-(NSString *)displayShort {
    return @"m";
}

-(NSString *)displayLong {
    return @"Miles";
}

-(CLLocationDistance)toMeters:(double)value {
    return value * METERS_IN_ONE_MILE;
}

-(double)fromMeters:(CLLocationDistance)meters {
    return meters / METERS_IN_ONE_MILE;
}

@end

@implementation DistanceUnits

static NSArray *UNITS;

+(void)initialize {
    UNITS = [[NSArray arrayWithObjects:[[[DistanceUnitMile alloc] init] autorelease], 
                                       [[[DistanceUnitKm alloc] init] autorelease], 
                                       nil] retain];
}

+(NSArray *)units {
    return [[UNITS retain] autorelease];
}

+(NSObject<DistanceUnit> *)unitWithDisplayShort:(NSString *)s {
    for (NSObject<DistanceUnit> *u in UNITS) {
        if ([[u displayShort] isEqualToString:s])
            return [[u retain] autorelease];
    }
    return nil;
}

@end