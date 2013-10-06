//
//  HCRLoginMenuScrollView.h
//  UNHCR
//
//  Created by Sean Conrad on 10/5/13.
//  Copyright (c) 2013 Sean Conrad. All rights reserved.
//

#import <UIKit/UIKit.h>

////////////////////////////////////////////////////////////////////////////////

typedef NS_ENUM(NSInteger, HCRHomeLoginMenuState) {
    HCRHomeLoginMenuStateNotSignedIn    = 1,
    HCRHomeLoginMenuStateSignedIn
};

////////////////////////////////////////////////////////////////////////////////

@interface HCRHomeLoginMenuScrollView : UIScrollView

@property (nonatomic) HCRHomeLoginMenuState loginState;

@property (nonatomic, readonly) UIButton *loginButton;
@property (nonatomic, readonly) UIButton *countriesButton;
@property (nonatomic, readonly) UIButton *campsButton;

@property (nonatomic, readonly) UIButton *signOutButton;
@property (nonatomic, readonly) UIButton *settingsButton;

@end
