//
//  HCRTallySheetDetailViewController.m
//  UNHCR
//
//  Created by Sean Conrad on 10/6/13.
//  Copyright (c) 2013 Sean Conrad. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

#import "HCRTallySheetDetailViewController.h"
#import "HCRTableFlowLayout.h"
#import "HCRDataEntryCell.h"
#import "HCRTallySheetDetailInputViewController.h"
#import "HCRHeaderView.h"

////////////////////////////////////////////////////////////////////////////////

NSString *const kTallyDetailCellIdentifier = @"kTallyDetailCellIdentifier";
NSString *const kTallyDetailHeaderIdentifier = @"kTallyDetailHeaderIdentifier";

NSString *const kTallyReportingPeriod = @"Reporting Period";
NSString *const kTallyLocation = @"Location";
NSString *const kTallyOrganization = @"Organization";

////////////////////////////////////////////////////////////////////////////////

@interface HCRTallySheetDetailViewController ()

@property NSArray *tallyResources;
@property NSArray *tallyLayoutData;

@property UIView *agencyPickerBackground;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HCRTallySheetDetailViewController

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        
        // Custom initialization
        self.tallyLayoutData = @[
                                 kTallyReportingPeriod,
                                 kTallyLocation,
                                 kTallyOrganization
                                 ];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSParameterAssert(self.tallySheetData);
    
    self.highlightCells = YES;
    
    self.tallyResources = [self.tallySheetData objectForKey:@"Resources" ofClass:@"NSArray"];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(_cancelButtonPressed)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    
    UIBarButtonItem *submitButton = [[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(_submitButtonPressed)];
    [self.navigationItem setRightBarButtonItem:submitButton];
    
    HCRTableFlowLayout *tableLayout = (HCRTableFlowLayout *)self.collectionView.collectionViewLayout;
    NSParameterAssert([tableLayout isKindOfClass:[HCRTableFlowLayout class]]);
    tableLayout.minimumLineSpacing = 0;
    tableLayout.sectionInset = UIEdgeInsetsMake(15, 0, 0, 0);
    
    [tableLayout setDisplayHeader:YES withSize:[HCRHeaderView preferredHeaderSizeForCollectionView:self.collectionView]];
    
    [self.collectionView registerClass:[HCRDataEntryCell class]
            forCellWithReuseIdentifier:kTallyDetailCellIdentifier];
    
    [self.collectionView registerClass:[HCRHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:kTallyDetailHeaderIdentifier];
    
}

#pragma mark - Class Methods

+ (UICollectionViewLayout *)preferredLayout {
    return [[HCRTableFlowLayout alloc] init];
}

#pragma mark - UICollectionView Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.tallyResources.count;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    HCRDataEntryCell *dataCell = [collectionView dequeueReusableCellWithReuseIdentifier:kTallyDetailCellIdentifier
                                                                           forIndexPath:indexPath];
    
    NSDictionary *resourceDictionary = [self.tallyResources objectAtIndex:indexPath.row ofClass:@"NSDictionary"];
    
    NSMutableDictionary *mutableData = @{@"Title": [resourceDictionary objectForKey:@"Title" ofClass:@"NSString"],
                                         @"Input": @"enter"}.mutableCopy;
    
    NSString *subtitle = [resourceDictionary objectForKey:@"Subtitle" ofClass:@"NSString" mustExist:NO];
    if (subtitle) {
        [mutableData setObject:subtitle forKey:@"Subtitle"];
    }
    
    dataCell.cellStatus = HCRDataEntryCellStatusChildNotCompleted;
    dataCell.dataDictionary = [NSDictionary dictionaryWithDictionary:mutableData];
    
    [dataCell setBottomLineStatusForCollectionView:collectionView atIndexPath:indexPath];
    
    return dataCell;
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        NSString *title = [self.tallySheetData objectForKey:@"Name" ofClass:@"NSString"];
        
        HCRHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                   withReuseIdentifier:kTallyDetailHeaderIdentifier
                                                                          forIndexPath:indexPath];
        
        header.titleString = title;
        
        return header;
        
    }
    
    return nil;
    
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *questions = [self.tallySheetData objectForKey:@"Questions" ofClass:@"NSArray"];
    
    NSDictionary *resourceDictionary = [self.tallyResources objectAtIndex:indexPath.row ofClass:@"NSDictionary"];
    NSArray *exclusions = [resourceDictionary objectForKey:@"Exclusions" ofClass:@"NSArray" mustExist:NO];
    if (exclusions) {
        NSMutableArray *mutableQuestions = questions.mutableCopy;
        
        for (NSString *question in questions) {
            if ([exclusions containsObject:question]) {
                [mutableQuestions removeObject:question];
            }
        }
        
        questions = mutableQuestions;
        
    }
    
    HCRTallySheetDetailInputViewController *tallyInput = [[HCRTallySheetDetailInputViewController alloc] initWithCollectionViewLayout:[HCRTallySheetDetailInputViewController preferredLayout]];
    
    NSString *title = [resourceDictionary objectForKey:@"Title" ofClass:@"NSString"];
    NSString *subtitle = [resourceDictionary objectForKey:@"Subtitle" ofClass:@"NSString" mustExist:NO];
    NSString *headerString = (subtitle) ? [NSString stringWithFormat:@"%@ %@",title, subtitle] : title;
//    tallyInput.headerDictionary = @{@"Header": headerString,
//                                    @"Subheader": [NSString stringWithFormat:@"%@ > %@ @ %@",
//                                                   self.countryName,
//                                                   self.campName,
//                                                   [self _inputDateRangeString]]};
    
    tallyInput.questionsArray = questions;
    
    [self.navigationController pushViewController:tallyInput animated:YES];
    
}

#pragma mark - UICollectionView Delegate Flow Layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return [HCRTableFlowLayout preferredTableFlowCellSizeForCollectionView:collectionView numberOfLines:@1];
    } else {
        
        NSDictionary *resourceDictionary = [self.tallyResources objectAtIndex:indexPath.row ofClass:@"NSDictionary"];
        if ([resourceDictionary objectForKey:@"Subtitle" ofClass:@"NSString" mustExist:NO]) {
            return [HCRTableFlowLayout preferredTableFlowCellSizeForCollectionView:collectionView numberOfLines:@2];
        } else {
            NSNumber *numberOfLines = [resourceDictionary objectForKey:@"Lines" ofClass:@"NSNumber" mustExist:NO];
            return [HCRTableFlowLayout preferredTableFlowCellSizeForCollectionView:collectionView numberOfLines:numberOfLines];
        }
            
    }
    
}

#pragma mark - Private Methods

- (void)_agencyPickerBackgroundTapped {
    // dismiss
}

- (NSString *)_inputDateRangeString {
    
    NSTimeInterval secondsPerWeek = 60*60*24*7;
    NSDate *now = [NSDate new];
    NSDate *nextWeek = [now dateByAddingTimeInterval:secondsPerWeek];
    
    NSDateFormatter *formatter = [NSDateFormatter dateFormatterWithFormat:HCRDateFormatddMMM forceEuropeanFormat:YES];
    
    NSString *nowString = [formatter stringFromDate:now];
    NSString *nextWeekString = [formatter stringFromDate:nextWeek];
    NSString *inputString = [NSString stringWithFormat:@"%@ - %@",nowString,nextWeekString];
    return inputString;
    
}

- (void)_cancelButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_submitButtonPressed {
    
    self.collectionView.userInteractionEnabled = NO;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window]
                                              animated:YES];
    
    hud.labelText = @"Sending..";
    hud.mode = MBProgressHUDModeIndeterminate;
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [hud hide:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    
}

@end
