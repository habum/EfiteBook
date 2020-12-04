//
//  MyWKWebView.m
//  EfiteBook
//
//  Created by Masayoshi Habu on 8/2/20.
//

#import <Foundation/Foundation.h>
#import "MyWKWebView.h"

@implementation MyWKWebView
- (instancetype)initWithCoder:(NSCoder *)coder
{
    // An initial frame for initialization must be set, but it will be overridden
    // below by the autolayout constraints set in interface builder.
    CGRect frame = [[UIScreen mainScreen] bounds];
    WKWebViewConfiguration *myConfiguration = [WKWebViewConfiguration new];
    
    // Set any configuration parameters here, e.g.
    //myConfiguration.dataDetectorTypes = WKDataDetectorTypeAll;
    //myConfiguration.ignoresViewportScaleLimits = YES;
    //myConfiguration.suppressesIncrementalRendering = YES;
    
    self = [super initWithFrame:frame configuration:myConfiguration];
    
    // Apply constraints from interface builder.
    self.translatesAutoresizingMaskIntoConstraints = NO;
    //self.allowsMagnification = YES;
    //self.allowsBackForwardNavigationGestures = YES;
    
    return self;
}
@end
