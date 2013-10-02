//
//  HCRCountryCollectionCell.m
//  UNHCR
//
//  Created by Sean Conrad on 9/30/13.
//  Copyright (c) 2013 Sean Conrad. All rights reserved.
//

#import "HCRCountryCollectionCell.h"

////////////////////////////////////////////////////////////////////////////////

@interface HCRCountryCollectionCell ()

@property UILabel *countryNameLabel;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HCRCountryCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)prepareForReuse {
    self.countryDictionary = nil;
    
    [self.countryNameLabel removeFromSuperview];
    self.countryNameLabel = nil;
}

#pragma mark - Getters & Setters

- (void)setCountryDictionary:(NSDictionary *)countryDictionary {
    
    _countryDictionary = countryDictionary;
    
    if ( countryDictionary == nil ) {
        return;
    }
    
    if ( !self.countryNameLabel && countryDictionary ) {
        
        CGFloat xPadding = 8;
        CGRect countryLabelFrame = CGRectMake(xPadding,
                                              0,
                                              CGRectGetWidth(self.bounds) - 2 * xPadding,
                                              CGRectGetHeight(self.bounds));
        
        self.countryNameLabel = [[UILabel alloc] initWithFrame:countryLabelFrame];
        [self addSubview:self.countryNameLabel];
        
    }
    
    NSString *countryName = [countryDictionary objectForKey:@"Name"];
    NSParameterAssert([countryName isKindOfClass:[NSString class]]);
    
    NSDictionary *titleAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18]};
    NSMutableAttributedString *countryLabelString = [[NSMutableAttributedString alloc] initWithString:countryName
                                                                                           attributes:titleAttributes];
    
    NSDictionary *subtitleAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:15],
                                         NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    NSNumber *persons = [countryDictionary objectForKey:@"Persons"];
    if (persons) {
        
        self.countryNameLabel.numberOfLines = 2;
        
        // format number
        NSNumberFormatter *commaFormatter = [[NSNumberFormatter alloc] init];
        commaFormatter.usesGroupingSeparator = YES;
        commaFormatter.groupingSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator];
        commaFormatter.groupingSize = 3;
        
        NSString *personString = [NSString stringWithFormat:@"\n%@ displaced persons",
                                  [commaFormatter stringFromNumber:persons]];
        
        NSAttributedString *personAttributedString = [[NSAttributedString alloc] initWithString:personString
                                                                                     attributes:subtitleAttributes];
        [countryLabelString appendAttributedString:personAttributedString];
        
    }
    
//    NSNumber *funding = [countryDictionary objectForKey:@"Funding"];
//    if (funding) {
//        
//        self.countryNameLabel.numberOfLines = 2;
//        
//        // format number
//        NSNumberFormatter *percentFormatter = [[NSNumberFormatter alloc] init];
//        percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
//        
//        NSString *personString = [NSString stringWithFormat:@" - %@ funding coverage",
//                                  [percentFormatter stringFromNumber:funding]];
//        
//        NSAttributedString *personAttributedString = [[NSAttributedString alloc] initWithString:personString
//                                                                                     attributes:subtitleAttributes];
//        [countryLabelString appendAttributedString:personAttributedString];
//    }
    
    self.countryNameLabel.attributedText = countryLabelString;
    
}

@end
