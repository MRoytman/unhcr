//
//  HCRSurveyQuestionHeader.m
//  UNHCR
//
//  Created by Sean Conrad on 1/6/14.
//  Copyright (c) 2014 Sean Conrad. All rights reserved.
//

#import "HCRSurveyQuestionHeader.h"

@implementation HCRSurveyQuestionHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

#pragma mark - Class Methods

//+ (CGSize)sizeForCellInCollectionView:(UICollectionView *)collectionView withQuestionData:(NSDictionary *)questionData {
//    
//    CGFloat height;
//    
//    // vars we need
//    NSArray *stringArray = [HCREmergencyCell _arrayOfStringsForValueLabelsWithEmergencyDictionary:emergencyDictionary];
//    CGSize finalBounding = [HCREmergencyCell _boundingSizeForValueLabelInViewWithWidth:boundingSize.width];
//    
//    // start with padding
//    NSInteger amountOfPadding = (stringArray.count - 1) * kYLabelPadding;
//    height = kEmergencyBannerHeight + kEmergencyBannerHeight + kYLabelOffset + amountOfPadding + kYLabelTrailing;
//    
//    // then add size of objects
//    for (NSString *string in stringArray) {
//        
//        CGSize stringSize = [string sizeforMultiLineStringWithBoundingSize:finalBounding
//                                                                  withFont:[HCREmergencyCell _preferredFontForLabelBold:YES]
//                                                                   rounded:YES];
//        
//        height += stringSize.height;
//        
//    }
//    
//    return CGSizeMake(boundingSize.width,
//                      height);
//    
//}

@end
