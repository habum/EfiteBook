//
//  EfiteFlipsideViewController.m
//  EfiteBook
//
//  Created by Masayoshi Habu on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EfiteFlipsideViewController.h"
#import "EfiteMainViewController.h"

@interface EfiteFlipsideViewController ()

@end

@implementation EfiteFlipsideViewController

@synthesize pageMap;
@synthesize pageNum;

@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
        // self.preferredContentSize = CGSizeMake(320.0, 480.0);
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // populate toc
    NSString *path = [[NSBundle mainBundle] pathForResource:@"EfiteToc" ofType:@"plist"];
    // key = logical page number string dd, value = title string
    self.pageMap = [[NSDictionary alloc] initWithContentsOfFile:path];
    self.pageNum = [[pageMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

//- (void)viewDidUnload
//{
//    [super viewDidUnload];
    // Release any retained subviews of the main view.
    //self.pageMap = nil;
    //self.pageNum = nil;
//}

-(void)dealloc
{
    [pageMap release];
    [pageNum release];
    [super dealloc];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//    } else {
//        return YES;
//    }
//}

#pragma mark - Actions

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [pageMap count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *EfiteTocTableIdentifier = @"EfiteTocTableIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:EfiteTocTableIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:EfiteTocTableIdentifier] autorelease];
    }
    
    NSUInteger row = [indexPath row];
    NSString *key = (NSString*) [self.pageNum objectAtIndex:row];

    cell.textLabel.text = [self.pageMap valueForKey:key];
    cell.detailTextLabel.text = key;

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    NSString *key = (NSString*) [self.pageNum objectAtIndex:row];
    int i = [key intValue];
    [(EfiteMainViewController*)self.delegate gotoPage: i + 1];  // logical to physical page
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self done: self];
}

-(void)selectPage:(int)p
{
    int key = p - 1;  // physical to logical page
    NSInteger row = 0;
    // find the table selection based on page number
    for (NSUInteger r = 0; r < pageNum.count; r++)
    {
        NSString *num = (NSString*)[self.pageNum objectAtIndex:r];
        int i = [num intValue];
        if (key < i) {
            break;
        } else {
            row = (NSInteger) r;
        }
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    UITableView *tableView = (UITableView*)self.view;
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

@end
