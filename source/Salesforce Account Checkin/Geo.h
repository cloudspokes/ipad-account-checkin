//
//  Geo.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/24/11.
//

#import <Foundation/Foundation.h>
#import "DistanceUnit.h"

// This holds onto common Geo related config
//      which field names to query for long/lat/address)
//      what distance units the user wants to use.
@interface Geo : NSObject {
    NSString *longFieldName, *latFieldName, *addressFieldName;
}

+(Geo *)geoConfig;

// builds a where clause filter for the box defined by center + distanceInKilometers (as a radius)
-(NSString *)buildFilter:(double)distanceInKilometers center:(CLLocationCoordinate2D)center;
-(NSString *)buildFilter:(double)distanceInKilometers centerLong:(CLLocationDegrees)centerLong centerLat:(CLLocationDegrees)centerLat;

@property (readonly) NSString *longitudeFieldName;
@property (readonly) NSString *latitudeFieldName;
@property (readonly) NSString *addressFieldName;

@property (retain) NSObject<DistanceUnit> *distanceUnit;

@end
