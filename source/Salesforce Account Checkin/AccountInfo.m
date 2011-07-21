//
//  AccountTableCell.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/24/11.
//

#import "AccountInfo.h"
#import "DistanceUnit.h"
#import "Geo.h"

@implementation AccountInfo

@synthesize sobject=_sobject, distance=_distance, coordinate=_coordinate;

-(id)initWithSObject:(NSDictionary *)so withDistanceFrom:(CLLocation *)startPoint {
    self = [super init];
    _sobject = [so retain];

    CLLocationDegrees rowLatitude = [[so objectForKey:[[Geo geoConfig] latitudeFieldName]] doubleValue];
    CLLocationDegrees rowLongitude = [[so objectForKey:[[Geo geoConfig] longitudeFieldName]] doubleValue];
    _coordinate = CLLocationCoordinate2DMake(rowLatitude, rowLongitude);
    
    CLLocation *rowLoc = [[[CLLocation alloc] initWithLatitude:rowLatitude longitude:rowLongitude] autorelease];
    _distance = [rowLoc distanceFromLocation:startPoint];

    return self;
}

-(void)dealloc {
    [_sobject release];
    [super dealloc];
}

+(id)accountInfo:(NSDictionary *)sobject withDistanceFrom:(CLLocation *)startPoint {
    return [[[AccountInfo alloc] initWithSObject:sobject withDistanceFrom:startPoint] autorelease];
}

// convience accessors.

-(NSString *)name {
    return [self.sobject objectForKey:@"Name"];
}

-(NSString *)address {
    return [self.sobject objectForKey:[[Geo geoConfig] addressFieldName]];
}

-(NSString *)recordId {
    return [self.sobject objectForKey:@"Id"];
}

-(NSString *)formattedDistanceInUnits:(NSObject<DistanceUnit> *)units {
    return [NSString stringWithFormat:@"%0.2f %@", [units fromMeters:self.distance], [units displayShort]];
}

-(NSString *)title {
    return self.name;
}

@end
