//
//  TableColumnsCell.h
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/25/11.
//

#import <UIKit/UIKit.h>

// A table row cell that supports a number of "columns" each column can either be of a fixed size, or 0
// to indicate that it should consume the remaining space, if you have multiple columns with size 0 the 
// free space is divided between them.
// the columns are automatically recalculated as needed (e.g. on device rotation)
@interface TableColumnsCell : UITableViewCell {
    NSArray *colSizes;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier columnSizes:(NSArray *)sizes;

@property (retain) NSArray *columnLabels;

-(UILabel *)setColumn:(NSUInteger)colIndex text:(id)txt;

@end
