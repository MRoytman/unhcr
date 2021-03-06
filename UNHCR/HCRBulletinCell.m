//
//  HCRBulletinCell.m
//  UNHCR
//
//  Created by Sean Conrad on 10/30/13.
//  Copyright (c) 2013 Sean Conrad. All rights reserved.
//

#import "HCRBulletinCell.h"

////////////////////////////////////////////////////////////////////////////////

static const CGFloat kIndentGlobalCustom = 44.0;
static const CGFloat kIndentClusterImage = 12.0;

static const CGFloat kYOffset = 14.0;
static const CGFloat kXTrailing = 8.0;

static const CGFloat kFontSizeHeader = 20.0;
static const CGFloat kFontSizeDefault = 16.0;
static const CGFloat kFontSizeTime = 14.0;

static const CGFloat kButtonHeight = 35.0;

static const CGFloat kClusterImageHeight = 25.0;

static const CGFloat kYTimePadding = 8.0;
static const CGFloat kYButtonPadding = 8.0;

static const CGFloat kOneLineLabelHeight = 20.0;
static const CGFloat kTwoLineLabelHeight = 35.0;
static const CGFloat kThreeLineLabelHeight = 55.0;

static const CGFloat kHeaderHeight = 30.0;

////////////////////////////////////////////////////////////////////////////////

@interface HCRBulletinCell ()

@property (nonatomic, readonly) CGRect headerLabelFrame;
@property (nonatomic, readonly) CGRect clusterImageFrame;
@property (nonatomic, readonly) CGRect messageLabelFrame;
@property (nonatomic, readonly) CGRect nameLabelFrame;

@property UILabel *headerLabel;
@property UIImageView *clusterImage;
@property UILabel *messageLabel;
@property UILabel *nameLabel;

@property (nonatomic, readonly) CGRect replyButtonFrame;
@property (nonatomic, readonly) CGRect forwardButtonFrame;

@property (nonatomic, readwrite) UIButton *replyButton;
@property (nonatomic, readwrite) UIButton *forwardButton;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HCRBulletinCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.indentForContent = kIndentGlobalCustom;
        
        self.headerLabel = [UILabel new];
        [self.contentView addSubview:self.headerLabel];
        
        self.headerLabel.text = @"BULLETIN";
        self.headerLabel.textAlignment = NSTextAlignmentCenter;
        
        self.headerLabel.font = [UIFont boldSystemFontOfSize:kFontSizeHeader];
        self.headerLabel.textColor = [UIColor whiteColor];
        self.headerLabel.backgroundColor = [UIColor UNHCRBlue];
        
        self.replyButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.contentView addSubview:self.replyButton];
        
        [self.replyButton setTitle:@"Reply" forState:UIControlStateNormal];
        
        self.forwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.contentView addSubview:self.forwardButton];
        
        [self.forwardButton setTitle:@"Forward" forState:UIControlStateNormal];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.replyButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.forwardButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.headerLabel.frame = self.headerLabelFrame;
    
    self.clusterImage.frame = self.clusterImageFrame;
    self.messageLabel.frame = self.messageLabelFrame;
    self.nameLabel.frame = self.nameLabelFrame;
    
    self.replyButton.frame = self.replyButtonFrame;
    self.forwardButton.frame = self.forwardButtonFrame;
    
}

#pragma mark - Class Methods

+ (CGSize)sizeForCellInCollectionView:(UICollectionView *)collectionView withBulletinDictionary:(NSDictionary *)bulletinDictionary {
    
    NSString *messageString = [bulletinDictionary objectForKey:@"Message" ofClass:@"NSString"];
    
    CGSize boundingSize = CGSizeMake(CGRectGetWidth(collectionView.bounds) - kIndentGlobalCustom - kXTrailing,
                                     CGRectGetHeight(collectionView.bounds));
    
    CGSize messageSize = [messageString sizeforMultiLineStringWithBoundingSize:boundingSize
                                                    withFont:[HCRBulletinCell _preferredFontForMessageText]
                                                     rounded:YES];
    
    CGFloat height = kHeaderHeight + kYOffset + messageSize.height + kYTimePadding + kThreeLineLabelHeight + kYButtonPadding + kButtonHeight;
    
    return CGSizeMake(CGRectGetWidth(collectionView.bounds),
                      height);
    
}

+ (CGSize)preferredSizeForCollectionView:(UICollectionView *)collectionView {
    NSAssert(NO, @"Size of cell must be dynamic!");
    return CGSizeZero;
}

#pragma mark - Getters & Setters

- (CGRect)headerLabelFrame {
    
    return CGRectMake(0,
                      0,
                      CGRectGetWidth(self.contentView.bounds),
                      kHeaderHeight);
    
}

- (CGRect)clusterImageFrame {
    
    return CGRectMake(kIndentClusterImage,
                      kHeaderHeight + kYOffset,
                      CGRectGetWidth(self.clusterImage.bounds),
                      CGRectGetHeight(self.clusterImage.bounds));
    
}

- (CGRect)messageLabelFrame {
    
    CGFloat xOrigin = self.indentForContent;
    
    CGSize boundingSize = CGSizeMake(CGRectGetWidth(self.contentView.bounds) - xOrigin - kXTrailing,
                                     CGRectGetHeight(self.contentView.bounds));
    CGSize labelSize = [self.messageLabel.text sizeforMultiLineStringWithBoundingSize:boundingSize
                                                           withFont:[HCRBulletinCell _preferredFontForMessageText]
                                                            rounded:YES];
    
    return CGRectMake(xOrigin,
                      kHeaderHeight + kYOffset,
                      labelSize.width,
                      labelSize.height);
}

- (CGRect)nameLabelFrame {
    
    CGFloat xOrigin = self.indentForContent;
    
    return CGRectMake(xOrigin,
                      CGRectGetMaxY(self.messageLabel.frame) + kYTimePadding,
                      CGRectGetWidth(self.contentView.bounds) - xOrigin - kXTrailing,
                      kThreeLineLabelHeight);
}

- (CGRect)replyButtonFrame {
    return CGRectMake(0,
                      CGRectGetMaxY(self.nameLabel.frame) + kYButtonPadding,
                      0.5 * CGRectGetWidth(self.contentView.bounds),
                      kButtonHeight);
}

- (CGRect)forwardButtonFrame {
    return CGRectMake(0.5 * CGRectGetWidth(self.contentView.bounds),
                      CGRectGetMaxY(self.nameLabel.frame) + kYButtonPadding,
                      0.5 * CGRectGetWidth(self.contentView.bounds),
                      kButtonHeight);
}

- (void)setBulletinDictionary:(NSDictionary *)bulletinDictionary {
    _bulletinDictionary = bulletinDictionary;
    
    // CLUSTER IMAGE
    // must be re-created every use due to unique size requirements
    [self.clusterImage removeFromSuperview];
    self.clusterImage = nil;
    
    if (!self.clusterImage) {
        
        NSString *imageName = [bulletinDictionary objectForKey:@"Cluster" ofClass:@"NSString"];
        UIImage *image = [HCRDataSource imageForClusterName:imageName];
        
        image = [image resizeImageToSize:CGSizeMake(kClusterImageHeight, kClusterImageHeight)
                        withResizingMode:RMImageResizingModeFitWithin];
        
        image = [image colorImage:[UIColor UNHCRBlue]
                    withBlendMode:kCGBlendModeNormal
                 withTransparency:YES];
        
        self.clusterImage = [[UIImageView alloc] initWithImage:image];
        [self.contentView addSubview:self.clusterImage];
        
    }
    
    if (!self.messageLabel) {
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.messageLabel];
        
        self.messageLabel.font = [UIFont systemFontOfSize:kFontSizeDefault];
        self.messageLabel.textAlignment = NSTextAlignmentLeft;
        self.messageLabel.textColor = [UIColor darkTextColor];
        self.messageLabel.numberOfLines = 0;
        
    }
    
    if (!self.nameLabel) {
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.nameLabel];
        
        self.nameLabel.font = [UIFont systemFontOfSize:kFontSizeTime];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        self.nameLabel.textColor = [UIColor midGrayColor];
        self.nameLabel.numberOfLines = 3;
        
    }
    
//    self.timeLabel.text = [bulletinDictionary objectForKey:@"Time" ofClass:@"NSString"];
    self.messageLabel.text = [bulletinDictionary objectForKey:@"Message" ofClass:@"NSString"];
    
    NSDictionary *contactDictionary = [bulletinDictionary objectForKey:@"Contact" ofClass:@"NSDictionary"];
    NSString *nameString = [contactDictionary objectForKey:@"Name" ofClass:@"NSString"];
    NSString *emailString = [contactDictionary objectForKey:@"Email" ofClass:@"NSString"];
    NSString *timeString = [bulletinDictionary objectForKey:@"Time" ofClass:@"NSString"];
    self.nameLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@",
                           nameString,
                           emailString,
                           timeString];
    
    [self setNeedsLayout];
}

#pragma mark - Public Methods

- (NSString *)emailSenderString {
    
    NSDictionary *contactDictionary = [self.bulletinDictionary objectForKey:@"Contact" ofClass:@"NSDictionary"];
    return [[contactDictionary objectForKey:@"Email" ofClass:@"NSString"] stringByAppendingString:@".test"];
#warning ADDING .TEST TO EMAIL ADDRESS
}

- (NSString *)emailSubjectStringWithPrefix:(NSString *)prefix {
    
    NSString *message = [self.bulletinDictionary objectForKey:@"Message"];
    return [self _subjectStringFromMessage:message withPrefixString:prefix];
    
}

- (NSString *)emailBodyString {
    
    NSString *message = [self.bulletinDictionary objectForKey:@"Message"];
    
    NSDictionary *contactDictionary = [self.bulletinDictionary objectForKey:@"Contact" ofClass:@"NSDictionary"];
    NSString *senderName = [contactDictionary objectForKey:@"Name" ofClass:@"NSString"];
    return [self _bodyStringFromMessage:message withSender:senderName];
}

#pragma mark - Private Methods

+ (UIFont *)_preferredFontForMessageText {
    return [UIFont systemFontOfSize:kFontSizeDefault];
}

- (NSString *)_subjectStringFromMessage:(NSString *)message withPrefixString:(NSString *)prefix {
    
    NSString *subject = [message stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    subject = [NSString stringWithFormat:@"%@ %@",
               prefix,
               subject];
    
    static const NSInteger maxSubjectLength = 100;
    if (subject.length > maxSubjectLength) {
        subject = [subject stringByReplacingCharactersInRange:NSMakeRange(maxSubjectLength,
                                                                          subject.length - maxSubjectLength)
                                                   withString:@"..."];
    }
    
    return subject;
}

- (NSString *)_bodyStringFromMessage:(NSString *)message withSender:(NSString *)sender {
    
    NSString *body = [NSString stringWithFormat:@"\n\n\n\n\nOriginal Message by %@:\n\n%@",
                      sender,
                      message];
    
    return body;
    
}

@end
