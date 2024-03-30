//
//  PurrMainViewController.m
//  Purrpad
//
//  Created by Reza on 4/29/18.
//  Copyright © 2018 EccentricSolo. All rights reserved.
//
#import "PurrMainViewController.h"
#import "PurrCollectionViewCell.h"
#import "KLCPopup.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Note+CoreDataClass.h"
#import "AppDelegate.h"
@import CoreData;
typedef enum{
    BrightMode,DarkMode
}Theme;

@interface PurrMainViewController ()
{
    
    NSString* typingAnimationForBrightTheme;
    NSString* typingAnimationForDarkTheme;
    CAShapeLayer *textfieldBottomBorder;
    CGPoint pointVisibleForTypingMode;
    CGPoint pointVisibleForViewMode;
    CGPoint pointInvisibleForTypingView;
    CGFloat screenW;
    CGFloat screenH;
    CGFloat oneFifthOfTypingViewW;
    CGFloat vidW;
    CGFloat vidH;
    CGFloat vidX;
    CGFloat vidY;
    CGFloat TutorialImageViewW;
    CGFloat TutorialImageViewH;
    CGFloat sideKittyW;
    CGFloat sideKittyH;
    CGFloat topBGW;
    CGFloat topBGH;
    CGFloat aspectRatioForPurrpadTopBG;
    CGFloat doneBtnW;
    CGFloat doneBtnH;
    CGFloat containerViewW;
    CGFloat containerViewHForTypingMode;
    CGFloat containerViewHForViewMode;
    CGFloat typingViewHForTypingMode;
    CGFloat typingViewHForViewMode;
    CGFloat textViewW;
    CGFloat textViewHForTypingMode;
    CGFloat textViewHForViewMode;
    CGFloat textViewY;
    CGFloat textFieldW;
    CGFloat textFieldH;
    CGFloat textFieldY;
    CGFloat PleaseAddPurrImgVWidth;
    CGFloat PleaseAddPurrImgVHeight;
    CGFloat keyboardHeightSize;
    CGFloat cellInsets;
    CGFloat cellWidth;
    CGFloat cellHeight;
    CGFloat cellLabelW;
    CGFloat cellLabelH;
    CGFloat cellLabelX;
    CGFloat cellLabelY;
    CGFloat cellTextViewH;
    CGFloat cellTextViewY;
    
    CGRect videoRect;
    NSNotificationCenter *notifCenterToStopTypingAnimForTextView;
    Boolean soundsAreAllowed;
    Boolean canDismissTheTypingViewBecauseNoteHasATitle;
    Boolean typingMode;

    NSUserDefaults *settingUserDefault;
    NSUserDefaults * keyboardHeightUserDefaults;
    Theme themeMode;
}
@property (assign) Boolean isCollectionViewEmpty;
@property (strong, nonatomic) NSTimer * timerToStopTypingAnimForTextField;
@property (strong, nonatomic) UIButton * doneButton;
@property (strong, nonatomic) UIButton * cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *addNoteBtn;
@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
@property (weak, nonatomic) IBOutlet UIButton *soundBtn;
@property (weak, nonatomic) IBOutlet UIButton *themeBtn;
@property (weak, nonatomic) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UICollectionView *purrCV;
@property (nonatomic,strong) KLCPopup * aboutPurrpadPopup;
@property (nonatomic,strong) UIView * aboutView;
@property (nonatomic,strong) UIImageView* aboutViewDevImgV;
@property (nonatomic,strong) UIImageView* aboutViewKittyImgV;
@property (nonatomic,strong) UITextView * sideKittyTxtView;
@property (nonatomic,strong) UITextView * aboutDevTxtView;
@property (nonatomic,strong) UIButton * aboutDevLinkedInBtn;
@property (nonatomic,strong) UIImageView *sideKittyImgView;
@property (nonatomic,strong) NSIndexPath *selectedNote;
@property (nonatomic,strong) NSIndexPath *indexOfOpenedNote;
@property (nonatomic,strong) UIView *pleaseAddAPurrView;
@property (nonatomic,strong) UIImageView *pleaseAddAPurrImageView;
@property (nonatomic,strong) UIImageView *typingViewTopBGImgView;
@property (nonatomic,strong) UIView *containerViewforTypingViewAndImageview;
@property (nonatomic,strong) UIView *typingView;
@property (nonatomic,strong) UITextField *textField;
@property (nonatomic,strong) UITextView *textView;
@property (nonatomic) AVPlayer *vidPlayer;
@property (nonatomic) AVPlayerLayer *videoLayer;
@property (nonatomic) AVPlayerItem * player;
@property (strong, nonatomic) AVAudioPlayer *doneBtnAudioPlayer;
@property (strong, nonatomic) AVAudioPlayer *cancelBtnAudioPlayer;
@property (strong, nonatomic) AVAudioPlayer *AddBtnAudioPlayer;
@property (strong, nonatomic) AVAudioPlayer *SideKitty1BtnAudioPlayer;
@property (strong, nonatomic) AVAudioPlayer *SideKitty2BAudioPlayer;
@property (nonatomic) NSManagedObjectContext*context;
@property (nonatomic) NSArray <Note*>* notesTempArrayToBeSorted;
@property (nonatomic) NSArray <Note*>* notesArray;
@property (nonatomic,weak) AppDelegate* delegate;
@property(readwrite, nonatomic) CGFloat angle;
@property(readwrite, nonatomic) CGFloat magnitude;
@end

@implementation PurrMainViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    screenW =[UIScreen mainScreen].bounds.size.width;
    screenH =[UIScreen mainScreen].bounds.size.height;
    [self calculateSizesForAllViewsAndCells];

    // First thing that needs to be checked in starting this app is keyboard height.
    keyboardHeightUserDefaults = [NSUserDefaults standardUserDefaults];
    [self initializeSoundFileUrls];

    // Making coredata ready and then filling the array with notes from Purrpad.xcdatamodeld
    self.delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.context = self.delegate.persistentContainer.viewContext;
    
    [self fetchAllNotesFromFileAndFillTheNotesArray];
    
    // Initialization for CollectionView
    self.purrCV.dataSource = self;
    self.purrCV.delegate = self;
    [self.purrCV registerNib:[UINib nibWithNibName:@"PurrCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PurrCell"];
    
    UILongPressGestureRecognizer *llongpressGesturepgr
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongPress:)];
    llongpressGesturepgr.delegate = self;
    llongpressGesturepgr.delaysTouchesBegan = YES;
    [self.purrCV addGestureRecognizer:llongpressGesturepgr];

    self.typingViewTopBGImgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"thickBG"]];

    // Using this trick to give "Done button" two actions! if bool is Yes for "New Note" the done action
    // Will create a new note to Core Data but if BOOl is NO for "New Note" the done action will update the
    // note that is opened and modified. No by default its set to Yes.
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NewNote"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    settingUserDefault = [NSUserDefaults standardUserDefaults];
    notifCenterToStopTypingAnimForTextView = [NSNotificationCenter defaultCenter];
    
    // About View
    self.aboutView = [[UIView alloc] initWithFrame:CGRectMake(0,0,screenW*0.93, screenH*0.56)];
    self.aboutView.layer.cornerRadius = 15;
    self.aboutView.layer.borderWidth = 5.0;
    
    
    // SideKitty ImageView in about view
    self.aboutViewKittyImgV = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"SideKitty"]];
    [self.aboutView addSubview:self.aboutViewKittyImgV];
    [self.aboutViewKittyImgV setFrame:CGRectMake(self.aboutView.frame.size.width*0.8, 16, self.aboutView.frame.size.width*0.2, (self.aboutView.frame.size.width*0.2*2.052))];

    // SideKitty Texview in about view
    self.sideKittyTxtView = [[UITextView alloc]initWithFrame:
                             CGRectMake(16,
                                        16,
                                        self.aboutView.frame.size.width*0.7,
                                        self.aboutView.frame.size.height*0.55)];
    self.sideKittyTxtView.showsVerticalScrollIndicator=YES;
    [self.sideKittyTxtView flashScrollIndicators];
    [self.sideKittyTxtView setText:NSLocalizedString(@"ABOUT_KITTY",@"")];
    
    [self.sideKittyTxtView setFont:[UIFont fontWithName:@"Avenir-Light" size:17]];
    [self updateTextFont: self.sideKittyTxtView];
    self.sideKittyTxtView.textAlignment = NSTextAlignmentLeft;
    [self.sideKittyTxtView setBackgroundColor: [UIColor clearColor]];
    [self.sideKittyTxtView setEditable:NO];
    [self.aboutView addSubview:self.sideKittyTxtView];

    
    // Dev ImageView in about view
    self.aboutViewDevImgV = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"PixelRez"]];
    [self.aboutView addSubview:self.aboutViewDevImgV];
    [self.aboutViewDevImgV setFrame:
     CGRectMake(self.aboutView.frame.size.width*0.75 - 12,
                10+self.aboutView.frame.size.height*0.55,
                self.aboutView.frame.size.width*0.25,
                self.aboutView.frame.size.width*0.25)];

    // Dev Texview in about view
    self.aboutDevTxtView = [[UITextView alloc]initWithFrame:
      CGRectMake(16,
                 10+self.aboutView.frame.size.height*0.55,
                 self.aboutView.frame.size.width*0.7,
                 self.aboutView.frame.size.height*0.4)];
    self.aboutDevTxtView.showsVerticalScrollIndicator=YES;
    [self.aboutDevTxtView flashScrollIndicators];
   
    [self.aboutDevTxtView setText:NSLocalizedString(@"DEVELOPED_BY", nil)];
    self.aboutDevTxtView.selectable = YES;
    
    [self.aboutDevTxtView setFont:[UIFont fontWithName:@"Avenir-Black" size:14]];
    [self updateTextFont: self.aboutDevTxtView];
    self.aboutDevTxtView.textAlignment = NSTextAlignmentLeft;
    [self.aboutDevTxtView setBackgroundColor: [UIColor clearColor]];
    [self.aboutDevTxtView setEditable:NO];
    [self.aboutView addSubview:self.aboutDevTxtView];
    
    self.aboutDevLinkedInBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.aboutDevLinkedInBtn setFrame:CGRectMake(16,
                                                 10+self.aboutView.frame.size.height*0.55,
                                                 self.aboutView.frame.size.width*0.7,
                                                 self.aboutView.frame.size.height*0.4)];
    [self.aboutDevLinkedInBtn addTarget:self action:@selector(devBtnAction)
     forControlEvents:UIControlEventTouchUpInside];
    [self.aboutView addSubview:self.aboutDevLinkedInBtn];

    self.aboutPurrpadPopup  = [KLCPopup popupWithContentView:self.aboutView];
    
    self.pleaseAddAPurrView = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBar.frame.size.height,screenW,(screenH - self.topBar.frame.size.height))];
    
    // Please add purr ImageView
    self.pleaseAddAPurrImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"PleaseAddPurrBright"]];
    
    [self.pleaseAddAPurrView addSubview:self.pleaseAddAPurrImageView];
    [self.pleaseAddAPurrImageView setFrame:
     CGRectMake(screenW/2 - PleaseAddPurrImgVWidth/2,
                self.pleaseAddAPurrView.frame.size.height/2 - PleaseAddPurrImgVHeight/2,
                PleaseAddPurrImgVWidth,
                PleaseAddPurrImgVHeight)];
    
    [self.view addSubview:self.pleaseAddAPurrView];
    [self.view sendSubviewToBack:self.pleaseAddAPurrView];
    
    // animation file Path initialization
    typingAnimationForBrightTheme=[[NSBundle mainBundle] pathForResource:@"TypingAnimBright.mp4" ofType:nil inDirectory:@"TypingAnimations"];
    typingAnimationForDarkTheme=[[NSBundle mainBundle] pathForResource:@"TypingAnimDark.mp4" ofType:nil inDirectory:@"TypingAnimations"];
    [self.themeBtn setBackgroundImage:[UIImage imageNamed:@"Theme"] forState:UIControlStateNormal];
    
    // Checking to see if the app is launched for the first time and if so, sounds are allowed by default.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"AppHasLaunchedOnce"]){
        NSLog(@"First time run");
        [self.pleaseAddAPurrView setBackgroundColor:[UIColor colorWithRed:228.0/255.0 green:228.0/255.0 blue:228.0/255.0 alpha:1.0]];
        [self.pleaseAddAPurrImageView setImage:[UIImage imageNamed:NSLocalizedString(@"TAPTOADDNOTEBRIGHT_IMAGENAME", nil)]];
        
        self.purrCV.backgroundColor = [UIColor clearColor];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CollectionViewIsEmpty"];

        soundsAreAllowed = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Sounds"];
        [self.soundBtn setImage:[UIImage imageNamed:@"Unmute"] forState:(UIControlState)UIControlStateNormal];

        themeMode = BrightMode;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ThemeIsBright"];

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AppHasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        //Tutorial View
        UIView * tutorialView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenW*0.9, screenW*0.7)];
        [tutorialView setBackgroundColor:[UIColor colorWithRed:76.0/255.0 green:76.0/255.0 blue:76.0/255.0 alpha:1.0]];
        TutorialImageViewW = 0.756*tutorialView.frame.size.width;
        TutorialImageViewH = TutorialImageViewW;

        UIImageView* tutorImgV = [[UIImageView alloc]initWithImage:[UIImage imageNamed:NSLocalizedString(@"TUTORIAL_IMAGENAME", nil)]];

        [tutorImgV setFrame:CGRectMake(tutorialView.frame.size.width/2 -TutorialImageViewW/2, tutorialView.frame.size.height/2 -TutorialImageViewW/2, TutorialImageViewW, TutorialImageViewH)];
        [tutorialView addSubview:tutorImgV];
        tutorialView.layer.cornerRadius = 15;
        tutorialView.layer.borderWidth = 5.0;
        KLCPopup * tutorialPopup = [KLCPopup popupWithContentView:tutorialView];
        [tutorialPopup show];
        
        // We do this to take care of it later in AddNewNote and in TextfieldShouldBeginEditing.
        keyboardHeightSize=0;
    } else {
        // App has ran before so we can get the keyboard height from NSUserdefault.
        keyboardHeightSize = [keyboardHeightUserDefaults floatForKey:@"KeyboardHeight"];

        NSLog(@"------Second Run");
        //Sounds
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Sounds"]){
            NSLog(@"-> Sounds were enabled ");
            soundsAreAllowed =YES;
            [self.soundBtn setImage:[UIImage imageNamed:@"Unmute"] forState:(UIControlState)UIControlStateNormal];
        }else{
            NSLog(@"-> Sounds were NOT allowed ");
            soundsAreAllowed =NO;
            [self.soundBtn setImage:[UIImage imageNamed:@"Muted"] forState:(UIControlState)UIControlStateNormal];
        }

        // Theme
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ThemeIsBright"]){
            NSLog(@"-> Theme was Bright");
            themeMode = BrightMode;
            [self.pleaseAddAPurrImageView setImage:[UIImage imageNamed:NSLocalizedString(@"TAPTOADDNOTEBRIGHT_IMAGENAME", nil)]];
            [self.addNoteBtn setImage:[UIImage imageNamed:@"AddBtnBright"] forState:(UIControlState)UIControlStateNormal];
        }else{
            NSLog(@"-> Theme was Dark");
            themeMode = DarkMode;
            [self.pleaseAddAPurrImageView setImage:[UIImage imageNamed:NSLocalizedString(@"TAPTOADDNOTEDARK_IMAGENAME", nil)]];
            [self.addNoteBtn setImage:[UIImage imageNamed:@"AddBtnDark"] forState:(UIControlState)UIControlStateNormal];
        }
        
        // CollectionView and pleaseAddPurView
        [self handlePleaseTapThisToAddPurrAndHandleCollectionView];
    }
    [self calculateSizesForAllViewsAndCells];
    [self initializeTypingViewForTypingMode];
    typingMode = NO;

    // Size of the keyboard when its showing.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
}
- (void)updateTextFont:(UITextView *)textView{
    // Only run if has text, otherwise it will make infinity loop
    if (textView.text.length == 0 || CGSizeEqualToSize(textView.bounds.size, CGSizeZero)) return;
    
    CGSize textViewSize = textView.frame.size;
    CGFloat fixedWidth = textViewSize.width;
    CGSize expectSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    
    UIFont *expectFont = textView.font;
    if (expectSize.height > textViewSize.height) {
        while ([textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)].height > textViewSize.height) {
            expectFont = [textView.font fontWithSize:(textView.font.pointSize-1)];
            textView.font = expectFont;
        }
    } else {
        while ([textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)].height < textViewSize.height) {
            expectFont = textView.font;
            textView.font = [textView.font fontWithSize:(textView.font.pointSize+1)];
        }
        textView.font = expectFont;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)fetchAllNotesFromFileAndFillTheNotesArray{
    NSFetchRequest * fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    self.notesTempArrayToBeSorted =  [self.context executeFetchRequest:fetchRequest error:nil];
    self.notesArray = [NSMutableArray arrayWithArray:[[self.notesTempArrayToBeSorted reverseObjectEnumerator] allObjects]];
}

-(void)handlePleaseTapThisToAddPurrAndHandleCollectionView{
    
    if (self.notesArray.count==0){
        self.purrCV.backgroundColor = [UIColor clearColor];
        
        if (themeMode==DarkMode){
            [self.pleaseAddAPurrView setBackgroundColor:[UIColor colorWithRed:91.0/255.0  green:81.0/255.0  blue:84.0/255.0 alpha:1.0]];

            [self.pleaseAddAPurrImageView setImage:[UIImage imageNamed:NSLocalizedString(@"TAPTOADDNOTEDARK_IMAGENAME", nil)]];
        }else{
            [self.pleaseAddAPurrView setBackgroundColor:[UIColor colorWithRed:228.0/255.0 green:228.0/255.0 blue:228.0/255.0 alpha:1.0]];
            [self.pleaseAddAPurrImageView setImage:[UIImage imageNamed:NSLocalizedString(@"TAPTOADDNOTEBRIGHT_IMAGENAME", nil)]];
        }
        [self.pleaseAddAPurrView setHidden:NO];
    }else{
        [self.pleaseAddAPurrView setHidden:YES];
        
        if (themeMode==DarkMode) {
            self.purrCV.backgroundColor = [UIColor colorWithRed:91.0/255.0  green:81.0/255.0  blue:84.0/255.0 alpha:1.0];
            self.view.backgroundColor =[UIColor colorWithRed:91.0/255.0  green:81.0/255.0  blue:84.0/255.0 alpha:1.0];
        }else{
            self.purrCV.backgroundColor= [UIColor colorWithRed:228.0/255.0 green:228.0/255.0 blue:228.0/255.0 alpha:1.0];
            self.view.backgroundColor =[UIColor colorWithRed:228.0/255.0 green:228.0/255.0 blue:228.0/255.0 alpha:1.0];
        }
    }
    [self.purrCV reloadData];
}

- (IBAction)soundBtnAction:(id)sender {
    if (!soundsAreAllowed){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Sounds"];
        soundsAreAllowed =YES;
        [self.soundBtn setImage:[UIImage imageNamed:@"Unmute"] forState:(UIControlState)UIControlStateNormal];
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Sounds"];
        soundsAreAllowed =NO;
        [self.soundBtn setImage:[UIImage imageNamed:@"Muted"] forState:(UIControlState)UIControlStateNormal];
    }
}

- (IBAction)themeBtnAction:(id)sender {
    if (themeMode==DarkMode){
        themeMode = BrightMode;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ThemeIsBright"];
        [self.addNoteBtn setImage:[UIImage imageNamed:@"AddBtnBright"] forState:(UIControlState)UIControlStateNormal];
        
        [self.pleaseAddAPurrImageView setImage:[UIImage imageNamed:NSLocalizedString(@"TAPTOADDNOTEBRIGHT_IMAGENAME", nil)]];
    }else{
        themeMode = DarkMode;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ThemeIsBright"];
        [self.addNoteBtn setImage:[UIImage imageNamed:@"AddBtnDark"] forState:(UIControlState)UIControlStateNormal];
        
        [self.pleaseAddAPurrImageView setImage:[UIImage imageNamed:NSLocalizedString(@"TAPTOADDNOTEDARK_IMAGENAME", nil)]];
    }
    [self manageThemes];
}

- (IBAction)aboutPurrpadAction:(id)sender {
    [self.aboutPurrpadPopup show];
}
- (IBAction)addNewNoteAction:(id)sender {
    if (keyboardHeightSize<220) {
        NSLog(@"1. AddNewNote -> Height UNKNOWN");
        [self.textField becomeFirstResponder];
    }else{
        [self.addNoteBtn setEnabled:NO];
        canDismissTheTypingViewBecauseNoteHasATitle=NO;
        if (soundsAreAllowed) {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self.AddBtnAudioPlayer play];
            });
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NewNote"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.textField.text = @"";
        self.textView.text = @"";
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveLinear animations:^{
            [self.doneButton   setEnabled:YES];
            [self.doneButton   setHidden:NO];
            [self.videoLayer   setHidden:NO];
            [self.containerViewforTypingViewAndImageview setFrame:
             CGRectMake((self->screenW/2)-(self->containerViewW/2),
                        self->screenH/22,
                        self->containerViewW,
                        self->containerViewHForTypingMode)];
            
            [self.typingView setFrame:
             CGRectMake(0,
                        (self->topBGH/2)-5,
                        self->containerViewW,
                        self->typingViewHForTypingMode)];
            
            [self.textView setFrame:CGRectMake(16,self->textViewY,self->textViewW,self->textViewHForTypingMode)];
            
            [self.cancelButton setFrame:CGRectMake(8,self->typingViewHForTypingMode - (8+self->doneBtnH),self->doneBtnW,self->doneBtnH)];
        } completion:^(BOOL finished) {
            self->typingMode=YES;
        }];
        [self.textField becomeFirstResponder];
    }
}

-(void)cancelAction{
    if (soundsAreAllowed) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self.cancelBtnAudioPlayer play];
        });
    }
 
    [self.textField setText:@""];
    [self.textView setText:@""];
    [self.addNoteBtn setEnabled:YES];
    
    //Moving containerViewout of screen
    [UIView animateWithDuration:0.3 animations:^{
        [self.containerViewforTypingViewAndImageview setFrame:
         CGRectMake((self->screenW/2)-(self->containerViewW/2),
                    self->screenH,
                    self->containerViewW,
                    self->containerViewHForTypingMode)];
        
        [self.typingView setFrame:
         CGRectMake(0,
                    (self->topBGH/2)-5,
                    self->containerViewW,
                    self->typingViewHForTypingMode)];
        
        [self.textView setFrame:CGRectMake(16,self->textViewY,self->textViewW,self->textViewHForTypingMode)];
        
        [self.cancelButton setFrame:CGRectMake(8,self->typingViewHForTypingMode - (8+self->doneBtnH),self->doneBtnW,self->doneBtnH)];
        
        
    } completion:^(BOOL finished) {
        [self.doneButton setEnabled:YES];
        [self.doneButton setHidden:NO];
        [self.videoLayer setHidden:NO];
    }];
    typingMode=NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
    });
 }
-(void)doneAction{
    if (soundsAreAllowed) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self.doneBtnAudioPlayer play];
        });
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"NewNote"]){
        Note * newNote = [[Note alloc]initWithContext:self.context];
        
        if ([self.textField hasText]) {
            NSString * title = self.textField.text;
            newNote.title = title;
            canDismissTheTypingViewBecauseNoteHasATitle = YES;
        } else {
   
            // get the cell at indexPath (the one you long pressed)
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:NSLocalizedString(@"OOPS",nil)
                                         message:NSLocalizedString(@"WHERE_IS_THE_TITLE",nil)
                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:NSLocalizedString(@"OK",nil)
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            
                                        }];
            [alert addAction:yesButton];
            [self presentViewController:alert animated:YES completion:nil];
            canDismissTheTypingViewBecauseNoteHasATitle = NO;
        }
        
        if ([self.textView  hasText]) {
            NSString * body = self.textView.text;
            newNote.body = body;
        } else {
            //Show Alert that your text has no title!!!!
        }
    } else {
        // It's NOT a New Note! done button will update this note because it was existing!!
        Note * updatingNote = self.notesArray[self.indexOfOpenedNote.row];
        
        if ([self.textField hasText]) {
            updatingNote.title = self.textField.text;
            canDismissTheTypingViewBecauseNoteHasATitle = YES;
        } else {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                //Show Alert that your text has no title!!!!
                // get the cell at indexPath (the one you long pressed)
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:NSLocalizedString(@"OOPS",nil)
                                             message:NSLocalizedString(@"WHERE_IS_THE_TITLE",nil)
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* yesButton = [UIAlertAction
                                            actionWithTitle:NSLocalizedString(@"OK",nil)
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                
                                            }];
                [alert addAction:yesButton];
                [self presentViewController:alert animated:YES completion:nil];
                
            });
            canDismissTheTypingViewBecauseNoteHasATitle = NO;
        }
        
        if ([self.textView  hasText]) {
            updatingNote.body = self.textView.text;
        }else{
            //Show Alert that your text has no title!!!!
        }
    }
    if (canDismissTheTypingViewBecauseNoteHasATitle){
        [self.delegate saveContext];
        [self.textField setText:@""];
        [self.textView setText:@""];
        [self.addNoteBtn setEnabled:YES];
        [self fetchAllNotesFromFileAndFillTheNotesArray];
        [self handlePleaseTapThisToAddPurrAndHandleCollectionView];
        
        // Moving containerViewout of screen
        [UIView animateWithDuration:0.6 animations:^{
            [self.containerViewforTypingViewAndImageview setFrame:
             CGRectMake((self->screenW/2)-(self->containerViewW/2),
                        self->screenH,
                        self->containerViewW,
                        self->containerViewHForTypingMode)];
            
            [self.typingView setFrame:
             CGRectMake(0,
                        (self->topBGH/2)-5,
                        self->containerViewW,
                        self->typingViewHForTypingMode)];
            
            [self.textView setFrame:CGRectMake(16,self->textViewY,self->textViewW,self->textViewHForTypingMode)];
            
            [self.cancelButton setFrame:CGRectMake(8,self->typingViewHForTypingMode - (8+self->doneBtnH),self->doneBtnW,self->doneBtnH)];
        
        } completion:^(BOOL finished) {
            [self.doneButton   setEnabled:YES];
            [self.doneButton   setHidden:NO];
            [self.videoLayer   setHidden:NO];
        }];
        typingMode=NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
        });
    }
}
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gestureRecognizer locationInView:self.purrCV];
        NSIndexPath *indexPath = [self.purrCV indexPathForItemAtPoint:p];
        if (indexPath == nil){
            NSLog(@"Couldn't find index path");
        } else {
            // get the cell at indexPath (the one you long pressed)
            UIAlertController * alert = [UIAlertController
                                         //  alertControllerWithTitle:@"Are you sure you want to delete this note?"
                                         alertControllerWithTitle:NSLocalizedString(@"DELETE_TITLE",nil)
                                         message: NSLocalizedString(@"MEOW_MEOW_MEOW",nil)
                                         preferredStyle: UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle: NSLocalizedString(@"DELETE", nil)
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            //Handle your yes please button action here
                                            // Show alert ARE YOU SURE YOU WANT TO DELETE THIS NOTE?
                                            Note*note = self.notesArray[indexPath.row];
                                            [self.context deleteObject:note];
                                            [self.delegate saveContext];
                                            [self fetchAllNotesFromFileAndFillTheNotesArray];
                                            [self handlePleaseTapThisToAddPurrAndHandleCollectionView];
                                        }];
            UIAlertAction* noButton = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"CANCEL", nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           //Handle no, thanks button
                                           [self cancelAction];
                                       }];
            [alert addAction:yesButton];
            [alert addAction:noButton];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}
-(void)devBtnAction{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://linkedin.com/in/rezaabdolahi/"] options:@{} completionHandler:nil];
}

//CollectionView & CollectionViewCell Methods/////////////////////////////////
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    PurrCollectionViewCell *purrCVCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PurrCell" forIndexPath:indexPath];
    Note * note = self.notesArray[indexPath.row];
    
    // Cell's Label
    [purrCVCell.purrLabel setText:[note.title uppercaseString]];
    purrCVCell.purrLabel.backgroundColor = [UIColor clearColor];
    purrCVCell.purrLabel.adjustsFontSizeToFitWidth = YES;
    purrCVCell.purrLabel.numberOfLines = 1;
    purrCVCell.purrLabel.minimumScaleFactor = 1;
    [purrCVCell.purrLabel setFont:[UIFont fontWithName:@"AvenirNext-Bold" size:purrCVCell.purrLabel.font.pointSize]];
    purrCVCell.purrLabel.translatesAutoresizingMaskIntoConstraints = YES;
    [purrCVCell.purrLabel setFrame:CGRectMake(cellLabelX, cellLabelY, cellLabelW, cellLabelH)];

    // Cell's Textview
    purrCVCell.purrTextView.text = note.body;
    purrCVCell.purrTextView.backgroundColor = [UIColor clearColor];
    purrCVCell.purrTextView.translatesAutoresizingMaskIntoConstraints = YES;
    [purrCVCell.purrTextView setFrame:CGRectMake(cellLabelX, cellTextViewY, cellLabelW, cellTextViewH)];
    purrCVCell.purrTextView.userInteractionEnabled = NO;
    purrCVCell.purrTextView.editable = NO;
    [purrCVCell.purrTextView setSelectable:NO];
    [self updateTextFont:purrCVCell.purrTextView];

    if (themeMode == DarkMode) {
        [purrCVCell.cellBGImageView setImage:[UIImage imageNamed:@"DarkThemeCellBG"]];
        
        [purrCVCell.purrLabel setTextColor:[UIColor colorWithRed:91.0/255.0  green:81.0/255.0  blue:84.0/255.0 alpha:1.0]];
        
        [purrCVCell.purrTextView setTextColor:[UIColor colorWithRed:91.0/255.0  green:81.0/255.0  blue:84.0/255.0 alpha:1.0]];
        [purrCVCell.purrTextView setFont:[UIFont fontWithName:@"AvenirNext-Bold" size:15.0]];
    }else{
        [purrCVCell.cellBGImageView setImage:[UIImage imageNamed:@"BrightThemeCell"]];

        [purrCVCell.purrLabel setTextColor:[UIColor colorWithRed:228.0/255.0  green:228.0/255.0  blue:228.0/255.0 alpha:1.0]];

        [purrCVCell.purrTextView setTextColor:[UIColor colorWithRed:228.0/255.0  green:228.0/255.0  blue:228.0/255.0 alpha:1.0]];
        [purrCVCell.purrTextView setFont:[UIFont fontWithName:@"AvenirNext-Bold" size:15.0]];
    }
    
    // Adding border for cell label
    CAShapeLayer * LabelBorder = [CAShapeLayer layer];
    LabelBorder.fillColor = nil;
    LabelBorder.lineDashPattern = @[@6,@6];
    LabelBorder.borderWidth = 4.0;
    
    if (themeMode == DarkMode) {
        LabelBorder.strokeColor = [UIColor colorWithRed:69.0/255.0 green:136.0/255.0 blue:244.0/255.0 alpha:1.0].CGColor;
    } else {
        LabelBorder.strokeColor = [UIColor colorWithRed:235.0/255.0 green:54.0/255.0 blue:116.0/255.0 alpha:1.0].CGColor;
    }
    UIBezierPath * aPath = [UIBezierPath bezierPath];
    [aPath moveToPoint:CGPointMake(0,(cellLabelH))];
    [aPath addLineToPoint:CGPointMake(cellLabelW,(cellLabelH))];
    LabelBorder.path =aPath.CGPath;
    [purrCVCell.purrLabel.layer addSublayer:LabelBorder];
    return purrCVCell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //Setting BOOL to NO for New note since it was previously created so "Done Button" will only update
    //the existing note in core data instead of creating a new one. (read viewdid load for more info)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NewNote"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.addNoteBtn setEnabled:NO];

    self.indexOfOpenedNote = indexPath;
    Note *note =self.notesArray[indexPath.row];
    self.textField.text = note.title;
    self.textView.text = note.body;
    
    if (soundsAreAllowed) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self.AddBtnAudioPlayer play];
        });
    }
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.doneButton   setEnabled:NO];
        [self.doneButton   setHidden:YES];
        [self.videoLayer   setHidden:YES];
        [self.containerViewforTypingViewAndImageview setFrame:
             CGRectMake((self->screenW/2-self->containerViewW/2),
                        40,
                        self->containerViewW,
                        self->containerViewHForViewMode)];
            [self.typingView setFrame:
             CGRectMake(0,
                        (self->topBGH/2)-5,
                        self->containerViewW,
                        self->typingViewHForViewMode)];
        
            [self.textView setFrame:CGRectMake(16,self->textViewY,self->textViewW,self->textViewHForViewMode)];
            [self.cancelButton setFrame:CGRectMake(8,self->typingViewHForViewMode - (8+self->doneBtnH),self->doneBtnW,self->doneBtnH)];
        
        } completion:^(BOOL finished) {
        }];
        typingMode=NO;
}
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    
    if (!typingMode){
        //Typing Mode
        [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.9 options:UIViewAnimationOptionCurveLinear animations:^{
            [self.containerViewforTypingViewAndImageview setFrame:
             CGRectMake((self->screenW/2)-(self->containerViewW/2),
                        self->screenH/22,
                        self->containerViewW,
                        self->containerViewHForTypingMode)];
            
            [self.typingView setFrame:
             CGRectMake(0,
                        (self->topBGH/2)-5,
                        self->containerViewW,
                        self->typingViewHForTypingMode)];
            
            [self.textView setFrame:CGRectMake(16,self->textViewY,self->textViewW,self->textViewHForTypingMode)];
            
            [self.cancelButton setFrame:CGRectMake(8,self->typingViewHForTypingMode - (8+self->doneBtnH),self->doneBtnW,self->doneBtnH)];
            
        } completion:^(BOOL finished) {
            [self.doneButton   setEnabled:YES];
            [self.doneButton   setHidden:NO];
            [self.videoLayer   setHidden:NO];
            self->typingMode=YES;
        }];
    }
    return YES;
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (keyboardHeightSize< 220){
        //Now by doing this for the first time, it will call KeyboardDidShow and then the height is taken and stored by NSUserdefault.
        return YES;
    }else{
        NSLog(@"6. textFieldShouldBegin -> %f",keyboardHeightSize);

        if (!typingMode){
            //Typing Mode
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.9 options:UIViewAnimationOptionCurveLinear animations:^{
                [self.containerViewforTypingViewAndImageview setFrame:
                 CGRectMake((self->screenW/2)-(self->containerViewW/2),
                            self->screenH/22,
                            self->containerViewW,
                            self->containerViewHForTypingMode)];
                
                [self.typingView setFrame:
                 CGRectMake(0,
                            (self->topBGH/2)-5,
                            self->containerViewW,
                            self->typingViewHForTypingMode)];
                
                [self.textView setFrame:CGRectMake(16,self->textViewY,self->textViewW,self->textViewHForTypingMode)];
                
                [self.cancelButton setFrame:CGRectMake(8,self->typingViewHForTypingMode - (8+self->doneBtnH),self->doneBtnW,self->doneBtnH)];
                
            } completion:^(BOOL finished) {
                [self.doneButton   setEnabled:YES];
                [self.doneButton   setHidden:NO];
                [self.videoLayer   setHidden:NO];
                self->typingMode=YES;
            }];
        }
        return YES;
    }
}
 
 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection{
     [super traitCollectionDidChange:previousTraitCollection];
     [self.purrCV reloadData];}
 - (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
     return 1;}
 - (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
     return self.notesArray.count;}
 - (NSUInteger)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout numberOfColumnsInSection:(NSUInteger)section{
     return 2;}
 - (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
     return UIEdgeInsetsMake(cellInsets, cellInsets, cellInsets, cellInsets);
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    //This method and the one above this is necessary.
    return cellInsets;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;{
    CGSize defaultSize = CGSizeMake(cellWidth, cellHeight);
    return defaultSize;
}

// START / STOP THE TYPING ANIMATION USING AVPlayer/////////
-(void)startTypingAnimation{
    if (soundsAreAllowed){
        [self.vidPlayer play];
        [self.vidPlayer setRate:0.8];
        //Play the sounds too
    }else{
        [self.vidPlayer play];
        [self.vidPlayer setRate:0.8];
    }
}
- (void)stopTheTypingAnimation{
    [self.vidPlayer pause];
    [self.vidPlayer seekToTime:CMTimeMake(0, 1)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.vidPlayer currentItem]];
}
- (void)itemDidFinishPlaying:(NSNotification *)notification {
    self.player = [notification object];
    [self.player seekToTime:kCMTimeZero];
}

// DETECTING WHEN USER STARTS/STOPS TYPING TO START/STOP THE TYPING ANIMATION FOR UITEXTFIELD //
// Starting the typing animation for UITEXTFIELD

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [self startTypingAnimation];
    return YES;
}
-(void)textFieldDidChange :(UITextField *)textField{
    // if a timer is already active, prevent it from firing
    if (self.timerToStopTypingAnimForTextField != nil) {
        [self.timerToStopTypingAnimForTextField invalidate];
        self.timerToStopTypingAnimForTextField = nil;
    }
    // reschedule the search: in 0.7 second, call the searchForKeyword: method on the new textfield content
    self.timerToStopTypingAnimForTextField = [NSTimer scheduledTimerWithTimeInterval: 0.7
                                                        target: self
                                                      selector: @selector(stopTheTypingAnimation)
                                                      userInfo: nil
                                                       repeats: NO];
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    [self startTypingAnimation];
    return YES;
}
- (void)textViewText:(id)notification {
    // if a timer is already active, prevent it from firing
    if (self.timerToStopTypingAnimForTextField != nil) {
        [self.timerToStopTypingAnimForTextField invalidate];
        self.timerToStopTypingAnimForTextField = nil;
    }
    // reschedule the search: in 0.7 second, call the searchForKeyword: method on the new textfield content
    self.timerToStopTypingAnimForTextField = [NSTimer scheduledTimerWithTimeInterval: 0.7
                                                        target: self
                                                      selector: @selector(stopTheTypingAnimation)
                                                      userInfo: nil
                                                       repeats: NO];
}

-(void)calculateSizesForAllViewsAndCells{
    aspectRatioForPurrpadTopBG = 6.9;
    
    // ContainerView contains typingView and imageView above it.
    containerViewW = 0.9*screenW;
    containerViewHForTypingMode = (screenH - (keyboardHeightSize+(screenH/11)));
 
    containerViewHForViewMode = 0.8*screenH;
    oneFifthOfTypingViewW = (containerViewW - (4*8))/5;

    topBGW = (containerViewW*0.85);
    topBGH = (topBGW/6.9);
    
    // TypingView contains textfield and textview and done button and cancel button.
    typingViewHForTypingMode = (containerViewHForTypingMode - (topBGH/2));
    typingViewHForViewMode   = (containerViewHForViewMode   - (topBGH/2));
    
    // Aspect ratio (H/W): 1.26
    cellInsets = 0.069*screenW;
    cellWidth  = ((screenW/2) - (1.5*cellInsets));
    cellHeight = cellWidth*1.26;
    cellLabelX = 0.12 * cellWidth;
    cellLabelY = 0.153* cellHeight;
    cellLabelW = 0.77 * cellWidth;
    cellLabelH = 0.215* cellHeight;
    cellTextViewH = 0.5*cellHeight;
    cellTextViewY = (cellLabelY+cellLabelH);
    
    doneBtnW = oneFifthOfTypingViewW;
    doneBtnH = doneBtnW/2.13;
    textFieldW = (containerViewW-32);
    textFieldH = containerViewHForTypingMode/10;
    textFieldY = (20+topBGH/2);
    
    vidW = (3*oneFifthOfTypingViewW);
    vidH =  0.411 * vidW;
    vidX = (containerViewW/2 - vidW/2);
    vidY = typingViewHForTypingMode - (vidH+4);
    
    textViewW = (containerViewW-32);
    textViewY = (textFieldY + textFieldH);
    
    textViewHForTypingMode = (typingViewHForTypingMode - (textViewY + vidH +16));
    textViewHForViewMode   = (typingViewHForViewMode   - (textViewY + doneBtnH +16));

    PleaseAddPurrImgVWidth= (0.746 * screenW);
    PleaseAddPurrImgVHeight= (PleaseAddPurrImgVWidth/5.43);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)manageThemes{
    
    if (themeMode == DarkMode){
        _topBar.backgroundColor= [UIColor colorWithRed:100.0/255.0 green:181.0/255.0 blue:246.0/255.0 alpha:1.0];
        
        if (self.notesArray.count!=0) {
            self.purrCV.backgroundColor = [UIColor colorWithRed:91.0/255.0 green:81.0/255.0 blue:84.0/255.0 alpha:1.0];
        } else {
            self.purrCV.backgroundColor = [UIColor clearColor];
            [self.pleaseAddAPurrView setBackgroundColor:[UIColor colorWithRed:76.0/255.0 green:76.0/255.0 blue:76.0/255.0 alpha:1.0]];
        }
        
        [self.sideKittyTxtView setTextColor:[UIColor whiteColor]];
        self.aboutView.backgroundColor = [UIColor darkGrayColor];
        self.aboutView.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.aboutDevTxtView setTextColor:[UIColor whiteColor]];
        textfieldBottomBorder.strokeColor = [UIColor whiteColor].CGColor;
        [self.textField setTextColor:[UIColor whiteColor]];
        
        self.typingView.backgroundColor = [UIColor colorWithRed:31.0/255.0 green:34.0/255.0 blue:51.0/255.0 alpha:1.0];
        
        self.typingView.layer.borderColor = [[UIColor whiteColor] CGColor];
        [self.textView setTextColor:[UIColor whiteColor]];
        
        [self.doneButton setBackgroundImage:[UIImage imageNamed:@"CheckDarkMode"] forState:(UIControlState)UIControlStateNormal];
        
        [self setupVideoForTypingAnimation];
    } else {
        
        _topBar.backgroundColor= [UIColor colorWithRed:2255.0/255.0 green:128.0/255.0 blue:171.0/255.0 alpha:1.0];
        if (self.notesArray.count!= 0) {
            self.purrCV.backgroundColor= [UIColor colorWithRed:228.0/255.0 green:228.0/255.0 blue:228.0/255.0 alpha:1.0];
        } else {
            self.purrCV.backgroundColor = [UIColor clearColor];
            [self.pleaseAddAPurrView setBackgroundColor:[UIColor colorWithRed:288.0/255.0 green:288.0/255.0 blue:288.0/255.0 alpha:1.0]];
        }
        [self.sideKittyTxtView setTextColor:[UIColor darkGrayColor]];
        self.aboutView.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:235.0/255.0 blue:238.0/255.0 alpha:1.0];
        self.aboutView.layer.borderColor = [UIColor colorWithRed:233.0/255.0 green:30.0/255.0 blue:99.0/255.0 alpha:1.0].CGColor;
        [self.aboutDevTxtView setTextColor:[UIColor darkGrayColor]];
        textfieldBottomBorder.strokeColor = [UIColor blackColor].CGColor;
        [self.textField setTextColor:[UIColor blackColor]];
        self.typingView.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:235.0/255.0 blue:238.0/255.0 alpha:1.0];
        self.typingView.layer.borderColor = [[UIColor blackColor] CGColor];
        [self.textView setTextColor:[UIColor blackColor]];
        
        [self.doneButton setBackgroundImage:[UIImage imageNamed:@"CheckBrightMode"] forState:(UIControlState)UIControlStateNormal];
        
        [self setupVideoForTypingAnimation];
    }
    [self.purrCV reloadData];
}

-(void)setupVideoForTypingAnimation{
    [_videoLayer removeFromSuperlayer];
    self.vidPlayer =nil;
    
    if (themeMode==DarkMode){
        self.vidPlayer = [AVPlayer playerWithURL:[NSURL fileURLWithPath:typingAnimationForDarkTheme]];
    }else{
        self.vidPlayer = [AVPlayer playerWithURL:[NSURL fileURLWithPath:typingAnimationForBrightTheme]];
    }
    
    self.vidPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _videoLayer = [AVPlayerLayer playerLayerWithPlayer:self.vidPlayer];
    [self.vidPlayer pause];
    [self.vidPlayer seekToTime:CMTimeMake(0, 1)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.vidPlayer currentItem]];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    videoRect = CGRectMake(vidX, vidY, vidW, vidH);
    [_videoLayer setFrame :videoRect];
    _videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.typingView.layer addSublayer:_videoLayer];
}

-(void)initializeSoundFileUrls{
    
    // Done sound file
    NSString *DoneSoundFilePath=[[NSBundle mainBundle] pathForResource:@"Done.mp3" ofType:nil inDirectory:@"Kitty Sounds"];
    NSURL * doneBtnSoundUrl = [NSURL fileURLWithPath:DoneSoundFilePath];
    self.doneBtnAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:doneBtnSoundUrl error:nil];
    self.doneBtnAudioPlayer.numberOfLoops = 0;
    
    // Cancel sound file
    NSString * cancelSoundFilePath =[[NSBundle mainBundle] pathForResource:@"Cancel.mp3" ofType:nil inDirectory:@"Kitty Sounds"];
    NSURL * cancelBtnSoundUrl = [NSURL fileURLWithPath:cancelSoundFilePath];
    self.cancelBtnAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:cancelBtnSoundUrl error:nil];
    self.cancelBtnAudioPlayer.numberOfLoops = 0;
    
    // Add sound file
    NSString *AddSoundFilePath = [[NSBundle mainBundle] pathForResource:@"Add.mp3" ofType:nil inDirectory:@"Kitty Sounds"];
    NSURL * AddBtnSoundUrl = [NSURL fileURLWithPath:AddSoundFilePath];
    self.AddBtnAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:AddBtnSoundUrl error:nil];
    self.AddBtnAudioPlayer.numberOfLoops = 0;
}

-(void)initializeTypingViewForTypingMode{
    self.containerViewforTypingViewAndImageview = [[UIView alloc]initWithFrame:CGRectMake((screenW/2-containerViewW/2),screenH, containerViewW,containerViewHForTypingMode)];
    self.containerViewforTypingViewAndImageview.backgroundColor  = [UIColor clearColor];
    
    self.typingView = [[UIView alloc]initWithFrame:CGRectMake((screenW/2-containerViewW/2),(topBGH/2)-5, containerViewW,typingViewHForTypingMode)];

    self.typingView.layer.cornerRadius =20;
    self.typingView.layer.borderWidth = 4.0;
    
    // Textfield for typingView (Note Title)
    self.textField = [[UITextField alloc]initWithFrame:CGRectMake(16,textFieldY,textFieldW,textFieldH)];
    self.textField.delegate = self;
    // handle the change event (UIControlEventEditingChanged) by calling (textFieldDidChange:)
    [self.textField addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    self.textField.placeholder = NSLocalizedString(@"PLACEHOLDER", nil);
    [self.textField setFont:[UIFont fontWithName:@"Avenir-Medium" size:20]];
    // Adding border for textfield
    textfieldBottomBorder = [CAShapeLayer layer];
    textfieldBottomBorder.fillColor = nil;
    textfieldBottomBorder.lineDashPattern = @[@3,@3];
    textfieldBottomBorder.borderWidth =4.0;
    UIBezierPath *aPath = [UIBezierPath bezierPath];
    [aPath moveToPoint:CGPointMake(0,textFieldH)];
    [aPath addLineToPoint:CGPointMake(textFieldW,textFieldH)];
    textfieldBottomBorder.path =aPath.CGPath;
    
    // TextView for typingView (Note body)
    self.textView = [[UITextView alloc]initWithFrame:CGRectMake(16,textViewY,textViewW,textViewHForTypingMode)];
    [self.textView setBackgroundColor:[UIColor clearColor]];
    
    self.textView.delegate = self;
    [self.textView setFont:[UIFont fontWithName:@"Avenir-Medium" size:18.0]];
    self.textView.scrollEnabled=YES;
    // this is used to stop the typing animation for uitextview
    [notifCenterToStopTypingAnimForTextView addObserver:self
                                               selector:@selector(textViewText:)
                                                   name:UITextViewTextDidChangeNotification
                                                 object:self.textView];
    self.textView.editable=YES;
    
    // Done button for typingView (Note body)
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.doneButton setFrame:CGRectMake((containerViewW-(8+doneBtnW)),typingViewHForTypingMode - (8 + doneBtnH),doneBtnW,doneBtnH)];
    [self.doneButton addTarget:self action:@selector(doneAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setFrame:CGRectMake(8,typingViewHForTypingMode - (8 + doneBtnH),doneBtnW,doneBtnH)];
    [self.cancelButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"cross"] forState:UIControlStateNormal];
    
    [self manageThemes];
    
    [self.view addSubview:self.containerViewforTypingViewAndImageview];
    [self.containerViewforTypingViewAndImageview addSubview:self.typingView];
    [self.textField.layer addSublayer:textfieldBottomBorder];
    [self.typingView addSubview:self.textField];
    [self.typingView addSubview:self.textView];
    [self.typingView addSubview:self.doneButton];
    [self.typingView addSubview:self.cancelButton];
    [self.containerViewforTypingViewAndImageview addSubview:self.typingViewTopBGImgView];
    [self.typingViewTopBGImgView setFrame:CGRectMake((self.containerViewforTypingViewAndImageview.frame.size.width/2-topBGW/2),0, topBGW, topBGH)];
    [_typingView.layer addSublayer:_videoLayer];
}
- (NSAttributedString *)linkedStringFromFullString:(NSString *)fullString withLinkString:(NSString *)linkString andUrlString:(NSString *)urlString{
        NSRange range = [fullString rangeOfString:linkString options:NSLiteralSearch];
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:fullString];
        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary *attributes = @{NSForegroundColorAttributeName:@(0x999999),
                                     NSFontAttributeName:[UIFont fontWithName:@"Avenir-Black" size:14],
                                     NSParagraphStyleAttributeName:paragraphStyle};
        [str addAttributes:attributes range:NSMakeRange(0, [str length])];
        [str addAttribute: NSLinkAttributeName value:urlString range:range];
        
        return str;
}

-(void)keyboardDidShow:(NSNotification *)notification{
    keyboardHeightSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    NSLog(@"3. Keyboard height is %f",keyboardHeightSize);
    
    if (keyboardHeightSize>220) {
        // We're checking if we havn't saved the keyboard height.
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"KeyboardHeightIsKnownBecauseAppWasLaunchedAtLeastOnce"]){
            
            NSLog(@"4. keyboardDidShow -> %f",keyboardHeightSize);

            [keyboardHeightUserDefaults setFloat:keyboardHeightSize forKey:@"KeyboardHeight"];
            [self calculateSizesForAllViewsAndCells];
            [self initializeTypingViewForTypingMode];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"KeyboardHeightIsKnownBecauseAppWasLaunchedAtLeastOnce"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.textField becomeFirstResponder];
        }
    }
}
@end
