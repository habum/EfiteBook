//
//  EfiteFlipsideViewController.h
//  EfiteBook
//
//  Created by Masayoshi Habu on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EfiteFlipsideViewController;

@protocol EfiteFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(EfiteFlipsideViewController *)controller;
@end

@interface EfiteFlipsideViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    NSDictionary *pageMap;
    NSArray *pageNum;
}

@property (nonatomic, retain) NSDictionary *pageMap;
@property (nonatomic, retain) NSArray *pageNum;

@property (assign, nonatomic) id <EfiteFlipsideViewControllerDelegate> delegate;

-(IBAction)done:(id)sender;
-(void)selectPage:(int)p;

@end
