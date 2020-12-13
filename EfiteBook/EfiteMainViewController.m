//
//  EfiteMainViewController.m
//  EfiteBook
//
//  Created by Masayoshi Habu on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EfiteMainViewController.h"
#import "MyWKWebView.h"

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
    zoomScale = 0.636450f; // was 1.0f;
    //ios = [[[UIDevice currentDevice] systemVersion] intValue];  // not used now
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

    //[(MyWKWebView*)self.view setScalesPageToFit: true];
    //[self gotoPage:page];  // unnecessary - see restoreData called on active
    previous.x = previous.y = 0.0f;
    contentOffset.x = contentOffset.y = 0.0f;

    // trigger zooming after page loading completed
    watchDogTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(1.0 / 10.0)
                        target:self selector:@selector(wakeUpWatchDog)
                        userInfo:nil repeats:TRUE];
    //all the view manipulation is in viewDidLayoutSubviews
}

#define x_offset 0.04f
#define y_offset 0.05f
#define x_shift  0.96f
#define y_shift  0.93f
#define x_center 0.50f
#define y_center 0.50f

-(void)viewDidLayoutSubviews
{
    // hide the PDF page counter
    UIView *lastView = self.view.subviews.lastObject;
    if (lastView != nil && ![lastView isKindOfClass:[UIScrollView class]]) {
        lastView.hidden = YES;
    }
    
    // bring them front
    // AutoLayout of WKWebView does not work, so layout them here
    CGSize wvsize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height);
    [(MyWKWebView*)self.view addSubview: buttonLeft];
    buttonLeft.frame = CGRectMake(wvsize.width * x_offset - (buttonLeft.frame.size.width / 2), wvsize.height * y_offset - (buttonLeft.frame.size.height / 2), buttonLeft.frame.size.width, buttonLeft.frame.size.height);
    [(MyWKWebView*)self.view bringSubviewToFront: buttonLeft];
    
    [(MyWKWebView*)self.view addSubview: buttonRight];
    buttonRight.frame = CGRectMake(wvsize.width * x_shift - (buttonRight.frame.size.width / 2), wvsize.height * y_offset - (buttonRight.frame.size.height / 2), buttonRight.frame.size.width, buttonRight.frame.size.height);
    [(MyWKWebView*)self.view bringSubviewToFront: buttonRight];
    
    [(MyWKWebView*)self.view addSubview: buttonInfo];
    buttonInfo.frame = CGRectMake(wvsize.width * x_center - (buttonInfo.frame.size.width / 2), wvsize.height * y_offset - (buttonInfo.frame.size.height / 2), buttonInfo.frame.size.width, buttonInfo.frame.size.height);
    [(MyWKWebView*)self.view bringSubviewToFront: buttonInfo];
    
    [(MyWKWebView*)self.view addSubview: buttonSpeechTest];
    buttonSpeechTest.frame = CGRectMake(wvsize.width * x_center - (buttonSpeechTest.frame.size.width / 2), wvsize.height * y_shift - (buttonSpeechTest.frame.size.height / 2), buttonSpeechTest.frame.size.width, buttonSpeechTest.frame.size.height);
    [(MyWKWebView*)self.view bringSubviewToFront: buttonSpeechTest];
    
    [(MyWKWebView*)self.view addSubview: activity];
    activity.frame = CGRectMake(wvsize.width * x_center - (activity.frame.size.width / 2), wvsize.height * y_center - (activity.frame.size.height / 2), activity.frame.size.width, activity.frame.size.height);
    [(MyWKWebView*)self.view bringSubviewToFront: activity];
    
    
    // gesture recognizer
    UISwipeGestureRecognizer* swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack:)];
    // iOS 3.2 or later supports this gesture
    if (![swipeRight respondsToSelector:@selector(locationInView:)]) {
        [swipeRight release];
        swipeRight = nil;
    } else if (swipeRight) {
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [(MyWKWebView*)self.view addGestureRecognizer:swipeRight];
    }
    
    UISwipeGestureRecognizer* swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goForward:)];
    // iOS 3.2 or later supports this gesture
    if (![swipeLeft respondsToSelector:@selector(locationInView:)]) {
        [swipeLeft release];
        swipeLeft = nil;
    } else if (swipeLeft) {
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [(MyWKWebView*)self.view addGestureRecognizer:swipeLeft];
    }
    
    // receive loading status through delegate
    [(MyWKWebView*)self.view setNavigationDelegate:self];
    [(MyWKWebView*)self.view setUIDelegate:self];
    
    // iOS 5.0 or later supports this
    if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        [[(MyWKWebView*)self.view scrollView] setDelegate:self];
    }
}

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
    if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        float _zoomScale = [[(MyWKWebView*)self.view scrollView] zoomScale];
        NSLog(@"zoomScale %f", _zoomScale);
        // 1.000000 indicates an initial zoom
        if (_zoomScale != 1.000000) {
            zoomScale = _zoomScale;
        }
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:documentName ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:path];
    //NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //NSURLRequest *original = [((MyWKWebView*)self.view) request];
    NSURL *originalURL = [((MyWKWebView*)self.view) URL];
    // load a new page only (avoid zoom reset on active)
    if (originalURL) {
        //NSURL *originalURL = [original URL];
        NSString *originalPath = [originalURL path];
        if (![originalPath isEqualToString:path]) {
            // iOS 5.0 or later supports this
            if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
                [[(MyWKWebView*)self.view scrollView] setHidden:YES];
            }
            //[(MyWKWebView*)self.view loadRequest:request];
            [(MyWKWebView*)self.view loadFileURL:url allowingReadAccessToURL:url];
            newPage = YES;
            tick = TICK;
        }
    } else {
        // iOS 5.0 or later supports this
        if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
            [[(MyWKWebView*)self.view scrollView] setHidden:YES];
        }
        //[(MyWKWebView*)self.view loadRequest:request];
        [(MyWKWebView*)self.view loadFileURL:url allowingReadAccessToURL:url];
        newPage = YES;
        tick = TICK;
    }
}

#define IPADPADDING 4.0f
-(void)goBackPage
{
    //NSURLRequest *current = [(MyWKWebView*)self.view request];
    //NSURL *url = [current URL];
    NSURL *url = [(MyWKWebView*)self.view URL];
    if ([url isFileURL]) {
        if (pageMin < page) {
            page--;
            [self gotoPage:page];
        }
    } else {
        if ([(MyWKWebView*)self.view canGoBack]) {
            [(MyWKWebView*)self.view goBack];
        }
    }
    contentOffset.x = contentOffset.y = 0.0f;
    
    // iOS 5.0 or later supports this
    // set to the bottom-right corner
    if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        CGRect bounds = [[(MyWKWebView*)self.view scrollView] bounds];
        CGSize csize = [[(MyWKWebView*)self.view scrollView] contentSize];
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
    //NSURLRequest *current = [(MyWKWebView*)self.view request];
    //NSURL *url = [current URL];
    NSURL *url = [(MyWKWebView*)self.view URL];
    if ([url isFileURL]) {
        if (page < pageMax) {
            page++;
            [self gotoPage:page];
        }
    } else {
        if ([(MyWKWebView*)self.view canGoForward]) {
            [(MyWKWebView*)self.view goForward];
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
    [(MyWKWebView*)self.view setNavigationDelegate:nil];
    [(MyWKWebView*)self.view setUIDelegate:nil];

    [watchDogTimer invalidate];
	[watchDogTimer release];
    [super dealloc];
}

- (IBAction)speechTest:(id)sender
{
    NSOperatingSystemVersion version = {10, 0, 0};
    BOOL isOSVersion10orLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
    if (isOSVersion10orLater) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            EfiteSpeechTestViewController *controller = [[[EfiteSpeechTestViewController alloc] initWithNibName:@"EfiteSpeechTestViewController_iPhone" bundle:nil] autorelease];
            controller.modalPresentationStyle = UIModalPresentationFullScreen; // iOS13+
            controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentViewController:controller animated:YES completion:nil];
        } else {
            EfiteSpeechTestViewController *controller = [[[EfiteSpeechTestViewController alloc] initWithNibName:@"EfiteSpeechTestViewController_iPad" bundle:nil] autorelease];
            controller.modalPresentationStyle = UIModalPresentationFullScreen; // iOS13+
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
    controller.modalPresentationStyle = UIModalPresentationFullScreen; // iOS13+
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    //controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:controller animated:YES completion:nil];
    //[self showDetailViewController:controller sender:self];
    [controller selectPage: page]; // show the current page selection
}

//WKNavigationDelegate
- (void)webView:(WKWebView *)webView
    didCommitNavigation:(WKNavigation *)navigation
{
    [activity startAnimating];
}

- (void)stopActivityAnimation
{
    [activity stopAnimating];
}

//WKNavigationDelegate
- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation
{
    [activity stopAnimating];
        
    // hide nav buttons on iPhone/iPod when showing an Internet page for page controls
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //NSURLRequest *current = [(MyWKWebView*)self.view request];
        //NSURL *url = [current URL];
        NSURL *url = [(MyWKWebView*)self.view URL];
        if ([url isFileURL]) {
            [buttonRight setHidden:NO];
            [buttonLeft setHidden:NO];
        } else {
            [buttonRight setHidden:YES];
            [buttonLeft setHidden:YES];
        }
    }
}

//WKNavigationDelegate
// this dialog is added for version 1.3, changed to UIAlertController for 1.4.
- (void)webView:(WKWebView *)webView
    didFailNavigation:(WKNavigation *)navigation
    withError:(NSError *)error
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
    if (newPage && ![(MyWKWebView*)self.view isLoading]) {
        if (0 < tick) {
            tick--;  // wait for rendering is done after loading is done
        } else {
            // iOS 5.0 or later supports this
            if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
                [[(MyWKWebView*)self.view scrollView] setZoomScale:zoomScale animated:NO];
                [[(MyWKWebView*)self.view scrollView] setContentOffset:contentOffset animated:NO];
                [[(MyWKWebView*)self.view scrollView] setHidden:NO];
            }
            newPage = NO;
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)sview
{
    if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        previous = [[(MyWKWebView*)self.view scrollView] contentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sview willDecelerate:(BOOL)decelerate
{
    if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        CGPoint offset = [[(MyWKWebView*)self.view scrollView] contentOffset];
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
    NSLog(@"saveData");
	NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
	
	NSNumber* pageObj = [NSNumber numberWithInt:page];
	[dic setObject:pageObj forKey:kcurrentPage];
	NSString* bookObj = [NSString stringWithUTF8String: "1.3"];  // current book version
	[dic setObject:bookObj forKey:kbookVersion];
    NSNumber* newsObj = [NSNumber numberWithInt:newsFlag];
    [dic setObject:newsObj forKey:knewsFlag];
    
	[dic writeToFile:[self dataFilePath] atomically:YES];
	[dic release];
    
    // iOS 5.0 or later supports this
    if ([(MyWKWebView*)self.view respondsToSelector:@selector(scrollView)]) {
        zoomScale = [[(MyWKWebView*)self.view scrollView] zoomScale];
        NSLog(@"zoomScale %f", zoomScale);
    }
}

- (void)restoreData {
    NSLog(@"restoreData");
    // hack to get a good view with WKWebView
    [self loadView];
    
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
            /*
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"新機能：発音練習付き"
                                                                           message:@"２本指タップで開始　iOS10以上"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"了解" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
             */
            newsFlag = 1;
        }
		
		[dic release];
	} else {
        [self gotoPage: page];  // load the initial page
    }
}

@end
