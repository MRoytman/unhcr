//
//  HCRCampClusterResourcesCell.h
//  UNHCR
//
//  Created by Sean Conrad on 10/4/13.
//  Copyright (c) 2013 Sean Conrad. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCRCampClusterResourcesCell : UICollectionViewCell

@property (nonatomic) BOOL showTallySheetsButton;

@property (nonatomic, readonly) UIButton *requestSuppliesButton;
@property (nonatomic, readonly) UIButton *sitRepsButton;
@property (nonatomic, readonly) UIButton *tallySheetsButton;

@end
