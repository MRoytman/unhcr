//
//  HCRSurveyController.m
//  UNHCR
//
//  Created by Sean Conrad on 1/5/14.
//  Copyright (c) 2014 Sean Conrad. All rights reserved.
//

#import "HCRSurveyController.h"
#import "HCRSurveyCell.h"
#import "HCRSurveyParticipantView.h"
#import "HCRParticipantToolbar.h"
#import "HCRSurveyQuestion.h"

#import <MBProgressHUD.h>

////////////////////////////////////////////////////////////////////////////////

@interface HCRSurveyController ()

@property CGRect keyboardBounds;
@property NSTimeInterval keyboardAnimationTime;
@property UIViewAnimationOptions keyboardAnimationOptions;

@property UITapGestureRecognizer *tapRecognizer;
@property UITextField *textFieldToDismiss;

@property UIBarButtonItem *doneBarButton;
@property UIBarButtonItem *closeBarButton;

@property BOOL selectingCell;

@property (nonatomic, strong) HCRSurveyAnswerSetParticipant *currentParticipant;

@property (nonatomic, readonly) HCRSurvey *survey;
@property (nonatomic, readonly) HCRSurveyAnswerSet *answerSet;
@property (nonatomic, readonly) UICollectionViewFlowLayout *flowLayout;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HCRSurveyController

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = @"Lebanon: Access to Care";
    
//    self.collectionView.scrollEnabled = NO;
    self.collectionView.backgroundColor = [UIColor tableBackgroundColor];
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    self.navigationController.toolbarHidden = YES;
    
    // KEYBOARD AND INPUTS
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_dismissKeyboard)];
    [self.view addGestureRecognizer:self.tapRecognizer];
    
    self.tapRecognizer.cancelsTouchesInView = NO;
    
    // TOOLBAR
    HCRParticipantToolbar *toolbar = (HCRParticipantToolbar *)self.navigationController.toolbar;
    NSParameterAssert([toolbar isKindOfClass:[HCRParticipantToolbar class]]);
    
    toolbar.addParticipant.target = self;
    toolbar.addParticipant.action = @selector(_addParticipantButtonPressed);
    
    toolbar.nextParticipant.target = self;
    toolbar.nextParticipant.action = @selector(_nextParticipantButtonPressed);
    
    toolbar.previousParticipant.target = self;
    toolbar.previousParticipant.action = @selector(_previousParticipantButtonPressed);
    
    toolbar.removeParticipant.target = self;
    toolbar.removeParticipant.action = @selector(_removeParticipantButtonPressed);
    
    [toolbar.centerButton addTarget:self
                             action:@selector(_toolbarParticipantPressed:)
                   forControlEvents:UIControlEventTouchUpInside];
    
    // NOTIFICATIONS
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // LAYOUT AND REUSABLES
    [self.collectionView registerClass:[HCRSurveyCell class]
            forCellWithReuseIdentifier:kSurveyCellIdentifier];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // test whether likely first load - if so, refresh
    if (!self.currentParticipant) {
        [self _refreshModelDataForCollectionView:nil];
        self.currentParticipant = [self.answerSet.participants objectAtIndex:0];
    }
    
    NSInteger percentComplete = [[HCRDataManager sharedManager] percentCompleteForAnswerSet:self.answerSet];
    [self _updateAnswersCompleted:(percentComplete == 100)];
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    // scroll to top unanswered question UNLESS it's the very first question
    if ([self _indexPathForCurrentParticipantFirstUnansweredQuestion].row != 0) {
        [self _scrollToUnansweredQuestionForCurrentParticipant];
    }
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Class Methods

+ (UICollectionViewLayout *)preferredLayout {
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    layout.sectionInset = UIEdgeInsetsZero;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    
    return layout;
}

#pragma mark - UICollectionView Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    NSInteger numberOfSections;
    
    if (collectionView == self.collectionView) {
        
        // SURVEY PAGES
        numberOfSections = 1;
        
    } else if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        
        // CONTENTS OF SURVEY PAGES
        NSInteger participantID = [self _participantIDForSurveyView:collectionView];
        HCRSurveyAnswerSetParticipant *participant = [self.answerSet participantWithID:participantID];
        numberOfSections = participant.questions.count;
        
    } else {
        
        // WTF
        NSAssert(0, @"Unhandled collectionView type");
        numberOfSections = 0;
    }
    
    return numberOfSections;
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    NSInteger numberOfItemsInSection = -1;
    
    if (collectionView == self.collectionView) {
        
        // SURVEY PAGES
        numberOfItemsInSection = self.answerSet.participants.count;
        
    } else if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        
        // CONTENTS OF SURVEY PAGES
        
        HCRSurveyAnswerSetParticipantQuestion *question = [self _participantQuestionForSection:section inCollectionView:collectionView];
        HCRSurveyQuestion *surveyQuestion = [[HCRDataManager sharedManager] surveyQuestionWithQuestionID:question.question];
        
        if (question.answer ||
            surveyQuestion.freeformLabel) {
            
            numberOfItemsInSection = 1; // the answer is all that remains :)
            
        } else {
            
            numberOfItemsInSection = surveyQuestion.answers.count; // normal :)
            
        }
		//NSLog (@"Code %@ - Section %d - Items: %d", question.question, section, numberOfItemsInSection);

    } else {
        
        // WTF
        NSAssert(0, @"Unhandled collectionView type");
        numberOfItemsInSection = 0;
    }
    
    return numberOfItemsInSection;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == self.collectionView) {
        
        // SURVEY PAGES
        return [self _collectionViewSurveyForIndexPath:indexPath];
        
    } else if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        
        // CONTENTS OF SURVEY PAGES
        return [self _cellForParticipantCollectionView:collectionView
                                           atIndexPath:indexPath];
        
    } else {
        NSAssert(NO, @"Unhandled collectionView type..");
        return nil;
    }
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == self.collectionView) {
        
        // SURVEY PAGES
        // do nothing!
        
    } else if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            HCRSurveyQuestionHeader *header =
            [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                               withReuseIdentifier:kSurveyHeaderIdentifier
                                                      forIndexPath:indexPath];
            
            // ADD QUESTION
            HCRSurveyAnswerSetParticipantQuestion *question = [self _participantQuestionForSection:indexPath.section inCollectionView:collectionView];
            
            HCRSurveyQuestion *surveyQuestion = [self _surveyQuestionForSection:indexPath.section inCollectionView:collectionView];
            
            [header setSurveyQuestion:surveyQuestion
                      withParticipant:[self.answerSet participantWithID:[self _participantIDForSurveyView:collectionView]]];
            
            header.questionAnswered = (question.answer != nil || question.answerString != nil);
            
            return header;
        } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
            HCRSurveyQuestionFooter *footer =
            [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                               withReuseIdentifier:kSurveyFooterIdentifier
                                                      forIndexPath:indexPath];
            
            BOOL bottomLine = (indexPath.section == collectionView.numberOfSections - 1);
            footer.showMSFLogo = bottomLine;
            
            return footer;
        }
        
    } else {
        NSAssert(NO, @"Unhandled collectionView type..");
    }
    
    return nil;
    
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == self.collectionView) {
        
        // SURVEY PAGES
        // do nothing
        
    } else if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        
        // CONTENTS OF SURVEY PAGES
        
        [self _surveyAnswerCellPressedInCollectionView:collectionView AtIndexPath:indexPath withFreeformAnswer:nil];
        
    } else {
        NSAssert(NO, @"Unhandled collectionView type..");
    }
    
}

#pragma mark - UICollectionView Delegate Flow Layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    if (collectionView == self.collectionView) {
        
        // SURVEY PAGES
        return CGSizeZero;
        
    } else if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        
        // CONTENTS OF SURVEY PAGES
        HCRSurveyQuestion *question = [self _surveyQuestionForSection:section inCollectionView:collectionView];
        return [HCRSurveyQuestionHeader sizeForHeaderInCollectionView:(HCRSurveyParticipantView *)collectionView
                                                     withQuestionData:question
                                                      withParticipant:[self.answerSet participantWithID:[self _participantIDForSurveyView:collectionView]]];
        
    } else {
        NSAssert(NO, @"Unhandled collectionView type..");
        return CGSizeZero;
    }
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    
    if (collectionView == self.collectionView) {
        
        // SURVEY PAGES
        return CGSizeZero;
        
    } else if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        
        // CONTENTS OF SURVEY PAGES
        BOOL bottomLine = (section == collectionView.numberOfSections - 1);
        
        return (bottomLine) ? [HCRSurveyQuestionFooter preferredFooterSizeForCollectionView:collectionView] : [HCRSurveyQuestionFooter preferredFooterSizeWithBottomLineOnlyForCollectionView:collectionView];
        
    } else {
        NSAssert(NO, @"Unhandled collectionView type..");
        return CGSizeZero;
    }
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // not ideal to use this method on such a large collection, but there's some wackiness with the collectionview changing all over the place, so..
    
    if (collectionView == self.collectionView) {
        
        // SURVEY PAGES
        UINavigationBar *navBar = self.navigationController.navigationBar;
        UIToolbar *toolbar = self.navigationController.toolbar;
        UIEdgeInsets navigationInsets = UIEdgeInsetsMake(CGRectGetMinY(navBar.frame) + CGRectGetHeight(navBar.bounds),
                                                         0,
                                                         (self.navigationController.toolbarHidden) ? 0 : CGRectGetHeight(toolbar.bounds),
                                                         0);
        
        return UIEdgeInsetsInsetRect(self.view.bounds, navigationInsets).size;
        
    } else if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        
        // CONTENTS OF SURVEY PAGES
        // TODO: much of this re-used from cellForItemAtIndexPath
        NSString *answerString = [self _answerStringForCollectionView:(HCRSurveyParticipantView *)collectionView
                                                          atIndexPath:indexPath];
        return [HCRSurveyAnswerCell sizeForCollectionView:collectionView withAnswerString:answerString];
        
    }
    
    NSAssert(NO, @"Unhandled collectionView type..");
    return CGSizeZero;
    
}

#pragma mark - UIScrollView

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    [self _updateCurrentParticipantWithActiveScrollView:scrollView];
    
}

#pragma mark - HCRDataFieldCell Delegate

- (void)dataEntryCellDidBecomeFirstResponder:(HCRDataEntryFieldCell *)signInCell {
    
    self.textFieldToDismiss = signInCell.inputTextField;
    
    // position text field / collection view
    HCRSurveyAnswerFreeformCell *freeformCell = (HCRSurveyAnswerFreeformCell *)signInCell;
    NSParameterAssert([freeformCell isKindOfClass:[HCRSurveyAnswerFreeformCell class]]);
    
    // next loop so keyboard data populates
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGFloat yTarget = CGRectGetMinY(freeformCell.frame) + CGRectGetMidY(freeformCell.bounds);
        CGFloat midPoint = 0.5 * (CGRectGetHeight(freeformCell.participantView.bounds) - CGRectGetHeight(self.keyboardBounds));
        
        [UIView animateWithDuration:self.keyboardAnimationTime
                              delay:0
                            options:self.keyboardAnimationOptions
                         animations:^{
                             [freeformCell.participantView setContentOffset:CGPointMake(0, yTarget - midPoint)];
                         } completion:nil];
        
    });
    
}

- (void)dataEntryCellDidPressDone:(HCRDataEntryFieldCell *)signInCell {
    
    [signInCell.inputTextField resignFirstResponder];
    
}

- (void)dataEntryCellDidResignFirstResponder:(HCRDataEntryFieldCell *)signInCell {
    
    self.textFieldToDismiss = nil;
    
    HCRSurveyAnswerFreeformCell *freeformCell = (HCRSurveyAnswerFreeformCell *)signInCell;
    NSParameterAssert([freeformCell isKindOfClass:[HCRSurveyAnswerFreeformCell class]]);
    
    NSIndexPath *cellIndexPath = [freeformCell.participantView indexPathForCell:freeformCell];
    
    [self _surveyAnswerCellPressedInCollectionView:freeformCell.participantView AtIndexPath:cellIndexPath withFreeformAnswer:(signInCell.inputTextField.text.length > 0) ? signInCell.inputTextField.text : nil];
    
    // next loop so cells are regenerated
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGFloat yTarget = CGRectGetMinY(freeformCell.frame) + CGRectGetMidY(freeformCell.bounds);
        CGFloat midPoint = 0.33 * CGRectGetHeight(freeformCell.participantView.bounds);
        
        [UIView animateWithDuration:self.keyboardAnimationTime
                              delay:0
                            options:self.keyboardAnimationOptions
                         animations:^{
                             [freeformCell.participantView setContentOffset:CGPointMake(0, yTarget - midPoint)];
                         } completion:nil];
        
    });
    
}

#pragma mark - Getters & Setters

- (HCRSurvey *)survey {
    
    // TODO: refactor, point to dynamic survey with ID set by preceding controller
    return [[[HCRDataManager sharedManager] localSurveys] objectAtIndex:0];
    
}

- (HCRSurveyAnswerSet *)answerSet {
    
    return [[HCRDataManager sharedManager] surveyAnswerSetWithLocalID:self.answerSetID];
    
}

- (UICollectionViewFlowLayout *)flowLayout {
    
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    NSParameterAssert([flow isKindOfClass:[UICollectionViewFlowLayout class]]);
    
    return flow;
    
}

- (void)setCurrentParticipant:(HCRSurveyAnswerSetParticipant *)currentParticipant {
    
    _currentParticipant = currentParticipant;
    
    // set data
    [self _refreshToolbarData];
    
    // slide to correct position..
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGPoint targetOffset = CGPointMake(screenWidth * [self.answerSet.participants indexOfObject:currentParticipant],
                                       self.collectionView.contentOffset.y);

    [self.collectionView setContentOffset:targetOffset
                                 animated:YES];
    
    [self _refreshModelDataForParticipantID:currentParticipant.participantID.integerValue];
    
}

#pragma mark - Private Methods (Layout)

- (void)_refreshModelDataForCollectionView:(UICollectionView *)collectionView {
    
    if ([collectionView isKindOfClass:[HCRSurveyParticipantView class]]) {
        NSInteger participantID = [self _participantIDForSurveyView:collectionView];
        [self _refreshModelDataForParticipantID:participantID];
    } else {
        [[HCRDataManager sharedManager] refreshSurveyResponsesForAllParticipantsWithAnswerSet:self.answerSet];
    }
    
}

- (void)_refreshModelDataForParticipantID:(NSInteger)participantID {
    
    [[HCRDataManager sharedManager] refreshSurveyResponsesForParticipantID:participantID withAnswerSet:self.answerSet];
}

- (void)_reloadAllData {
    [self _reloadLayoutData:YES inSections:nil withCollectionView:self.collectionView animated:YES withLayoutChanges:nil];
}

- (void)_reloadLayoutData:(BOOL)reloadData inSections:(NSIndexSet *)sections withCollectionView:(UICollectionView *)collectionView animated:(BOOL)animated withLayoutChanges:(void (^)(void))layoutChanges {
    
    void (^percentCompleteCheck)(void) = ^{
        NSInteger percentComplete = [[HCRDataManager sharedManager] percentCompleteForAnswerSet:self.answerSet];
        [self _updateAnswersCompleted:(percentComplete == 100)];
    };
    
    // completion code (update UI, etc)
    if (animated == NO ||
        (reloadData && !layoutChanges)) {
        [collectionView reloadData];
        percentCompleteCheck();
    }
    
    if (layoutChanges) {
        [collectionView performBatchUpdates:layoutChanges completion:^(BOOL finished) {
            if (reloadData) {
                if (sections) {
                    [collectionView reloadSections:sections];
                    percentCompleteCheck();
                } else {
                    [collectionView reloadData];
                    percentCompleteCheck();
                }
                [self _refreshToolbarData];
            }
        }];
    }
    
}

#pragma mark - Private Methods (Keyboard)

- (void)_keyboardWillShow:(NSNotification *)notification {
    NSDictionary *dictionary = notification.userInfo;
    self.keyboardBounds = [[dictionary objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardAnimationTime = [[dictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    self.keyboardAnimationOptions = [[dictionary objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
}

- (void)_keyboardWillHide:(NSNotification *)notification {
    NSDictionary *dictionary = notification.userInfo;
    self.keyboardBounds = [[dictionary objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardAnimationTime = [[dictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    self.keyboardAnimationOptions = [[dictionary objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
}

#pragma mark - Private Methods (Navigation)

- (void)_closeButtonPressed {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_doneButtonPressed {
    
    HCRSurveyAnswerSetParticipant *headParticipant = [self.answerSet participantWithID:0];
    HCRSurveyAnswerSetParticipantQuestion *question = [headParticipant questionWithID:self.survey.participantsQuestion];
    NSString *statedParticipants = question.answerString;
    
    // if participants match OR if consent question has been answered
    if (self.answerSet.participants.count == statedParticipants.integerValue ||
        [self.answerSet.consent isEqualToNumber:@0] ||
        [self.answerSet.consent isEqualToNumber:@77]) {
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        
    } else {
        
        NSString *body = [NSString stringWithFormat:@"You are attempting to submit a survey with %d participant%@, but in question %@ you indicated there were %d member%@ of the household. Are you sure you want to submit this survey?",
                          self.answerSet.participants.count,
                          (self.answerSet.participants.count == 1) ? @"" : @"s",
                          self.survey.participantsQuestion,
                          statedParticipants.integerValue,
                          (statedParticipants.integerValue == 1) ? @"" : @"s"];
        
        [UIAlertView showConfirmationDialogWithTitle:@"Mismatched Participants"
                                             message:body
                                             handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                                 if (buttonIndex != alertView.cancelButtonIndex) {
                                                     [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                                 }
                                             }];
    }
    
}

- (void)_addParticipantButtonPressed {
    
    void (^addParticipant)(void) = ^{
        HCRSurveyAnswerSetParticipant *newParticipant = [[HCRDataManager sharedManager] createNewParticipantForAnswerSet:self.answerSet];
        
        [self _refreshModelDataForParticipantID:newParticipant.participantID.integerValue];
        [self _reloadAllData];
        
        self.currentParticipant = newParticipant;
    };
    
    HCRSurveyAnswerSetParticipant *headParticipant = [self.answerSet participantWithID:0];
    HCRSurveyAnswerSetParticipantQuestion *question = [headParticipant questionWithID:self.survey.participantsQuestion];
    NSString *statedParticipants = question.answerString;
    
    if (self.answerSet.participants.count >= statedParticipants.integerValue) {
        
        NSString *bodyText = [NSString stringWithFormat:@"Adding another participant will exceed the number of household you specified in question #%@. Proceeding may cause survey data to be incorrect. Are you sure you want to add another participant to the survey?",self.survey.participantsQuestion];
        
        [UIAlertView showConfirmationDialogWithTitle:@"Add Participant?"
                                             message:bodyText
                                             handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                                 if (buttonIndex != alertView.cancelButtonIndex) {
                                                     addParticipant();
                                                 }
                                             }];
        
    } else {
        addParticipant();
    }
    
}

- (void)_nextParticipantButtonPressed {
    
    HCRSurveyAnswerSetParticipant *participant = [self _nextParticipantFromCurrentParticipant];
    if (participant) {
        self.currentParticipant = participant;
    } else {
        NSAssert(NO, @"Should not be able to toggle to this participant!");
    }
    
}

- (void)_previousParticipantButtonPressed {
    
    HCRSurveyAnswerSetParticipant *participant = [self _previousParticipantFromCurrentParticipant];
    if (participant) {
        self.currentParticipant = participant;
    } else {
        NSAssert(NO, @"Should not be able to toggle to this participant!");
    }
    
}

- (void)_removeParticipantButtonPressed {
    
    if (self.answerSet.participants.count > 1) {
        
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForItem:[self.answerSet.participants indexOfObject:self.currentParticipant] inSection:0];
        HCRSurveyAnswerSetParticipant *oldParticipant = self.currentParticipant;
        
        HCRSurveyAnswerSetParticipant *nextParticipant = [self _nextParticipantFromCurrentParticipant];
        HCRSurveyAnswerSetParticipant *prevParticipant = [self _previousParticipantFromCurrentParticipant];
        
        HCRSurveyAnswerSetParticipant *newParticipant = (nextParticipant) ? nextParticipant : prevParticipant;
        
        if (!newParticipant) {
            newParticipant = [self.answerSet.participants objectAtIndex:0];
        }
        
        [[HCRDataManager sharedManager] removeParticipant:oldParticipant fromAnswerSet:self.answerSet];
        
        [self _refreshModelDataForCollectionView:self.collectionView];
        
        [self _reloadLayoutData:YES
                     inSections:[NSIndexSet indexSetWithIndex:0]
             withCollectionView:self.collectionView
                       animated:YES
              withLayoutChanges:^{
                  
                  [self.collectionView deleteItemsAtIndexPaths:@[oldIndexPath]];
                  
              }];
        
        self.currentParticipant = newParticipant;
        
    }
    
}

- (void)_refreshToolbarData {
    
    if (self.currentParticipant) {
        
        HCRParticipantToolbar *toolbar = (HCRParticipantToolbar *)self.navigationController.toolbar;
        NSParameterAssert([toolbar isKindOfClass:[HCRParticipantToolbar class]]);
        
        toolbar.participants = self.answerSet.participants;
        
        toolbar.currentParticipant = self.currentParticipant;
        
        // check for 100% completion
        NSInteger percentComplete = [[HCRDataManager sharedManager] percentCompleteForParticipantID:self.currentParticipant.participantID.integerValue withAnswerSet:self.answerSet];
        
        toolbar.backgroundColor = (percentComplete == 100) ? [UIColor flatGreenColor] : toolbar.defaultToolbarColor;
        
        NSNumber *currentConsent = self.answerSet.consent;
        [self.navigationController setToolbarHidden:![currentConsent boolValue]
                                           animated:YES];
        
    }
    
}

#pragma mark - Private Methods

- (UICollectionViewCell *)_cellForParticipantCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath {
    
    HCRCollectionCell *cell;
    
    // initial vars
    HCRSurveyQuestion *surveyQuestion = [self _surveyQuestionForSection:indexPath.section inCollectionView:collectionView];
    HCRSurveyAnswerSetParticipantQuestion *participantQuestion = [self _participantQuestionForSection:indexPath.section inCollectionView:collectionView];
    
    // get answer
    HCRSurveyQuestionAnswer *answer = [self _answerDataForSurveyQuestion:surveyQuestion withParticipantData:participantQuestion atIndexPath:indexPath];
    
    BOOL answered = (participantQuestion.answer != nil || participantQuestion.answerString != nil);
    BOOL freeformAnswer = [answer.freeform boolValue];
    
    if (surveyQuestion.freeformLabel ||
        freeformAnswer) {
        
        // FREE FORM CELL
        HCRSurveyAnswerFreeformCell *freeformCell =
        [collectionView dequeueReusableCellWithReuseIdentifier:kSurveyAnswerFreeformCellIdentifier
                                                  forIndexPath:indexPath];
        cell = freeformCell;
        
        freeformCell.participantView = (HCRSurveyParticipantView *)collectionView;
        freeformCell.answered = answered;
        
        NSString *labelTitle = (surveyQuestion.freeformLabel) ? surveyQuestion.freeformLabel : answer.string;
        freeformCell.labelTitle = [NSString stringWithFormat:@"%@:",[labelTitle capitalizedString]];
        freeformCell.inputPlaceholder = @"(tap here to answer)";
        freeformCell.inputTextField.text = participantQuestion.answerString;
        
        HCRDataEntryType fieldType;
        
        if ([surveyQuestion.keyboard isEqualToString:HCRSurveyQuestionKeyboardNumberKey]) {
            fieldType = HCRDataEntryTypeNumber;
        } else if ([surveyQuestion.keyboard isEqualToString:HCRSurveyQuestionKeyboardStringKey]) {
            fieldType = HCRDataEntryTypeDefault;
        } else {
            NSAssert(NO, @"Unhandled keyboard field type!");
            fieldType = HCRDataEntryTypeDefault;
        }
        
        freeformCell.inputType = fieldType;
        freeformCell.delegate = self;
        
        freeformCell.lastFieldInSeries = YES;
        
    } else {
        
        // NORMAL ANSWER CELL
        
        HCRSurveyAnswerCell *answerCell =
        [collectionView dequeueReusableCellWithReuseIdentifier:kSurveyAnswerCellIdentifier
                                                  forIndexPath:indexPath];
        cell = answerCell;
        
        answerCell.title = (participantQuestion.answerString) ? participantQuestion.answerString : answer.string;
        answerCell.answered = answered;
    }
    
    cell.processingViewPosition = HCRCollectionCellProcessingViewPositionCenter;
    
    [cell setBottomLineStatusForCollectionView:collectionView atIndexPath:indexPath];
    
    return cell;
    
}

- (UICollectionViewCell *)_collectionViewSurveyForIndexPath:(NSIndexPath *)indexPath {
    
    HCRSurveyCell *surveyCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kSurveyCellIdentifier
                                                                               forIndexPath:indexPath];
    
    HCRSurveyAnswerSetParticipant *participant = [self.answerSet.participants objectAtIndex:indexPath.row];
    
    surveyCell.participantDataSourceDelegate = self;
    surveyCell.participantID = participant.participantID;
    surveyCell.participantCollection.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    return surveyCell;
    
}

- (NSInteger)_participantIDForSurveyView:(UICollectionView *)collectionView {
    
    HCRSurveyParticipantView *surveyView = (HCRSurveyParticipantView *)collectionView;
    NSParameterAssert([surveyView isKindOfClass:[HCRSurveyParticipantView class]]);
    
    return surveyView.participantID.integerValue;
    
}

- (HCRSurveyAnswerSetParticipantQuestion *)_currentParticipantQuestionForSection:(NSInteger)section {
    
    // get question code
    return [self.currentParticipant.questions objectAtIndex:section];
    
}

- (HCRSurveyAnswerSetParticipantQuestion *)_participantQuestionForSection:(NSInteger)section inCollectionView:(UICollectionView *)collectionView {
    
    // get question code
    NSInteger participantID = [self _participantIDForSurveyView:collectionView];
    return [[self.answerSet participantWithID:participantID].questions objectAtIndex:section];
    
}

- (HCRSurveyQuestion *)_surveyQuestionForSection:(NSInteger)section inCollectionView:(UICollectionView *)collectionView {
    
    HCRSurveyAnswerSetParticipantQuestion *question = [self _participantQuestionForSection:section inCollectionView:collectionView];
    return [[HCRDataManager sharedManager] surveyQuestionWithQuestionID:question.question];
    
}

- (NSString *)_questionStringForSection:(NSInteger)section inCollectionView:(UICollectionView *)collectionView {
    HCRSurveyQuestion *question = [self _surveyQuestionForSection:section inCollectionView:collectionView];
    NSString *questionNumber = question.questionCode;
    NSString *questionString = question.questionString;
    
    return [NSString stringWithFormat:@"%@: %@",questionNumber,questionString];
}

- (NSArray *)_answerIndexPathsForQuestion:(HCRSurveyQuestion *)question withParticipantResponse:(HCRSurveyAnswerSetParticipantQuestion *)response atSection:(NSInteger)section {
    
    NSMutableArray *indexPaths = @[].mutableCopy;
    
    for (HCRSurveyQuestionAnswer *answer in question.answers) {
        if (response && ![answer.code isEqualToNumber:response.answer]) {
            NSUInteger answerIndex = [question.answers indexOfObject:answer];
            NSIndexPath *deadIndexPath = [NSIndexPath indexPathForRow:answerIndex inSection:section];
            [indexPaths addObject:deadIndexPath];
        }
    }
    
    return indexPaths;
    
}

- (void)_updateCollectionView:(UICollectionView *)collectionView withOldQuestions:(NSArray *)oldQuestions {
    
    NSMutableIndexSet *indexesToDelete = [NSIndexSet indexSet].mutableCopy;
    NSMutableIndexSet *indexesToAdd = [NSIndexSet indexSet].mutableCopy;
    
    NSMutableArray *oldQuestionCodes = @[].mutableCopy;
    
    for (HCRSurveyAnswerSetParticipantQuestion *question in oldQuestions) {
        [oldQuestionCodes addObject:question.question];
    }
    
    // for all section questions, check if the participant has them
    for (NSString *questionCode in oldQuestionCodes) {
        
        // if not, add to delete
        if (![self.currentParticipant questionWithID:questionCode]) {
            [indexesToDelete addIndex:[oldQuestionCodes indexOfObject:questionCode]];
        }
        
    }
    
    // for all participant questions, check if section has them
    for (HCRSurveyAnswerSetParticipantQuestion *question in self.currentParticipant.questions) {
        
        // if not, add
        if (![oldQuestionCodes containsObject:question.question]) {
            [indexesToAdd addIndex:[self.currentParticipant.questions indexOfObject:question]];
        }
        
    }
    
    [collectionView deleteSections:indexesToDelete];
    [collectionView insertSections:indexesToAdd];
    
}

- (void)_surveyAnswerCellPressedInCollectionView:(UICollectionView *)collectionView AtIndexPath:(NSIndexPath *)indexPath withFreeformAnswer:(NSString *)freeformString {
    
    if (!self.selectingCell) {
		// get question values from our model
        HCRCollectionCell *answerCell = (HCRCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
        NSParameterAssert([answerCell isKindOfClass:[HCRCollectionCell class]]);
        
        // get question and answer codes
        HCRSurveyQuestion *questionAnswered = [self _surveyQuestionForSection:indexPath.section inCollectionView:collectionView];
        NSString *questionCode = questionAnswered.questionCode;
		
		/*
			Hacky sanity check here so we disallow submissions when the groupmetadata has not been populated
			(since this breaks the UICollectionView's animations and causes a crash
		*/
		if ([questionAnswered.questionCode  isEqual: @"0"])
		{
			bool isMetaDataPopulated = [[HCRDataManager sharedManager] isSurveyMetaDataPopulatedForAnswerSetID:self.answerSetID];
			if (!isMetaDataPopulated)
			{
				[UIAlertView showWithTitle:@"Metadata missing!" message:@"Please complete questions _0, _1, _2 (survey group, team and location), before filling in the consent form." handler:nil];
				return;
			}
		}
		
        // set UI
        self.selectingCell = YES;
        answerCell.processingAction = YES;
        
        NSInteger participantID = [self _participantIDForSurveyView:collectionView];
        NSArray *oldQuestions = [[self.answerSet participantWithID:participantID].questions copy];
        
        // if answer already exists, unset it and reload info
        HCRSurveyAnswerSetParticipantQuestion *question = [self _participantQuestionForSection:indexPath.section inCollectionView:collectionView];
        
        // get answer - by code if it's an existing answer, or by index if it's fresh
        HCRSurveyQuestionAnswer *answer = (question.answer) ? [questionAnswered answerForAnswerCode:question.answer] : [questionAnswered.answers objectAtIndex:indexPath.row];
		
//#define __MSF_SURVEY_VIEW_MT

        if (!freeformString &&
            (question.answer || question.answerString || answer.freeform.boolValue)) {

#ifndef __MSF_SURVEY_VIEW_MT
			[[HCRDataManager sharedManager] removeAnswerForQuestion:questionCode withAnswerSetID:self.answerSetID withParticipantID:participantID];
			[self _refreshModelDataForCollectionView:collectionView];
			[collectionView reloadData];
			self.selectingCell = NO;
			answerCell.processingAction = NO;
#else
			
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            dispatch_async(queue, ^{
                
                // background code
                
                // if the cells are non-standard, reset 'em..
                NSArray *indexPathsToAdd;
                if ([collectionView numberOfItemsInSection:indexPath.section] != questionAnswered.answers.count) {
                    
                    indexPathsToAdd = [self _answerIndexPathsForQuestion:questionAnswered
                                                 withParticipantResponse:question
                                                               atSection:indexPath.section];
                    
                }
				
				/*
					Harris:
					This section of the code is pretty bad. The number of index paths (answer views) to add is calculated first. Then, in the original version, the model for the view is updated, increasing the corresponding number of paths to its intended target (e.g. a question has 4 answers. At this point, indextPathsToAdd = 3 and the call to removeAnswerToQuestion would result in further calls to numberOfItemsInSection for the collectionView to return 4. Consequently, this would result in an internal consistency error for the view crashing. In order to fix this as a workaround, I've moved the model updating code to the end of the layout operation.
				*/
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // completion code (update UI, etc)
                    [self _reloadLayoutData:YES
                                 inSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                         withCollectionView:collectionView
                                   animated:NO
                          withLayoutChanges:^{
							  
						  //NSLog(@"%d",[collectionView numberOfItemsInSection:indexPath.section]);
						  [collectionView insertItemsAtIndexPaths:indexPathsToAdd];
						  
						  if ([collectionView numberOfSections] != [self.answerSet participantWithID:participantID].questions.count) {
							  [self _updateCollectionView:collectionView withOldQuestions:oldQuestions];
						  }
						  
						  self.selectingCell = NO;
						  answerCell.processingAction = NO;
							  
						// see comment right above about why this is implemented in this particular way
						[[HCRDataManager sharedManager] removeAnswerForQuestion:questionCode withAnswerSetID:self.answerSetID withParticipantID:participantID];
						[self _refreshModelDataForCollectionView:collectionView];
                          }];
                    
                });
                
            });
#endif
            
        } else {
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            dispatch_async(queue, ^{
                
                // background code
                [[HCRDataManager sharedManager] setAnswerCode:answer.code withFreeformString:freeformString forQuestion:questionCode withAnswerSetID:self.answerSetID withParticipantID:participantID];
                //NSLog([NSString stringWithFormat:@"%d-%d",indexPath.section,indexPath.row]);
                [self _refreshModelDataForCollectionView:collectionView];
				
				/*
					Kludge fix
					When submitting the consent question, the metadata questions get removed from the model by the _refreshModelDataForCollectionview
					call above. Consequently, the index path for the selection operation no longer corresponds with the state of the mdoel which is
					used during animations (the section is offset by 3 since the three metadata questions have been removed). We compensate for this
					by checking the question type and re-offseting the section.
				*/
				NSIndexPath* newIndexPath = indexPath;
				if ([questionCode isEqual:@"0"])
				{
#ifdef BEEKA_SURVEY
					NSInteger numMetadataQuestions = 3;
#else
					// Tripoli Survey
					NSInteger numMetadataQuestions = 2;
#endif
					newIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - (numMetadataQuestions + 1)];
				}
				
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // completion code (update UI, etc)
                    [self _reloadLayoutData:YES
                                 inSections:[NSIndexSet indexSetWithIndex:newIndexPath.section]
                         withCollectionView:collectionView
                                   animated:NO
                          withLayoutChanges:^{
                              
                              // if the cells appear normal, remove some
                              if ([collectionView numberOfItemsInSection:newIndexPath.section] == questionAnswered.answers.count) {
                                  
                                  NSArray *indexPathsToDelete = [self _answerIndexPathsForQuestion:questionAnswered
                                                                           withParticipantResponse:question
                                                                                         atSection:newIndexPath.section];
                                  
                                  [collectionView deleteItemsAtIndexPaths:indexPathsToDelete];
                                  
                              }
                              
                              if ([collectionView numberOfSections] != [self.answerSet participantWithID:participantID].questions.count) {
                                  [self _updateCollectionView:collectionView withOldQuestions:oldQuestions];
                              }
                              
                              if ([questionCode isEqualToString:@"0"]) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      NSIndexPath* targetIndexPath = [self _indexPathForCurrentParticipantFirstUnansweredQuestion];
									  
									  if (targetIndexPath)
									  {
										  [collectionView scrollToItemAtIndexPath:targetIndexPath
																 atScrollPosition:UICollectionViewScrollPositionCenteredVertically
																		 animated:YES];
                                      }
                                      [self _refreshToolbarData];
                                      
                                  });
                              }
                              
                              self.selectingCell = NO;
                              answerCell.processingAction = NO;
                              
                          }];
                    
                });
                
            });
            
        }
        
    }
    
}

- (void)_dismissKeyboard {
    [self.textFieldToDismiss resignFirstResponder];
    self.textFieldToDismiss = nil;
}

- (void)_updateAnswersCompleted:(BOOL)allAnswersComplete {
    
    if (!self.doneBarButton) {
        self.doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(_doneButtonPressed)];
    }
    
    if (!self.closeBarButton) {
		self.closeBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Exit" style:UIBarButtonItemStylePlain target:self action:@selector(_closeButtonPressed)];
    }
    
    UIBarButtonItem *rightItem = (allAnswersComplete) ? self.doneBarButton : nil;
    UIBarButtonItem *leftItem = self.closeBarButton;
    
    [self.navigationItem setRightBarButtonItem:rightItem animated:YES];
    [self.navigationItem setLeftBarButtonItem:leftItem animated:YES];
    
}

- (void)_updateCurrentParticipantWithActiveScrollView:(UIScrollView *)scrollView {
    
    // only do this for the core collectionview
    if ([scrollView isKindOfClass:[HCRSurveyParticipantView class]]) {
        return;
    }
    
    CGFloat width = CGRectGetWidth(scrollView.bounds);
    NSInteger page = (scrollView.contentOffset.x + 0.5 * width) / width;
    
    if (self.currentParticipant.participantID.integerValue != page) {
        self.currentParticipant = [self.answerSet.participants objectAtIndex:page];
    }
    
}

- (void)_toolbarParticipantPressed:(UIButton *)toolbarButton {
    
    if (self.currentParticipant) {
        
        [self _scrollToUnansweredQuestionForCurrentParticipant];
        
    }
    
}

- (NSIndexPath *)_indexPathForCurrentParticipantFirstUnansweredQuestion {
    
    HCRSurveyAnswerSetParticipantQuestion *unanasweredQuestion = [self.currentParticipant firstUnansweredQuestion];
    
    for (HCRSurveyAnswerSetParticipantQuestion *question in self.currentParticipant.questions) {
        if (question == unanasweredQuestion) {
            
            return [NSIndexPath indexPathForItem:0
                                       inSection:[self.currentParticipant.questions indexOfObject:question]];
            
        }
    }
    
    return nil;
}

- (HCRSurveyCell *)_surveyCellForCurrectParticipant {
    
    NSIndexPath *indexPathForSurvey =
    [NSIndexPath indexPathForItem:[self.answerSet.participants indexOfObject:self.currentParticipant]
                        inSection:0];
    
    HCRSurveyCell *survey = (HCRSurveyCell *)[self.collectionView cellForItemAtIndexPath:indexPathForSurvey];
    NSParameterAssert([survey isKindOfClass:[HCRSurveyCell class]]);
    
    return survey;
    
}

- (HCRSurveyAnswerSetParticipant *)_nextParticipantFromCurrentParticipant {
    
    NSInteger indexOfNextParticipant = [self.answerSet.participants indexOfObject:self.currentParticipant] + 1;
    
    if (indexOfNextParticipant <= self.answerSet.participants.count - 1) {
        return [self.answerSet.participants objectAtIndex:indexOfNextParticipant];
    } else {
        return nil;
    }
}

- (HCRSurveyAnswerSetParticipant *)_previousParticipantFromCurrentParticipant {
    
    NSInteger indexOfPreviousParticipant = [self.answerSet.participants indexOfObject:self.currentParticipant] - 1;
    
    if (indexOfPreviousParticipant >= 0) {
        return [self.answerSet.participants objectAtIndex:indexOfPreviousParticipant];
    } else {
        return nil;
    }
}

- (NSString *)_answerStringForCollectionView:(HCRSurveyParticipantView *)collectionView atIndexPath:(NSIndexPath *)indexPath {
    
    HCRSurveyQuestion *surveyQuestion = [self _surveyQuestionForSection:indexPath.section inCollectionView:collectionView];
    HCRSurveyAnswerSetParticipantQuestion *participantQuestion = [self _participantQuestionForSection:indexPath.section inCollectionView:collectionView];
    
    // get answer
    HCRSurveyQuestionAnswer *answer = [self _answerDataForSurveyQuestion:surveyQuestion withParticipantData:participantQuestion atIndexPath:indexPath];
    
    return (participantQuestion.answerString) ? participantQuestion.answerString : answer.string;
    
}

- (HCRSurveyQuestionAnswer *)_answerDataForSurveyQuestion:(HCRSurveyQuestion *)surveyQuestion withParticipantData:(HCRSurveyAnswerSetParticipantQuestion *)participantQuestion atIndexPath:(NSIndexPath *)indexPath {
    
    if (participantQuestion.answer) {
        // traditional answer
        return [surveyQuestion answerForAnswerCode:participantQuestion.answer];
    } else {
        // get answer for index
        NSParameterAssert(indexPath);
        NSArray *answerStrings = surveyQuestion.answers;
        return [answerStrings objectAtIndex:indexPath.row];
    }
}

- (void)_scrollToUnansweredQuestionForCurrentParticipant {
    
    NSIndexPath *indexPath = [self _indexPathForCurrentParticipantFirstUnansweredQuestion];
    
    if (indexPath) {
        
        HCRSurveyCell *surveyCell = [self _surveyCellForCurrectParticipant];
        
        [surveyCell.participantCollection scrollToItemAtIndexPath:indexPath
                                                 atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                                         animated:YES];
    }
    
}

@end
