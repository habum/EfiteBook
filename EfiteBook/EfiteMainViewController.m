//
//  EfiteMainViewController.m
//  EfiteBook
//
//  Created by Masayoshi Habu on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EfiteMainViewController.h"

@interface EfiteMainViewController ()

@end

@implementation EfiteMainViewController

@synthesize buttonRight;
@synthesize buttonLeft;
@synthesize buttonInfo;
@synthesize buttonSpeechTest;
@synthesize activity;

#define TICK 2

- (void)viewDidLoad
{
    [super viewDidLoad];
    tick = 0;
    newsFlag = 0;
    newPage = NO;
    zoomScale = 1.0f;
    ios = [[[UIDevice currentDevice] systemVersion] intValue];  // not used now
	// Do any additional setup after loading the view, typically from a nib.
    // Calling -loadDocument:inView:
    prefix = @"EFITE2_ibook-page";
    suffix = @".pdf";
    // physical page numbers as a file suffix; see also EfiteToc.plist
    page = 1;
    pageMin = 1;
    // see also saveData for book version string
    //pageMax = 71;  // book 1.0
    //pageMax = 77;  // book 1.1
    pageMax = 78;  // book 1.2, 1.3

    [(UIWebView*)self.view setScalesPageToFit: true];
    //[self gotoPage:page];  // unnecessary - see restoreData called on active
    previous.x = previous.y = 0.0f;

    UISwipeGestureRecognizer* swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack:)];
    // iOS 3.2 or later supports this gesture
    if (![swipeRight respondsToSelector:@selector(locationInView:)]) {
        [swipeRight release];
        swipeRight = nil;
    } else if (swipeRight) {
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [(UIWebView*)self.view addGestureRecognizer:swipeRight];
    }
    
    UISwipeGestureRecognizer* swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goForward:)];
    // iOS 3.2 or later supports this gesture
    if (![swipeLeft respondsToSelector:@selector(locationInView:)]) {
        [swipeLeft release];
        swipeLeft = nil;
    } else if (swipeLeft) {
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [(UIWebView*)self.view addGestureRecognizer:swipeLeft];
    }
    
    UITapGestureRecognizer * tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goSpeech:)];
    // iOS 3.2 or later supports this gesture
    if (![tap2 respondsToSelector:@selector(locationInView:)]) {
        [tap2 release];
        tap2 = nil;
    } else if (tap2) {
        tap2.numberOfTouchesRequired = 2;
        [(UIWebView*)self.view addGestureRecognizer:tap2];
    }
    
    // bring them front
    [(UIWebView*)self.view bringSubviewToFront: buttonLeft];
    [(UIWebView*)self.view bringSubviewToFront: buttonRight];
    [(UIWebView*)self.view bringSubviewToFront: buttonInfo];
    [(UIWebView*)self.view bringSubviewToFront: buttonSpeechTest];
    [(UIWebView*)self.view bringSubviewToFront: activity];
    
    // receive loading status for activity
    [(UIWebView*)self.view setDelegate:self];
    
    // iOS 5.0 or later supports this
    if ([(UIWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        [[(UIWebView*)self.view scrollView] setDelegate:self];
    }
    
    // trigger zooming after page loading completed
    watchDogTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(1.0 / 10.0)
                        target:self selector:@selector(wakeUpWatchDog)
                        userInfo:nil repeats:TRUE];
    
}

//- (void)viewDidUnload
//{
//    self.buttonRight = nil;
//    self.buttonLeft = nil;
//    self.buttonInfo = nil;
//    self.activity = nil;
//    [super viewDidUnload];
    // Release any retained subviews of the main view.
//}

// landscape only
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return (interfaceOrientation == UIDeviceOrientationLandscapeLeft ||
//            interfaceOrientation == UIDeviceOrientationLandscapeRight);
//
//}

// called from both page selection menu, buttons, and swipes
-(void)gotoPage:(int)p
{
    if (pageMin <= p && p <= pageMax) {
        NSString *pdf = [NSString stringWithFormat:@"%@%d%@", prefix, p, suffix];
        [self loadDocument:pdf];
        page = p;
    }
    // reset to the top-left corner
    contentOffset.x = contentOffset.y = 0.0f;
}

-(void)loadDocument:(NSString*)documentName
{
    // iOS 5.0 or later supports this
    if ([(UIWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        zoomScale = [[(UIWebView*)self.view scrollView] zoomScale];
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:documentName ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLRequest *original = ((UIWebView*)self.view).request;
    // load a new page only (avoid zoom reset on active)
    if (original) {
        NSURL *originalURL = [original URL];
        NSString *originalPath = [originalURL path];
        if (![originalPath isEqualToString:path]) {
            // iOS 5.0 or later supports this
            if ([(UIWebView*)self.view respondsToSelector:@selector(scrollView)]) {
                [[(UIWebView*)self.view scrollView] setHidden:YES];
            }
            [(UIWebView*)self.view loadRequest:request];
            newPage = YES;
            tick = TICK;
        }
    } else {
        // iOS 5.0 or later supports this
        if ([(UIWebView*)self.view respondsToSelector:@selector(scrollView)]) {
            [[(UIWebView*)self.view scrollView] setHidden:YES];
        }
        [(UIWebView*)self.view loadRequest:request];
        newPage = YES;
        tick = TICK;
    }
}

#define IPADPADDING 4.0f
-(void)goBackPage
{
    NSURLRequest *current = [(UIWebView*)self.view request];
    NSURL *url = [current URL];
    if ([url isFileURL]) {
        if (pageMin < page) {
            page--;
            [self gotoPage:page];
        }
    } else {
        if ([(UIWebView*)self.view canGoBack]) {
            [(UIWebView*)self.view goBack];
        }
    }
    contentOffset.x = contentOffset.y = 0.0f;
    
    // iOS 5.0 or later supports this
    // set to the bottom-right corner
    if ([(UIWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        CGRect bounds = [[(UIWebView*)self.view scrollView] bounds];
        CGSize csize = [[(UIWebView*)self.view scrollView] contentSize];
        contentOffset.x = csize.width - bounds.size.width;
        
        // iPad can show the entire page, so a vertical shift needs to be excluded
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            // if (self.interfaceOrientation == UIDeviceOrientationPortrait) {
            if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait) {
                // reset to the top-right corner
                contentOffset.y = 0.0f;
            } else {
                contentOffset.y = csize.height - bounds.size.height;
            }
        } else {
            contentOffset.y = csize.height - bounds.size.height - IPADPADDING;
            // iPad shows a page that fits to the view width
            if (contentOffset.y < 0.0f) {
                contentOffset.y = 0.0f;
            }
        }
    }
}

- (void)goBack:(UIGestureRecognizer *)gestureRecognizer
{
    [self goBackPage];
}

-(void)goForwardPage
{
    NSURLRequest *current = [(UIWebView*)self.view request];
    NSURL *url = [current URL];
    if ([url isFileURL]) {
        if (page < pageMax) {
            page++;
            [self gotoPage:page];
        }
    } else {
        if ([(UIWebView*)self.view canGoForward]) {
            [(UIWebView*)self.view goForward];
        }
    }
    // reset to the top-left corner
    contentOffset.x = contentOffset.y = 0.0f;
}

- (void)goForward:(UIGestureRecognizer *)gestureRecognizer
{
    [self goForwardPage];
}

- (void)goTable:(UIGestureRecognizer *)gestureRecognizer {
    [self showInfo:buttonInfo];
}

- (void)goSpeech:(UIGestureRecognizer *)gestureRecognizer {
    [self speechTest:nil];
}

- (IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton*) sender;
    if (button == buttonRight) {
        [self goForwardPage];
    } else if (button == buttonLeft) {
        [self goBackPage];
    } else {
        // ignore other buttons
    }
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(EfiteFlipsideViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    [buttonRight release];
    [buttonLeft release];
    [buttonInfo release];
    [buttonSpeechTest release];
    [activity release];
    [(UIWebView*)self.view setDelegate:nil];
    [watchDogTimer invalidate];
	[watchDogTimer release];
    [super dealloc];
}

//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
//{
//}

- (IBAction)speechTest:(id)sender
{
    NSOperatingSystemVersion version = {10, 0, 0};
    BOOL isOSVersion10orLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
    if (isOSVersion10orLater) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            EfiteSpeechTestViewController *controller = [[[EfiteSpeechTestViewController alloc] initWithNibName:@"EfiteSpeechTestViewController_iPhone" bundle:nil] autorelease];
            controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentViewController:controller animated:YES completion:nil];
        } else {
            EfiteSpeechTestViewController *controller = [[[EfiteSpeechTestViewController alloc] initWithNibName:@"EfiteSpeechTestViewController_iPad" bundle:nil] autorelease];
            controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentViewController:controller animated:YES completion:nil];
        }
    } else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Notice"
                                                                       message:@"Speech API needs iOS 10 or higher"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)showInfo:(id)sender
{
    EfiteFlipsideViewController *controller = [[[EfiteFlipsideViewController alloc] initWithNibName:@"EfiteFlipsideViewController" bundle:nil] autorelease];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller selectPage: page]; // show the current page selection
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [activity startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [activity stopAnimating];
    
    // hide nav buttons on iPhone/iPod when showing an Internet page for page controls
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        NSURLRequest *current = [(UIWebView*)self.view request];
        NSURL *url = [current URL];
        if ([url isFileURL]) {
            [buttonRight setHidden:NO];
            [buttonLeft setHidden:NO];
        } else {
            [buttonRight setHidden:YES];
            [buttonLeft setHidden:YES];
        }
    }
}

// this dialog is added for version 1.3, changed to UIAlertController for 1.4.
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSInteger code = [error code];
    if (code == NSURLErrorNotConnectedToInternet) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Notice"
                                                                       message:[error localizedDescription]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [activity stopAnimating];
}

// hack to adjust zooming because content loading and rendering are asynchronous
-(void)wakeUpWatchDog
{
    if (newPage && ![(UIWebView*)self.view isLoading]) {
        if (0 < tick) {
            tick--;  // wait for rendering is done after loading is done
        } else {
            // iOS 5.0 or later supports this
            if ([(UIWebView*)self.view respondsToSelector:@selector(scrollView)]) {
                [[(UIWebView*)self.view scrollView] setZoomScale:zoomScale animated:NO];
                [[(UIWebView*)self.view scrollView] setContentOffset:contentOffset animated:NO];
                [[(UIWebView*)self.view scrollView] setHidden:NO];
            }
            newPage = NO;
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)sview
{
    if ([(UIWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        previous = [[(UIWebView*)self.view scrollView] contentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sview willDecelerate:(BOOL)decelerate
{
    if ([(UIWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        CGPoint offset = [[(UIWebView*)self.view scrollView] contentOffset];
        CGFloat xdiff = offset.x - previous.x;
        CGFloat ydiff = offset.y - previous.y;
        CGFloat margin = 6.0f;  // empirical value
        CGRect bounds = [sview bounds];
        CGFloat xmax = (bounds.size.width / margin);
        CGFloat xmin = -xmax;
        // side scroll and bigger than margin
        if (fabs(ydiff) < fabs(xdiff)/margin) {
            CGFloat scale = [sview zoomScale];
            if (xmax < xdiff && (bounds.size.width * (scale - 1.0f)) + xmax < offset.x) {
                [self goForwardPage];
            } if (xdiff < xmin && offset.x < xmin) {
                [self goBackPage];
            }
        }
    }
}


#define kFilename        @"EfiteBook.plist"
#define kcurrentPage     @"currentPage"
#define kbookVersion     @"bookVersion"
#define knewsFlag        @"newsFlag"

- (NSString*)dataFilePath {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:kFilename];
}

- (void)saveData {
	NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
	
	NSNumber* pageObj = [NSNumber numberWithInt:page];
	[dic setObject:pageObj forKey:kcurrentPage];
	NSString* bookObj = [NSString stringWithUTF8String: "1.3"];  // current book version
	[dic setObject:bookObj forKey:kbookVersion];
    NSNumber* newsObj = [NSNumber numberWithInt:newsFlag];
    [dic setObject:newsObj forKey:knewsFlag];
    
	[dic writeToFile:[self dataFilePath] atomically:YES];
	[dic release];
}

- (void)restoreData {
	NSString* filePath = [self dataFilePath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		NSDictionary* dic = [[NSDictionary alloc] initWithContentsOfFile:filePath];
		
		NSNumber* pageObj = (NSNumber*) [dic objectForKey:kcurrentPage];
        NSString* bookObj = (NSString*) [dic objectForKey:kbookVersion];
        NSNumber* newsObj = (NSNumber*) [dic objectForKey:knewsFlag];

        if (pageObj) {
            int p = [pageObj intValue];
            
            if (bookObj == nil) {  // this implies book version 1.0
                if (26 <= p) {
                    p += 4; // book 1.0 to 1.1 offset increase
                }
            } else {
                if ([bookObj isEqualToString: @"1.1"]) {
                    if (11 <= p) {
                        p += 1; // book 1.1 to 1.2 offset
                    }
                }
                if ([bookObj isEqualToString: @"1.2"]) {
                    // correct page number - do nothing
                }
            }
            
            [self gotoPage: p];  // load the page
        } else {
            [self gotoPage: page];  // load the same page if current page is unknown
        }
        
        if (newsObj == nil) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"新機能：発音練習付き"
                                                                           message:@"２本指タップで開始　iOS10以上"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"了解" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            newsFlag = 1;
        }
		
		[dic release];
	} else {
        [self gotoPage: page];  // load the initial page
    }
}

@end
