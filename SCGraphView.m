//
//  SCGraphView.m
//  UNHCR
//
//  Created by Sean Conrad on 10/22/13.
//  Copyright (c) 2013 Sean Conrad. All rights reserved.
//

#import "SCGraphView.h"
#import "EASoundManager.h"

////////////////////////////////////////////////////////////////////////////////

NSString *SCGraphTipDateKey = @"SCGraphTipDateKey";
NSString *SCGraphTipValueKey = @"SCGraphTipValueKey";

static const CGFloat kDataLineWidth = 1.0;

static const CGFloat kDataDotWidth = 4.0;
static const CGFloat kDataDotWidthHighlighted = 8.0;

static const CGFloat kGraphDataPointHighlightFontSize = 14.0;
static const CGFloat kGraphDataPointHighlightLabelHeight = 25.0;

static const CGFloat kGraphDateLabelHeight = 20.0;
static const CGFloat kGraphDateLabelFontSize = 14.0;

////////////////////////////////////////////////////////////////////////////////

@interface SCGraphView ()

@property UILabel *highlightedHeaderLabel;
@property UILabel *highlightedDataPointLabel;
@property NSNumberFormatter *numberFormatter;

@property CGRect dataRect;
@property BOOL displayTimePeriodLabels;
@property CGPoint initialDataPointLocation;
@property UIFont *preferredLabelFont;

@property (nonatomic) NSNumber *highlightedDataPointIndex;
@property (nonatomic) CGGradientRef backgroundGradientRef;
@property (nonatomic) CGGradientRef blueGradientRef;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation SCGraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        self.dataLineColor = [UIColor UNHCRBlue];
        self.dotColor = [UIColor UNHCRBlue];
        self.labelColor = [UIColor lightGrayColor];
        self.horizontalGuideLineColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.25];
        
        self.preferredLabelFont = [UIFont helveticaNeueLightFontOfSize:kGraphDateLabelFontSize];
        
        self.numberFormatter = [NSNumberFormatter numberFormatterWithFormat:HCRNumberFormatThousandsSeparated forceEuropeanFormat:YES];
        
        self.displayTimePeriodLabels = YES;
        self.displayedTimePeriod = SCDataTimePeriod30Days; // TODO: not hooked up yet
        
        self.roundingMode = SCGraphIndexRoundingModeNormal;
        
        [[EASoundManager sharedSoundManager] registerSoundIDs:@[@(EASoundIDClick0)]];
        
    }
    return self;
}

- (void)dealloc {
    CGGradientRelease(self.backgroundGradientRef);
    CGGradientRelease(self.blueGradientRef);
}

#pragma mark - Drawing Methods

/*
 * The instigating method for drawing the graph
 * clips to the rounded rect
 * draws the components
 */
- (void)drawRect:(CGRect)rect {
    
    // TODO: respond better to dynamic specification of input 'rect' value - poorly supported atm
    
    CGRect highlightedDataPointLabelRect = CGRectMake(self.bounds.origin.x,
                                                      self.bounds.origin.y,
                                                      CGRectGetWidth(self.bounds),
                                                      kGraphDataPointHighlightLabelHeight);
    
    CGFloat dateLabelHeight = (self.displayTimePeriodLabels) ? kGraphDateLabelHeight : 0.0;
    
    static const CGFloat kXPadding = 0.0;
    self.dataRect = CGRectMake(self.bounds.origin.x + kXPadding,
                               CGRectGetMaxY(highlightedDataPointLabelRect),
                               CGRectGetWidth(self.bounds) - 2 * kXPadding,
                               CGRectGetHeight(self.bounds) - dateLabelHeight - highlightedDataPointLabelRect.size.height);
    
    
    
    // clip to the rounded rect
//    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
//                                               byRoundingCorners:UIRectCornerAllCorners
//                                                     cornerRadii:CGSizeMake(16.0, 16.0)];
//    [path addClip];
//    [self _drawBackgroundGradient];
//    [self _drawVerticalGridInRect:dataRect];
    
    if (!self.highlightedDataPointIndex) {
        self.highlightedDataPointIndex = @([self.dataSource numberOfDataPointsInGraphView:self] - 1);
    }
    
    if (CGRectContainsRect(rect, highlightedDataPointLabelRect)) {
        NSInteger index = self.highlightedDataPointIndex.integerValue;
        [self _drawHighlightedDataPointInRect:highlightedDataPointLabelRect forDataPointAtIndex:index];
    }
    
    [self _drawHorizontalGridInRect:self.dataRect clip:NO];
//    [self _drawPatternArtUnderClosingData:dataRect clip:YES];
//    [self _drawPatternLinesUnderDataPoints:dataRect clip:YES];
    [self _drawLineForDataPointsInRect:self.dataRect];
    [self _drawVerticalLineForHighlightedDataPointInRect:self.dataRect];
    [self _drawDotsAtDataPointsInRect:self.dataRect];
    [self _drawLabelsUnderDataRect:self.dataRect];
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _touchesOccurring:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _touchesOccurring:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _touchesStopped];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _touchesStopped];
}

#pragma mark -
#pragma mark Getters & Setters

// TODO: use proper rect to redraw
- (void)setDisplayedTimePeriod:(SCDataTimePeriod)displayedTimePeriod {
    // TODO: this isn't hooked up really
    _displayedTimePeriod = displayedTimePeriod;
    [self setNeedsDisplay];
}

- (void)setRoundingMode:(SCGraphIndexRoundingMode)roundingMode {
    _roundingMode = roundingMode;
    [self setNeedsDisplay];
}

- (void)setDataLineColor:(UIColor *)dataLineColor {
    _dataLineColor = dataLineColor;
    [self setNeedsDisplay];
}

- (void)setDotColor:(UIColor *)dotColor {
    _dotColor = dotColor;
    [self setNeedsDisplay];
}

- (void)setHorizontalGuideLineColor:(UIColor *)horizontalGuideLineColor {
    _horizontalGuideLineColor = horizontalGuideLineColor;
    [self setNeedsDisplay];
}

- (void)setLabelColor:(UIColor *)labelColor {
    _labelColor = labelColor;
    [self setNeedsDisplay];
}

- (void)setHighlightedDataPointIndex:(NSNumber *)highlightedDataPointIndex {
    
    NSNumber *oldValue = _highlightedDataPointIndex;
    NSNumber *newValue = highlightedDataPointIndex;
    
    _highlightedDataPointIndex = highlightedDataPointIndex;
    
    if (highlightedDataPointIndex &&
        oldValue.integerValue != newValue.integerValue) {
        
        if (oldValue) {
            [[EASoundManager sharedSoundManager] playSoundOnce:EASoundIDClick0];
        }
        
        if ([self.delegate respondsToSelector:@selector(graphView:didChangeSelectedIndex:)]) {
            [self.delegate graphView:self didChangeSelectedIndex:newValue.integerValue];
        }
        
    }
    
}

/*
 * This method creates the blue gradient used behind the 'programmer art' pattern
 */
- (CGGradientRef)blueGradientRef {
    if( NULL == _blueGradientRef) {
        CGFloat colors[8] = {0.0, 80.0 / 255.0, 89.0 / 255.0, 1.0,
            0.0, 50.0f / 255.0, 64.0 / 255.0, 1.0};
        CGFloat locations[2] = {0.0, 0.90};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _blueGradientRef = CGGradientCreateWithColorComponents(colorSpace, colors, locations, 2);
        CGColorSpaceRelease(colorSpace);
    }
    return _blueGradientRef;
}

/*
 * Creates the blue background gradient
 */
- (CGGradientRef)backgroundGradientRef {
    if(NULL == _backgroundGradientRef) {
        // lazily create the gradient, then reuse it
        CGFloat colors[16] = {48.0 / 255.0, 61.0 / 255.0, 114.0 / 255.0, 1.0,
            33.0 / 255.0, 47.0 / 255.0, 113.0 / 255.0, 1.0,
            20.0 / 255.0, 33.0 / 255.0, 104.0 / 255.0, 1.0,
            20.0 / 255.0, 33.0 / 255.0, 104.0 / 255.0, 1.0 };
        CGFloat colorStops[4] = {0.0, 0.5, 0.5, 1.0};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _backgroundGradientRef = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 4);
        CGColorSpaceRelease(colorSpace);
    }
    return _backgroundGradientRef;
}

#pragma mark - Public Methods

- (NSInteger)indexOfDataAtPoint:(CGPoint)point {
    
    return [self _indexOfDataAtXPosition:point.x withRoundingMode:self.roundingMode];
    
}

#pragma mark - Private - Clipping Paths

/*
 * Creates and returns a path that can be used to clip drawing to the top
 * of the data graph.
 */
- (UIBezierPath *)_topClipPathFromDataInRect:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path appendPath:[self _linePathForDataPointsInRect:rect]];
    CGPoint currentPoint = [path currentPoint];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), currentPoint.y)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(rect), self.initialDataPointLocation.y)];
    [path addLineToPoint:CGPointMake(self.initialDataPointLocation.x, self.initialDataPointLocation.y)];
    [path closePath];
    return path;
}

/*
 * Creates and returns a path that can be used to clip drawing to the bottom
 * of the data graph.
 */
- (UIBezierPath *)_bottomClipPathFromDataInRect:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path appendPath:[self _linePathForDataPointsInRect:rect]];
    CGPoint currentPoint = [path currentPoint];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), currentPoint.y)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(rect), self.initialDataPointLocation.y)];
    [path addLineToPoint:CGPointMake(self.initialDataPointLocation.x, self.initialDataPointLocation.y)];
    [path closePath];
    return path;
}


#pragma mark -
#pragma mark Draw Labels

- (void)_drawHighlightedDataPointInRect:(CGRect)labelRect forDataPointAtIndex:(NSInteger)index {
    
    UIFont *sharedFont = [UIFont helveticaNeueFontOfSize:kGraphDataPointHighlightFontSize];
    UIColor *sharedColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    
    // write the label string
    // TODO: hacky to use same rect for both labels
    if (!self.highlightedHeaderLabel) {
        self.highlightedHeaderLabel = [[UILabel alloc] initWithFrame:labelRect];
        [self addSubview:self.highlightedHeaderLabel];
        
//        self.highlightedHeaderLabel.backgroundColor = [UIColor clearColor];
        
        self.highlightedHeaderLabel.font = sharedFont;
        self.highlightedHeaderLabel.textAlignment = NSTextAlignmentLeft;
        self.highlightedHeaderLabel.textColor = sharedColor;
        
    }
    
    self.highlightedHeaderLabel.text = self.dataLabelString;
    
    // write the data string
    if (!self.highlightedDataPointLabel) {
        self.highlightedDataPointLabel = [[UILabel alloc] initWithFrame:labelRect];
        [self addSubview:self.highlightedDataPointLabel];
        
//        self.highlightedHeaderLabel.backgroundColor = [UIColor clearColor];
        
        self.highlightedDataPointLabel.font = sharedFont;
        self.highlightedDataPointLabel.textAlignment = NSTextAlignmentRight;
        self.highlightedDataPointLabel.textColor = sharedColor;
    }
    
    [self _updateHighlightedDataPointLabelForIndex:index]; // this method sets text directly
    
}

/*
 * Draws the label names, reterived from the NSDateFormatter.
 */
- (void)_drawLabelsUnderDataRect:(CGRect)dataRect {
    
    // get vars
    CGFloat maxLabelWidth = ceilf([self _maximumLabelWidth]);
    NSInteger dataCount = [[self dataSource] numberOfDataPointsInGraphView:self];
    
    //find safe # of labels to display - round down/truncate
    CGFloat xMinimumPadding = 15.0;
    CGFloat dataWidth = CGRectGetWidth(dataRect);
    NSInteger maxLabelsThatFit = dataWidth / (maxLabelWidth + xMinimumPadding); // is this a safe way to truncate/round down?
    NSInteger labelsToDisplay = MIN(maxLabelsThatFit,dataCount);
    
    // display labels
    CGFloat baseLabelGap = (dataWidth / labelsToDisplay);
    for (NSInteger i = 0; i < labelsToDisplay; i++) {
        
        CGFloat actualLabelXPosition = i * baseLabelGap + baseLabelGap;
        NSInteger indexToUse = (i == 0) ? 0 : [self _indexOfDataAtXPosition:actualLabelXPosition withRoundingMode:self.roundingMode];
        NSString *labelStringToUse = [self.dataSource graphView:self labelForDataPointAtIndex:indexToUse withTimeStamp:NO];
        
        // write the string
        CGSize labelSize = [labelStringToUse sizeWithAttributes:@{NSFontAttributeName: self.preferredLabelFont}];
        CGRect labelRect = CGRectMake(CGRectGetMinX(dataRect) + actualLabelXPosition - labelSize.width,
                                      CGRectGetMaxY(dataRect),
                                      labelSize.width,
                                      labelSize.height);
        [labelStringToUse drawInRect:labelRect withAttributes:@{NSFontAttributeName: self.preferredLabelFont,
                                                                NSForegroundColorAttributeName: self.labelColor}];
        
    }
    
}


#pragma mark -
#pragma mark Draw Line for Data Points

/*
 * Draws the path for the closing price data set.
 */
- (void)_drawLineForDataPointsInRect:(CGRect)rect {
    [self.dataLineColor setStroke];
    UIBezierPath *path = [self _linePathForDataPointsInRect:rect];
    [path stroke];
}

/*
 * Draws dots on the points in the rect
 */
- (void)_drawDotsAtDataPointsInRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *defaultColor = [UIColor whiteColor];
    
    CGContextSetStrokeColorWithColor(context, self.dotColor.CGColor);
    CGContextSetFillColorWithColor(context, defaultColor.CGColor);
    
    [self _performBlockInRect:rect atDataPoints:^(NSInteger index, CGFloat xValue, CGFloat yValue) {
        
        BOOL highlightedDot = self.highlightedDataPointIndex && self.highlightedDataPointIndex.integerValue == index;
        
        CGFloat dotWidth = (highlightedDot) ? kDataDotWidthHighlighted : kDataDotWidth;
        
        CGRect rect = CGRectMake(xValue - dotWidth * 0.5,
                                 yValue - dotWidth * 0.5,
                                 dotWidth,
                                 dotWidth);
        
        CGContextAddEllipseInRect(context, rect);
        
    }];
    
    CGContextDrawPath(context, kCGPathFillStroke);
    
}

- (void)_drawVerticalLineForHighlightedDataPointInRect:(CGRect)rect {
    
    if (self.highlightedDataPointIndex) {
        
        NSInteger highlightedIndex = self.highlightedDataPointIndex.integerValue;
        [self _performBlockInRect:rect atDataPoints:^(NSInteger index, CGFloat xValue, CGFloat yValue) {
            
            if (index == highlightedIndex) {
                // draw vertical line!
                UIBezierPath *path = [UIBezierPath bezierPath];
                path.lineWidth = 2.0;
                
                [path moveToPoint:CGPointMake(xValue, CGRectGetMinY(rect))];
                [path addLineToPoint:CGPointMake(xValue, CGRectGetMaxY(rect))];
                
                [[UIColor orangeColor] setStroke];
                [path stroke];
                
            }
                
        }];
    }
    
}

/*
 * The path for the closing data, this is used to draw the graph, and as part of the 
 * top and bottom clip paths.
 */
- (UIBezierPath *)_linePathForDataPointsInRect:(CGRect)rect {
    
    __block UIBezierPath *path = [UIBezierPath bezierPath];

    CGFloat lineWidth = kDataLineWidth;
    [path setLineWidth:lineWidth];
    [path setLineJoinStyle:kCGLineJoinRound];
    [path setLineCapStyle:kCGLineCapRound];
    
    [self _performBlockInRect:rect atDataPoints:^(NSInteger index, CGFloat xValue, CGFloat yValue) {
        
        if (index == 0) {
            self.initialDataPointLocation = CGPointMake(CGRectGetMinX(rect) + MAX(lineWidth,kDataDotWidthHighlighted) * 0.5,
                                                        yValue);
            [path moveToPoint:self.initialDataPointLocation];
        }
        
        [path addLineToPoint:CGPointMake(xValue, yValue)];
        
    }];
    
    return path;
}

#pragma mark -
#pragma mark Draw Patterns Beneath Line

/*
 * Draws the line pattern, slowly changing the alpha of the stroke color
 * from 0.8 to 0.2.
 */
- (void)_drawPatternLinesUnderDataPoints:(CGRect)rect clip:(BOOL)shouldClip {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if(shouldClip) {
        CGContextSaveGState(ctx);
        UIBezierPath *clipPath = [self _bottomClipPathFromDataInRect:rect];
        [clipPath addClip];
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat lineWidth = 1.0;
    [path setLineWidth:lineWidth];
    // because the line width is odd, offset the horizontal lines by 0.5 points
    [path moveToPoint:CGPointMake(0.0, rint(CGRectGetMinY(rect)) + 0.5)];
    [path addLineToPoint:CGPointMake(rint(CGRectGetMaxX(rect)), rint(CGRectGetMinY(rect)) + 0.5)];
    CGFloat alpha = 0.8;
    UIColor *startColor = [UIColor colorWithWhite:1.0 alpha:alpha];
    [startColor setStroke];
    CGFloat step = 4.0;
    CGFloat stepCount = CGRectGetHeight(rect) / step;
    // alpha starts at 0.8, ends at 0.2
    CGFloat alphaStep = (0.8 - 0.2) / stepCount;
    CGContextSaveGState(ctx);
    CGFloat translation = CGRectGetMinY(rect);
    while(translation < CGRectGetMaxY(rect)) {
        [path stroke];
        CGContextTranslateCTM(ctx, 0.0, lineWidth * step);
        translation += lineWidth * step;
        alpha -= alphaStep;
        startColor = [startColor colorWithAlphaComponent:alpha];
        [startColor setStroke];
    }
    CGContextRestoreGState(ctx);
    if(shouldClip) {
        CGContextRestoreGState(ctx);
    }
}

/*
 * This method draws the line used behind the 'programmer art' pattern
 */
- (void)_drawLineFromPoint:(CGPoint)start toPoint:(CGPoint)end {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path setLineWidth:1.0];
    [path moveToPoint:start];
    [path addLineToPoint:end];
    [path stroke];
}

/*
 * This method draws the blue gradient used behind the 'programmer art' pattern
 */
- (void)_drawRadialGradientInSize:(CGSize)size centeredAt:(CGPoint)center {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat startRadius = 0.0;
    CGFloat endRadius = 0.85 * pow(floor(size.width / 2.0) * floor(size.width / 2.0) +
                                   floor(size.height / 2.0) * floor(size.height / 2.0), 0.5);
    CGContextDrawRadialGradient(ctx, self.blueGradientRef,  center, startRadius, center,
                                endRadius, kCGGradientDrawsAfterEndLocation);
}

/*
 * This method creates a UIImage from the 'programmer art' pattern
 */
- (UIImage *)_patternImageOfSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
    
    CGPoint center = CGPointMake(floor(size.width / 2.0), floor(size.height / 2.0));
    [self _drawRadialGradientInSize:size centeredAt:center];
    UIColor *lineColor = [UIColor colorWithRed:211.0 / 255.0 
                                         green:218.0 / 255.0
                                          blue:182.0 / 255.0
                                         alpha:1.0];
    [lineColor setStroke];
    
    CGPoint start = CGPointMake(0.0, 0.0);
    CGPoint end = CGPointMake(floor(size.width), floor(size.height));
    [self _drawLineFromPoint:start toPoint:end];
    
    start = CGPointMake(0.0, floor(size.height));
    end = CGPointMake(floor(size.width), 0.0);
    [self _drawLineFromPoint:start toPoint:end];
    
    UIImage *patternImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return patternImage;
}

/*
 * draws the 'programmer art' pattern under the closing data graph
 */
- (void)_drawPatternArtUnderClosingData:(CGRect)rect clip:(BOOL)shouldClip {
//    [[UIColor colorWithPatternImage:[self _patternImageOfSize:CGSizeMake(32.0, 32.0)]] setFill];
//    if(shouldClip) {
//        UIBezierPath *path = [self _bottomClipPathFromDataInRect:rect];
//        [path fill];
//    } else {
//        UIRectFill(rect);
//    }
}


#pragma mark -
#pragma mark Draw Horizontal Grid

/*
 * draws the horizontal lines that make up the grid
 * if shouldClip then it will clip to the data
 * if not then it won't
 * shouldClip is a debugging tool, pass YES most of the time
 */
- (void)_drawHorizontalGridInRect:(CGRect)dataRect clip:(BOOL)shouldClip {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if(shouldClip) {
        CGContextSaveGState(ctx);
        UIBezierPath *clipPath = [self _topClipPathFromDataInRect:dataRect];
        [clipPath addClip];
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path setLineWidth:1.0];
    [path moveToPoint:CGPointMake(rint(CGRectGetMinX(dataRect)),
                                  rint(CGRectGetMinY(dataRect)) + 0.5)];
    [path addLineToPoint:CGPointMake(rint(CGRectGetMaxX(dataRect)),
                                     rint(CGRectGetMinY(dataRect)) + 0.5)];
    CGFloat dashPatern[2] = {1.0, 1.0};
    [path setLineDash:dashPatern count:2 phase:0.0];
    
    [self.horizontalGuideLineColor setStroke];
    
    CGContextSaveGState(ctx);
    [path stroke];
    for(int i = 0; i < 5; i++) {
        CGContextTranslateCTM(ctx, 0.0, rint(CGRectGetHeight(dataRect) / 5.0));
        [path stroke];
    }
    CGContextRestoreGState(ctx);
    if(shouldClip) {
        CGContextRestoreGState(ctx);
    }
}


#pragma mark -
#pragma mark Draw Vertical Grid

/*
 * Draws the vertical grid that sits behind the data
 * makes sure not to step into the space needed by the
 * volume graph and the price labels
 */
- (void)_drawVerticalGridInRect:(CGRect)dataRect {
    UIColor *gridColor = [UIColor colorWithRed:74.0 / 255.0 green:86.0 / 255.0 
                                          blue:126.0 / 266.0 alpha:0.25];
    [gridColor setStroke];
    
    NSInteger dataCount = [[self dataSource] numberOfDataPointsInGraphView:self];
    
    UIBezierPath *gridLinePath = [UIBezierPath bezierPath];
    [gridLinePath moveToPoint:CGPointMake(rint(CGRectGetMinX(dataRect)), CGRectGetMinY(dataRect))];
    [gridLinePath addLineToPoint:CGPointMake(rint(CGRectGetMinX(dataRect)), CGRectGetMaxY(dataRect))];
    [gridLinePath setLineWidth:1.0];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    // # of gaps is # of data points - 1
    // context saves, so don't re-calc every time
    CGFloat lineGap = CGRectGetWidth(self.bounds) / (dataCount - 1);
    
    for(int i = 0; i < dataCount; i++) {
//        CGFloat linePosition = i * ( CGRectGetWidth(self.bounds) / dataCount );
        CGContextTranslateCTM(ctx, rint(lineGap), 0.0);
        [gridLinePath stroke];
    }
    CGContextRestoreGState(ctx);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, rint(CGRectGetMaxX(dataRect)), 0.0);
    [gridLinePath stroke];
    CGContextRestoreGState(ctx);
    
//    UIBezierPath *horizontalLine = [UIBezierPath bezierPath];
//    [horizontalLine moveToPoint:CGPointMake(rint(CGRectGetMinX(dataRect)), rint(CGRectGetMaxY(dataRect)))];
//    [horizontalLine addLineToPoint:CGPointMake(rint(CGRectGetMaxX(dataRect)), rint(CGRectGetMaxY(dataRect)))];
//    [horizontalLine setLineWidth:2.0];
//    [horizontalLine stroke];
//    CGContextSaveGState(ctx);
//    [horizontalLine stroke];
//    CGContextRestoreGState(ctx);
}

#pragma mark - Background Gradient

/*
 * draws the blue background gradient
 */
- (void)_drawBackgroundGradient {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGPoint startPoint = {0.0, 0.0};
    CGPoint endPoint = {0.0, self.bounds.size.height};
    CGContextDrawLinearGradient(ctx, self.backgroundGradientRef, startPoint, endPoint,0);
}


#pragma mark - Private Methods

- (CGFloat)_maximumLabelWidth {

    // set custom font
    UIFont *labelFont = self.preferredLabelFont;
    
    // compare all strings using font
    NSInteger numberOfDataPoints = [self.dataSource numberOfDataPointsInGraphView:self];
    
    CGFloat maxWidth = 0;
    for (NSInteger i = 0; i < numberOfDataPoints; i++) {
        NSString *labelString = [self.dataSource graphView:self labelForDataPointAtIndex:i withTimeStamp:NO];
        CGSize projectedLabelSize = [labelString sizeWithAttributes:@{NSFontAttributeName: labelFont}];
        CGFloat projectedLabelWidth = projectedLabelSize.width;
        maxWidth = MAX(maxWidth,projectedLabelWidth);
    }
    
    return maxWidth;
}

- (void)_performBlockInRect:(CGRect)rect atDataPoints:(void (^)(NSInteger index, CGFloat xValue, CGFloat yValue))dataPointBlock {
    
    // inset so the path does not ever go beyond the frame of the graph
    CGFloat largestObjectWidth = MAX(kDataLineWidth,kDataDotWidthHighlighted);
    rect = CGRectInset(rect, largestObjectWidth / 2.0, largestObjectWidth);
    
    NSInteger dataCount = [self.dataSource numberOfDataPointsInGraphView:self];
    
    CGFloat maxY = [self.dataSource graphViewMaxYValue:self];
    CGFloat minY = [self.dataSource graphViewMinYValue:self];
    
    CGFloat verticalScale = CGRectGetHeight(rect) / (maxY - minY);
    CGFloat horizontalSpacing = CGRectGetWidth(rect) / (dataCount - 1); // # of gaps = count - 1
    
    CGFloat baseline = CGRectGetMinY(rect);
    CGFloat maxHeight = CGRectGetHeight(rect);
    
    for(int i = 0; i < dataCount; i++) {
        
        NSNumber *dataPointNumber = [self.dataSource graphView:self dataPointForIndex:i];
        NSParameterAssert(dataPointNumber);
        
        CGFloat dataPoint = [dataPointNumber floatValue];
        CGFloat yValue = baseline + (maxHeight - (dataPoint - minY) * verticalScale);
        
        CGFloat xValue = CGRectGetMinX(rect) + i * horizontalSpacing;
        
        dataPointBlock(i, xValue, yValue);
        
    }
    
}

- (NSInteger)_indexOfDataAtXPosition:(CGFloat)xPosition withRoundingMode:(SCGraphIndexRoundingMode)roundingMode {
    
    NSInteger numberOfDataPoints = [self.dataSource numberOfDataPointsInGraphView:self];
    NSInteger validIndexMaximum = numberOfDataPoints - 1;
    
    CGFloat positionRatio = xPosition / CGRectGetWidth(self.bounds);
    CGFloat rawPositionResult = validIndexMaximum * positionRatio;
    
    NSInteger roundedIndexFromPositionRatio;
    switch (roundingMode) {
        case SCGraphIndexRoundingModeNormal:
            roundedIndexFromPositionRatio = lroundf(rawPositionResult);
            break;
            
        case SCGraphIndexRoundingModeCeiling:
            roundedIndexFromPositionRatio = ceilf(rawPositionResult);
            break;
            
        case SCGraphIndexRoundingModeFloor:
            roundedIndexFromPositionRatio = floorf(rawPositionResult);
            break;
    }
    
    return roundedIndexFromPositionRatio;
    
}

- (void)_updateHighlightedDataPointLabelForIndex:(NSInteger)index {
    
    NSNumber *dataValue = [self.dataSource graphView:self dataPointForIndex:index];
    NSString *dataValueString = [self.numberFormatter stringFromNumber:dataValue];
    
    NSString *dataDate = [self.dataSource graphView:self labelForDataPointAtIndex:index withTimeStamp:YES];
    
    self.highlightedDataPointLabel.text = [NSString stringWithFormat:@"%@ | %@",
                                           dataDate,
                                           dataValueString];
    
}

- (void)_touchesOccurring:(NSSet *)touches {
    
    if ([self.delegate respondsToSelector:@selector(graphViewBeganTouchingData:withTouches:)]) {
        [self.delegate graphViewBeganTouchingData:self withTouches:touches];
    }
    
    UITouch *touch = touches.anyObject;
    CGFloat xTouchFactor = [touch locationInView:self].x;
    
    NSInteger highlightedIndex = MAX(0,
                                     MIN([self _indexOfDataAtXPosition:xTouchFactor withRoundingMode:self.roundingMode],
                                         [self.dataSource numberOfDataPointsInGraphView:self] - 1));
    [self _updateHighlightedDataPointLabelForIndex:highlightedIndex];
    
    // update line
    self.highlightedDataPointIndex = @(highlightedIndex);
    [self setNeedsDisplayInRect:self.dataRect];
    
}

- (void)_touchesStopped {
    
    if ([self.delegate respondsToSelector:@selector(graphViewStoppedTouchingData:)]) {
        [self.delegate graphViewStoppedTouchingData:self];
    }
    
    // reset line and label
//    self.highlightedDataPointIndex = nil;
    [self setNeedsDisplay];
}

@end
