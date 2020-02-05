//
//  EfiteSpeechTestViewController.h
//  EfiteBook
//
//  Created by Masayoshi Habu on 10/8/17.
//

#ifndef EfiteSpeechTestViewController_h
#define EfiteSpeechTestViewController_h

#import <UIKit/UIKit.h>
#import <Speech/Speech.h>

@class EfiteSpeechTestViewController;

@interface EfiteSpeechTestViewController : UIViewController <SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate, AVSpeechSynthesizerDelegate>
{
    NSDictionary *pageMap;
    NSArray *pageNum;
    
    UILabel *label;
    UITextView *textView;
    UITextView *answView;
    UIButton *doneButton;
    UIButton *startButton;
    UIButton *speechButton;
    UIButton *shuffleButton;
    UIActivityIndicatorView *wheel;
    
    SFSpeechRecognizer *recognizer;
    AVAudioEngine *audioEngine;
    SFSpeechAudioBufferRecognitionRequest *request;
    AVAudioInputNode *inputNode;
    SFSpeechRecognitionTask *currentTask;
    NSTimer *speechTimer;
    AVSpeechSynthesizer *synthesizer;
    
    NSUInteger qsize;
    NSUInteger qnum;
    BOOL listening;
    BOOL authorized;
}

@property (nonatomic, retain) NSDictionary *pageMap;
@property (nonatomic, retain) NSArray *pageNum;

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UITextView *answView;
@property (nonatomic, retain) IBOutlet UIButton *doneButton;
@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) IBOutlet UIButton *speechButton;
@property (nonatomic, retain) IBOutlet UIButton *shuffleButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *wheel;

@property (nonatomic, retain) SFSpeechRecognizer *recognizer;
@property (nonatomic, retain) AVAudioEngine *audioEngine;
@property (nonatomic, retain) SFSpeechAudioBufferRecognitionRequest *request;
@property (readonly, nonatomic) AVAudioInputNode *inputNode;
@property (nonatomic, retain) SFSpeechRecognitionTask *currentTask;
@property (nonatomic, retain) AVSpeechSynthesizer *synthesizer;

-(IBAction)done:(id)sender;
-(IBAction)start:(id)sender;
-(IBAction)speech:(id)sender;
-(IBAction)shuffle:(id)sender;

-(void)startListening;
-(void)stopListening;
-(void)startSpeech;
-(void)stopSpeech;
-(void)cleanUp;
-(void)unload;
-(void)shuffleExample;

@end

#endif /* EfiteSpeechTestViewController_h */
