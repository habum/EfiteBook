//
//  EfiteSpeechTestViewController.m
//  EfiteBook
//
//  Created by Masayoshi Habu on 10/8/17.
//

// for rand()
#import <stdlib.h>

#import "EfiteSpeechTestViewController.h"
#import "EfiteMainViewController.h"

@interface EfiteSpeechTestViewController ()

@end

@implementation EfiteSpeechTestViewController

@synthesize pageMap;
@synthesize pageNum;
@synthesize label;
@synthesize textView;
@synthesize answView;
@synthesize doneButton;
@synthesize startButton;
@synthesize speechButton;
@synthesize shuffleButton;
@synthesize wheel;
@synthesize recognizer;
@synthesize audioEngine;
@synthesize request;
@synthesize inputNode;
@synthesize currentTask;
@synthesize synthesizer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"EfiteSpeechTestViewController viewDidLoad");
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"EfiteSpeechTest" ofType:@"plist"];
    // key = text number string dd, value = text to show
    self.pageMap = [[NSDictionary alloc] initWithContentsOfFile:path];
    self.pageNum = [[pageMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
    qsize = pageNum.count;
    qnum = arc4random_uniform((uint32_t) qsize);
    self.textView.text = pageMap[pageNum[qnum]];
    
    // iOS 10+
    NSLocale *en_us = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    self.recognizer = [[SFSpeechRecognizer alloc] initWithLocale:en_us];
    [self.recognizer setDelegate:self];

    // TextToSpeech
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    [self.synthesizer setDelegate:self];
    
    // Init Audio Session
    NSError *outError = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&outError];
    //AVAudioSessionModeVideoChat keeps the synthesized speech volume high
    [audioSession setMode:AVAudioSessionModeVideoChat error:&outError];
    [audioSession setActive:true withOptions:
        (AVAudioSessionCategoryOptionDefaultToSpeaker
        |AVAudioSessionCategoryOptionAllowBluetooth) error:&outError];
    if (outError) {
        NSLog(@"Error %@", outError);
    }

    authorized = NO;
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus authStatus) {
        switch (authStatus) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                //User gave access to speech recognition
                NSLog(@"Authorized");
                authorized = YES;
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                //User denied access to speech recognition
                NSLog(@"SFSpeechRecognizerAuthorizationStatusDenied");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                //Speech recognition restricted on this device
                NSLog(@"SFSpeechRecognizerAuthorizationStatusRestricted");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                //Speech recognition not yet authorized
                NSLog(@"SFSpeechRecognizerAuthorizationStatusNotDetermined");
                break;
            default:
                NSLog(@"Default");
                break;
        }
    }];
    
    self.audioEngine = [[AVAudioEngine alloc] init];

    listening = NO;
    [wheel stopAnimating];
    request = nil;
    currentTask = nil;
    speechTimer = nil;
    inputNode = nil;
}

-(void)startSpeech
{
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:self.textView.text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en_US"];
    [self.synthesizer speakUtterance:utterance];
}

-(void)stopSpeech
{
    if (synthesizer && synthesizer.speaking) {
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}

-(void)stopListening
{
    self.answView.text = @"";
    self.answView.textColor = [UIColor blueColor];
    if (currentTask && listening) {
        if ([recognizer isAvailable]) {
            [currentTask finish];
        } else {
            self.answView.text = @"Network may be down. Recognizer is unavailable.";
            self.answView.textColor = [UIColor redColor];
        }
    }
    if (speechTimer && speechTimer.valid) {
        [speechTimer invalidate];
        speechTimer = nil;
    }
    [self cleanUp];
}

-(void)startListening
{
    if (! [recognizer isAvailable]) {
        self.answView.text = @"Recognizer is unavailable. Network may be down.";
        self.answView.textColor = [UIColor redColor];
        return;
    }
    
    if (request) {
        [self cleanUp];
    }
    self.answView.text = @"Listening to your voice for speech recognition...";
    self.answView.textColor = [UIColor redColor];
    
    request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    inputNode = [audioEngine inputNode];
    
    request.shouldReportPartialResults = false;
    currentTask = [recognizer recognitionTaskWithRequest:request delegate:self];
    // do not release currentTask as delegate works in another thread
    
    [inputNode installTapOnBus:0 bufferSize:1024 format:[inputNode outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        if (listening) {  // A hack to stop the memory leak against logDictationFailedWithError (no words recognized)
            [request appendAudioPCMBuffer:buffer];
        }
    }];
    
    [audioEngine prepare];
    NSError *outError = nil;
    [audioEngine startAndReturnError:&outError];
    if (outError) {
        NSLog(@"Error %@", outError);
    }
    
    listening = YES;
    [wheel startAnimating];
    [startButton setTitle:@"Stop" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor redColor]
                      forState:UIControlStateNormal];
    
    // after 30 sec, cancel the recognition task
    speechTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(30.0)
                  target:self selector:@selector(stopListening) userInfo:nil repeats:FALSE];
}

- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task {
    NSLog(@"speechRecognitionTaskWasCancelled");
    [self cleanUp];
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)result {
    
    NSLog(@"speechRecognitionTask: didFinishRecognition");
    NSString *translatedString = [[[result bestTranscription] formattedString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([result isFinal]) {
        NSLog(@"%@", translatedString);
        self.answView.text = translatedString;
        self.answView.textColor = [UIColor blueColor];
        [self cleanUp];
    }
}

// this is rarely called
//- (void)viewDidUnload
//{
//    NSLog(@"EfiteSpeechTestViewController viewDidUnload");
//    [self unload];
//    [super viewDidUnload];
//}

-(void)dealloc
{
    [super dealloc];
}

// use shake to shuffle the quiz
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (UIEventSubtypeMotionShake) {
        [self shuffleExample];
        //[self stopSpeech];
        //[self stopListening];
        //qnum = arc4random_uniform((uint32_t) qsize);
        //self.textView.text = pageMap[pageNum[qnum]];
        //self.answView.text = @"";
        //self.answView.textColor = [UIColor blueColor];
    }
}

- (void) shuffleExample
{
    [self stopSpeech];
    [self stopListening];
    qnum = arc4random_uniform((uint32_t) qsize);
    self.textView.text = pageMap[pageNum[qnum]];
    self.answView.text = @"";
    self.answView.textColor = [UIColor blueColor];
}

- (void)cleanUp
{
    listening = NO;
    [wheel stopAnimating];
    [audioEngine stop];
    [inputNode removeTapOnBus:0];
    //Bluetooth mic changes inputNode
    [audioEngine release];
    audioEngine = [[AVAudioEngine alloc] init];
    inputNode = nil;
    
    [request endAudio];
    [request release];
    request = nil;

    [startButton setTitle:@"Start" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor blueColor]
                      forState:UIControlStateNormal];
}

- (void)unload
{
    // objects created in viewDidLoad
    [self stopSpeech];
    [synthesizer release];
    synthesizer = nil;
    
    [pageMap release];
    pageMap = nil;
    [pageNum release];
    pageNum = nil;
    
    [self stopListening];  // calls cleanUp
    [recognizer release];
    recognizer = nil;
    
    [audioEngine stop];
    [audioEngine release];
    audioEngine = nil;
    
    // allow other audio sources to resume
    NSError *outError = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:false withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&outError];
    if (outError) {
        NSLog(@"Error %@", outError);
    }
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    if (currentTask && listening) {
        if ([recognizer isAvailable]) {
            [currentTask cancel];
        } else {
            [self cleanUp];
        }
    }
    if (speechTimer && speechTimer.valid) {
        [speechTimer invalidate];
        speechTimer = nil;
    }
    [self unload];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)start:(id)sender
{
    if (authorized) {
        if (listening) {
            [self stopListening];
        } else {
            [self startListening];
        }
    } else {
        startButton.hidden = YES;
        self.answView.text = @"Speech Recognition is turned off. Turn it on from Settings.";
        self.answView.textColor = [UIColor redColor];
    }
}

- (IBAction)speech:(id)sender
{
    [self startSpeech];
}

- (IBAction)shuffle:(id)sender
{
    [self shuffleExample];
}

@end
