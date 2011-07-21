//
//  AccountTableCell.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/24/11.
//

#import <UIKit/UIKit.h>
#import "DistanceUnit.h"

// Container with information about a particular account, include both information from salesforce
// and local distance information.
@interface AccountInfo : NSObject <MKAnnotation> {
}

+(id)accountInfo:(NSDictionary *)sobject withDistanceFrom:(CLLocation *)startPoint;

@property (readonly) CLLocationDistance distance;

@property (readonly) NSDictionary *sobject;
@property (readonly) NSString *name;
@property (readonly) NSString *address;
@property (readonly) NSString *recordId;

-(NSString *)formattedDistanceInUnits:(NSObject<DistanceUnit> *)units;

@end

