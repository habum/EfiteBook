//
//  EfiteMainViewController.h
//  EfiteBook
//
//  Created by Masayoshi Habu on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "EfiteFlipsideViewController.h"
#import "EfiteSpeechTestViewController.h"

@interface EfiteMainViewController : UIViewController <EfiteFlipsideViewControllerDelegate, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate>
{
    NSString *prefix;
    NSString *suffix;
    NSTimer *watchDogTimer;
    int page;
    int pageMin;
    int pageMax;
    //int ios;
    CGPoint previous;
    CGPoint contentOffset;
    float zoomScale;
    BOOL newPage;
    int newsFlag;
    int tick;
    
    UIButton *buttonRight;
    UIButton *buttonLeft;
    UIButton *buttonInfo;
    UIActivityIndicatorView *activity;
}

@property (nonatomic, retain) IBOutlet UIButton *buttonRight;
@property (nonatomic, retain) IBOutlet UIButton *buttonLeft;
@property (nonatomic, retain) IBOutlet UIButton *buttonInfo;
@property (nonatomic, retain) IBOutlet UIButton *buttonSpeechTest;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activity;

// show Table of Content view
-(IBAction)showInfo:(id)sender;
// show SpeechTest view
-(IBAction)speechTest:(id)sender;

-(IBAction)buttonPressed:(id)sender;

-(void)gotoPage:(int) p;
-(void)loadDocument:(NSString*)documentName;
-(void)goBack:(UIGestureRecognizer *)gestureRecognizer;
-(void)goForward:(UIGestureRecognizer *)gestureRecognizer;
-(void)goTable:(UIGestureRecognizer *)gestureRecognizer;
-(void)goSpeech:(UIGestureRecognizer *)gestureRecognizer;

-(void)saveData;
-(void)restoreData;
-(void)goBackPage;
-(void)goForwardPage;

-(void)wakeUpWatchDog;

@end
