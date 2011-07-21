//
//  DistanceUnit.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/27/11.
//

#import <Foundation/Foundation.h>

// a protocol/interface for dealing with a type of distance unit or measurement.
// the app code deals in either measures in a specific DistanceUnit or in
// CLLocationDistance (which is meters)
@protocol DistanceUnit <NSObject>

-(NSString *)displayShort;
-(NSString *)displayLong;

-(CLLocationDistance)toMeters:(double)value;
-(double)fromMeters:(CLLocationDistance)meters;

@end

// distances in kilometers.
@interface DistanceUnitKm : NSObject <DistanceUnit> {
}
@end

// distances in miles.
@interface DistanceUnitMile : NSObject <DistanceUnit> {
}
@end

// the collection of distance types we know about.
@interface DistanceUnits : NSObject {
}

+(NSArray *)units;
+(NSObject<DistanceUnit> *)unitWithDisplayShort:(NSString *)s;

@end