//
//  Geo.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/24/11.
//

#import "Geo.h"

@interface Geo()
-(id)initWithLongFieldName:(NSString *)longFn latFieldName:(NSString *)latFn addressFieldName:(NSString *)addr;
@end

@implementation Geo

static Geo *instance;

+(void)initialize {
    // change this if you want to work with different field names.
    instance = [[Geo alloc] initWithLongFieldName:@"Longitude__c" latFieldName:@"Latitude__c" addressFieldName:@"BillingAddress__c"];
}

+(Geo *)geoConfig {
    return instance;
}


// client side calculation helpers based on the GeocodeService apex class from Richard Vanhook geocoding toolkit.
static const double M_IN_ONE_LATITUDE_DEGREE = 111000.132;
static const double MEAN_EARTH_RADIUS_KM = 6371;

@synthesize longitudeFieldName=longFieldName, latitudeFieldName=latFieldName, addressFieldName;
@synthesize distanceUnit=_distanceUnit;

-(id)initWithLongFieldName:(NSString *)longFn latFieldName:(NSString *)latFn addressFieldName:(NSString *)addr {
    self = [super init];
    longFieldName = [longFn retain];
    latFieldName = [latFn retain];
    addressFieldName = [addr retain];
    return self;
}

-(void)dealloc {
    [longFieldName release];
    [latFieldName release];
    [addressFieldName release];
    [_distanceUnit release];
    [super dealloc];
}

double cap(double v, double cap) {
    return (v < -cap || v > cap) ? cap : v;
}

-(NSString *)buildFilter:(double)distanceInUnits center:(CLLocationCoordinate2D)center {
    return [self buildFilter:distanceInUnits centerLong:center.longitude centerLat:center.latitude];
}

-(NSString *)buildFilter:(double)distanceInUnits centerLong:(CLLocationDegrees)centerLong centerLat:(CLLocationDegrees)centerLat {
    double distLat = [self.distanceUnit toMeters:distanceInUnits] / M_IN_ONE_LATITUDE_DEGREE;
    double distLng = distLat / cos(centerLat * M_PI / 180);
    
    double neLat = centerLat + distLat;
    double neLng = centerLong + distLng;
    double swLat = centerLat - distLat;
    double swLng = centerLong - distLng;
    neLat = cap(neLat, 90);
    neLng = cap(neLng, 180);
    swLat = cap(swLat, 90);
    swLng = cap(swLng, 180);
    
    return [NSString stringWithFormat:@"(%@ >= %f and %@ <= %f and %@ >= %f and %@ <= %f)",
            longFieldName, swLng,
            longFieldName, neLng,
            latFieldName,  swLat,
            latFieldName,  neLat];
}

@end
