//
//  HCRCampClusterDetailViewController.m
//  UNHCR
//
//  Created by Sean Conrad on 10/2/13.
//  Copyright (c) 2013 Sean Conrad. All rights reserved.
//

#import "HCRCampClusterDetailViewController.h"
#import "HCRTableFlowLayout.h"
#import "HCRGraphCell.h"
#import "HCRButtonListCell.h"
#import "HCRTallySheetPickerViewController.h"
#import "EAEmailUtilities.h"
#import "HCRAlertCell.h"

////////////////////////////////////////////////////////////////////////////////

NSString *const kCampClusterHeaderIdentifier = @"kCampClusterHeaderIdentifier";
NSString *const kCampClusterFooterIdentifier = @"kCampClusterFooterIdentifier";

NSString *const kCampClusterAlertCellIdentifier = @"kCampClusterAlertCellIdentifier";
NSString *const kCampClusterGraphCellIdentifier = @"kCampClusterGraphCellIdentifier";
NSString *const kCampClusterResourcesCellIdentifier = @"kCampClusterResourcesCellIdentifier";
NSString *const kCampClusterAgenciesCellIdentifier = @"kCampClusterAgenciesCellIdentifier";

NSString *const kResourceNameSupplies = @"Request Supplies";
NSString *const kResourceNameSitReps = @"Situation Reports";
NSString *const kResourceNameTallySheets = @"Tally Sheets";

////////////////////////////////////////////////////////////////////////////////

@interface HCRCampClusterDetailViewController ()

@property NSMutableArray *localAlerts;
@property NSDictionary *campClusterData;
@property NSMutableArray *campClusterCollectionLayoutData;

@property (nonatomic, readonly) BOOL clusterContainsTallySheets;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HCRCampClusterDetailViewController

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        // Custom initialization
        
        self.localAlerts = @[].mutableCopy;
        
        self.campClusterCollectionLayoutData = @[
                                      @{@"Section": @"Refugee Requests",
                                        @"Cell": kCampClusterGraphCellIdentifier},
                                      @{@"Section": @"Resources",
                                        @"Cell": kCampClusterResourcesCellIdentifier,
                                        @"Resources": @[
                                                kResourceNameSupplies,
                                                kResourceNameSitReps,
                                                kResourceNameTallySheets
                                                ]},
                                      @{@"Section": @"Local Agencies",
                                        @"Cell": kCampClusterAgenciesCellIdentifier}
                                      ].mutableCopy;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSParameterAssert(self.selectedClusterMetaData);
    NSParameterAssert(self.campDictionary);
    
    // finish data source
    NSString *selectedCluster = [self.selectedClusterMetaData objectForKey:@"Name"];
    if ([HCRDataSource globalAlertsData].count > 0) {
        
        for (NSDictionary *alertsDictionary in [HCRDataSource globalAlertsData]) {
            
            NSString *alertCluster = [alertsDictionary objectForKey:@"Cluster" ofClass:@"NSString"];
            if ([alertCluster isEqualToString:selectedCluster]) {
                
                [self.localAlerts addObject:alertsDictionary];
                
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    [self.campClusterCollectionLayoutData insertObject:@{@"Section": @"Alerts",
                                                                         @"Cell": kCampClusterAlertCellIdentifier}
                                                               atIndex:0];
                });
                
            }
            
            
        }
        
    }
    [self.collectionView reloadData];
    
    self.campClusterData = [[self.campDictionary objectForKey:@"Clusters" ofClass:@"NSDictionary"] objectForKey:selectedCluster ofClass:@"NSDictionary"];
    
    self.title = selectedCluster;
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.925];
    
    HCRFlowLayout *flowLayout = (HCRFlowLayout *)self.collectionView.collectionViewLayout;
    NSParameterAssert([flowLayout isKindOfClass:[HCRFlowLayout class]]);
    [flowLayout setDisplayHeader:YES withSize:[HCRFlowLayout preferredHeaderSizeForCollectionView:self.collectionView]];
    
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:kCampClusterHeaderIdentifier];
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:kCampClusterFooterIdentifier];
    
    [self.collectionView registerClass:[HCRGraphCell class]
            forCellWithReuseIdentifier:kCampClusterGraphCellIdentifier];
    [self.collectionView registerClass:[HCRButtonListCell class]
            forCellWithReuseIdentifier:kCampClusterResourcesCellIdentifier];
    [self.collectionView registerClass:[HCRButtonListCell class]
            forCellWithReuseIdentifier:kCampClusterAgenciesCellIdentifier];
    [self.collectionView registerClass:[HCRAlertCell class]
            forCellWithReuseIdentifier:kCampClusterAlertCellIdentifier];
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    UIView *background = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:background];
    [self.view sendSubviewToBack:background];
    
    UIImage *clusterImage = [[UIImage imageNamed:[self.selectedClusterMetaData objectForKey:@"Image"]] colorImage:[UIColor lightGrayColor]
                                                                                                    withBlendMode:kCGBlendModeNormal
                                                                                                 withTransparency:YES];
    background.backgroundColor = [UIColor colorWithPatternImage:clusterImage];
    
}

#pragma mark - Class Methods

+ (UICollectionViewLayout *)preferredLayout {
    return [[HCRTableFlowLayout alloc] init];
}

#pragma mark - UICollectionView Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.campClusterCollectionLayoutData.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    NSDictionary *sectionData = [self.campClusterCollectionLayoutData objectAtIndex:section ofClass:@"NSDictionary"];
    NSString *cellType = [sectionData objectForKey:@"Cell" ofClass:@"NSString"];
    
    if ([cellType isEqualToString:kCampClusterResourcesCellIdentifier]) {
        
        return (self.clusterContainsTallySheets) ? 3 : 2;
        
    } else if ([cellType isEqualToString:kCampClusterAgenciesCellIdentifier]) {
        
        NSArray *agencyArray = [self.campClusterData objectForKey:@"Agencies" ofClass:@"NSArray"];
        return agencyArray.count;
        
    } else if ([cellType isEqualToString:kCampClusterAlertCellIdentifier]) {
        
        return self.localAlerts.count;
        
    } else {
    
        return 1;
        
    }
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellType = [self _cellTypeForSection:indexPath.section];
    
    if ([cellType isEqualToString:kCampClusterGraphCellIdentifier]) {
        HCRGraphCell *graphCell = [collectionView dequeueReusableCellWithReuseIdentifier:kCampClusterGraphCellIdentifier forIndexPath:indexPath];
        
        // TODO: make this real
        
        return graphCell;
    } else if ([cellType isEqualToString:kCampClusterResourcesCellIdentifier]) {
        
        HCRButtonListCell *resourcesCell = [collectionView dequeueReusableCellWithReuseIdentifier:kCampClusterResourcesCellIdentifier forIndexPath:indexPath];
        
        NSDictionary *campClusterLayoutDictionary = [self.campClusterCollectionLayoutData objectAtIndex:indexPath.section ofClass:@"NSDictionary"];
        NSArray *resourcesArray = [campClusterLayoutDictionary objectForKey:@"Resources" ofClass:@"NSArray"];
        resourcesCell.listButtonTitle = [resourcesArray objectAtIndex:indexPath.row ofClass:@"NSString"];
        
        return resourcesCell;
        
    } else if ([cellType isEqualToString:kCampClusterAgenciesCellIdentifier]) {
        HCRButtonListCell *agencyCell = [collectionView dequeueReusableCellWithReuseIdentifier:kCampClusterAgenciesCellIdentifier forIndexPath:indexPath];
        
        NSArray *agencyArray = [self.campClusterData objectForKey:@"Agencies" ofClass:@"NSArray"];
        NSDictionary *agencyDictionary = [agencyArray objectAtIndex:indexPath.row ofClass:@"NSDictionary"];
        agencyCell.listButtonTitle = [agencyDictionary objectForKey:@"Abbr" ofClass:@"NSString"];
        
        return agencyCell;
    } else if ([cellType isEqualToString:kCampClusterAlertCellIdentifier]) {
        HCRAlertCell *alertCell = [collectionView dequeueReusableCellWithReuseIdentifier:kCampClusterAlertCellIdentifier forIndexPath:indexPath];
        
        alertCell.showLocation = NO;
        alertCell.alertDictionary = [self.localAlerts objectAtIndex:indexPath.row ofClass:@"NSDictionary"];
        
        return alertCell;
    }
    
    return nil;
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        NSDictionary *sectionData = [self.campClusterCollectionLayoutData objectAtIndex:indexPath.section ofClass:@"NSDictionary"];
        NSString *titleString = [sectionData objectForKey:@"Section" ofClass:@"NSString"];
        
        UICollectionReusableView *header = [UICollectionReusableView headerForUNHCRCollectionView:collectionView
                                                                                       identifier:kCampClusterHeaderIdentifier
                                                                                        indexPath:indexPath
                                                                                            title:titleString];
        
        // check if it's alerts
        NSDictionary *layoutObject = [self.campClusterCollectionLayoutData objectAtIndex:indexPath.section ofClass:@"NSDictionary"];
        NSString *sectionTitle = [layoutObject objectForKey:@"Section" ofClass:@"NSString"];
        if ([sectionTitle isEqualToString:@"Alerts"]) {
            header.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
        }
        
        return header;
        
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        
        UICollectionReusableView *footer = [UICollectionReusableView footerForUNHCRGraphCellWithCollectionCollection:collectionView
                                                                                                          identifier:kCampClusterFooterIdentifier
                                                                                                           indexPath:indexPath];
        
        UIButton *footerButton = [UIButton footerButtonForUNHCRGraphCellInFooter:footer title:@"Raw Data"];
        [footer addSubview:footerButton];
        
        [footerButton addTarget:self
                         action:@selector(_footerButtonPressed)
               forControlEvents:UIControlEventTouchUpInside];
        
        return footer;
        
    }
    
    return nil;
    
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    HCRButtonListCell *cell = (HCRButtonListCell *)[collectionView cellForItemAtIndexPath:indexPath];
    NSParameterAssert([cell isKindOfClass:[HCRButtonListCell class]]);
    
    NSString *cellType = [self _cellTypeForSection:indexPath.section];
    
    if ([cellType isEqualToString:kCampClusterGraphCellIdentifier]) {
        
        // do nothing
        
    } else if ([cellType isEqualToString:kCampClusterResourcesCellIdentifier]) {
        
        if ([cell.listButtonTitle isEqualToString:kResourceNameSupplies]) {
            [self _requestSuppliesButtonPressed];
        } else if ([cell.listButtonTitle isEqualToString:kResourceNameSitReps]) {
            [self _sitRepsButtonPressed];
        } else if ([cell.listButtonTitle isEqualToString:kResourceNameTallySheets]) {
            [self _tallySheetsButtonPressed];
        }
        
    } else if ([cellType isEqualToString:kCampClusterAgenciesCellIdentifier]) {
        
        //
        
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    HCRButtonListCell *cell = (HCRButtonListCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[HCRButtonListCell class]]) {
        [cell.listButton setHighlighted:YES];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    HCRButtonListCell *cell = (HCRButtonListCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[HCRButtonListCell class]]) {
        [cell.listButton setHighlighted:NO];
    }
    
}

#pragma mark - UICollectionView Delegate Flow Layout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    NSString *cellType = [self _cellTypeForSection:section];
    
    if ([cellType isEqualToString:kCampClusterGraphCellIdentifier]) {
        
        return UIEdgeInsetsZero;
        
    } else {
        
        return UIEdgeInsetsMake(kYListOffset, 0, kYListOffset, 0);
        
    }
    
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [HCRButtonListCell preferredButtonPadding];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellType = [self _cellTypeForSection:indexPath.section];
    
    if ([cellType isEqualToString:kCampClusterGraphCellIdentifier]) {
        return CGSizeMake(CGRectGetWidth(collectionView.bounds),
                          [HCRGraphCell preferredHeightForGraphCell]);
    } else if ([cellType isEqualToString:kCampClusterAlertCellIdentifier]) {
        
        return CGSizeMake(CGRectGetWidth(collectionView.bounds),
                          [HCRAlertCell preferredCellHeightWithoutLocation]);
        
    } else {
        
        return CGSizeMake(CGRectGetWidth(collectionView.bounds),
                          [HCRButtonListCell preferredCellHeight]);
        
    }
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    
    NSDictionary *layoutObject = [self.campClusterCollectionLayoutData objectAtIndex:section ofClass:@"NSDictionary"];
    NSString *sectionTitle = [layoutObject objectForKey:@"Section" ofClass:@"NSString"];
    if ([sectionTitle isEqualToString:@"Refugee Requests"]) {
        return [HCRFlowLayout preferredFooterSizeForGraphCellInCollectionView:collectionView];
    } else {
        return CGSizeZero;
    }
    
}

#pragma mark - Getters & Setters

- (BOOL)clusterContainsTallySheets {
    return ([self.campClusterData objectForKey:@"TallySheets" ofClass:@"NSArray" mustExist:NO] != nil);
}

#pragma mark - Private Methods

- (NSString *)_cellTypeForSection:(NSInteger)section {
    
    NSDictionary *sectionData = [self.campClusterCollectionLayoutData objectAtIndex:section ofClass:@"NSDictionary"];
    return [sectionData objectForKey:@"Cell" ofClass:@"NSString"];
    
}

- (void)_requestSuppliesButtonPressed {
    
    NSString *clusterName = [self.selectedClusterMetaData objectForKey:@"Name"];
    NSString *toString = [NSString stringWithFormat:@"%@@unhcr.org", [[clusterName stringByReplacingOccurrencesOfString:@" " withString:@"."] lowercaseString]];
    NSString *subjectString = [NSString stringWithFormat:@"%@ Supply Request", clusterName];
    
    [[EAEmailUtilities sharedUtilities] emailFromViewController:self
                                               withToRecipients:@[toString]
                                                withSubjectText:subjectString
                                                   withBodyText:nil
                                                 withCompletion:nil];
    
}

- (void)_sitRepsButtonPressed {
    
    NSString *sitRepString = [self.campClusterData objectForKey:@"SitReps" ofClass:@"NSString" mustExist:NO];
    
    NSURL *targetURL = [NSURL URLWithString:(sitRepString) ? sitRepString : [self.campDictionary objectForKey:@"SitReps" ofClass:@"NSString"]];
    
    [[UIApplication sharedApplication] openURL:targetURL];
    
}

- (void)_tallySheetsButtonPressed {
    
    HCRTallySheetPickerViewController *healthTallySheet = [[HCRTallySheetPickerViewController alloc] initWithCollectionViewLayout:[HCRTallySheetPickerViewController preferredLayout]];
    
    healthTallySheet.title = kResourceNameTallySheets;
    healthTallySheet.countryName = self.countryName;
    healthTallySheet.campData = self.campDictionary;
    healthTallySheet.campClusterData = self.campClusterData;
    healthTallySheet.selectedClusterMetaData = self.selectedClusterMetaData;
    
    [self.navigationController pushViewController:healthTallySheet animated:YES];
    
}

- (void)_footerButtonPressed {
    // TODO: footer button!
}

@end
