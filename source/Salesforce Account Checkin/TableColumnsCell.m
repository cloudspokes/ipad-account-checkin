//
//  TableColumnsCell.m
//  Salesforce Account Checkin
//
//  Created by Simon Fell on 4/25/11.
//

#import "TableColumnsCell.h"

@implementation TableColumnsCell

@synthesize columnLabels=_columnLabels;

// crete the initial set of labels, one for each column, except for the first column, where we'll reuse the existing label.
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier columnSizes:(NSArray *)sizes {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSMutableArray *cols = [NSMutableArray array];
        [cols addObject:self.textLabel];
        for (NSUInteger i = 0; i < [sizes count] - 1; i++) {
            UILabel * l = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
            l.opaque = NO;
            l.backgroundColor = [UIColor clearColor];
            [cols addObject:l];
            [self.contentView addSubview:l];
        }
        self.columnLabels = cols;
        colSizes = [sizes retain];
    }
    return self;
}

static const CGFloat col_spacing = 3.0f;

// work out how much space is used by the fixed size columns, then share the remaining space
// between any variable sized columns.
-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect b = self.contentView.bounds;
    CGFloat xLeft = b.size.width - col_spacing - col_spacing - col_spacing;
    // first pass through, set the fixed widths
    int i = 0, stretchCount = 0;
    for (UILabel *label in self.columnLabels) {
        int s = [[colSizes objectAtIndex:i++] intValue];
        if (s == 0) {
            stretchCount++;
            continue;
        }
        CGRect f = label.frame;
        f.size.width = s;
        label.frame = f;
        xLeft -= (s + col_spacing);
    }
    // calculate what size we should made the stretchable columns
    CGFloat stretchSize = stretchCount > 0 ? xLeft / stretchCount : 0;

    // 2nd pass, set origin and also set width of stretchable columns.
    i = 0; 
    CGFloat xPos = col_spacing + col_spacing;
    for (UILabel *label in self.columnLabels) {
        int s = [[colSizes objectAtIndex:i++] intValue];
        CGRect f = label.frame;
        if (s == 0) f.size.width = stretchSize;
        f.origin.x = xPos;
        f.origin.y = col_spacing;
        f.size.height = b.size.height - col_spacing - col_spacing;
        xPos += f.size.width + col_spacing;
        label.frame = f;
    }
}

// set the text of a particular column to a value, includes some convience type converters
// returns the UILabel of the relevant column so that you can perform additional changes
// to the label without having to look it up in the array again.
-(UILabel *)setColumn:(NSUInteger)colIndex text:(id)txt {
    NSString *t = nil;
    if (txt == [NSNull null]) 
        t = @"";
    else if ([txt isKindOfClass:[NSDecimalNumber class]])
        t = [txt stringValue];
    else if ([txt isKindOfClass:[NSNumber class]])
        t = [txt stringValue];
    else 
        t = txt;
    UILabel *col = [self.columnLabels objectAtIndex:colIndex];
    [col setText:t];
    return col;
}

- (void)dealloc {
    [colSizes release];
    [_columnLabels release];
    [super dealloc];
}

@end
