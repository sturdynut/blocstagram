//
//  ImagesTableViewController.m
//  Blocstagram
//
//  Created by Matti Salokangas on 11/12/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import "ImagesTableViewController.h"
#import "DataSource.h"
#import "User.h"
#import "Media.h"
#import "Comment.h"

@implementation ImagesTableViewController

-(id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    
    return self;
}

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"imageCell"];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DataSource sharedInstance].mediaItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell" forIndexPath:indexPath];
    
    static NSInteger imageViewTag = 1234;
    UIImageView *imageView = (UIImageView*)[cell.contentView viewWithTag:imageViewTag];
    
    if (!imageView) {
        // New cell
        imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.frame = cell.contentView.bounds;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        imageView.tag = imageViewTag;
        
        [cell.contentView addSubview:imageView];
    }
    
    Media *item = [DataSource sharedInstance].mediaItems[indexPath.row];
    imageView.image = item.image;
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Media *item = [DataSource sharedInstance].mediaItems[indexPath.row];
    UIImage *image = item.image;
    
    return (CGRectGetWidth(self.view.frame) / image.size.width) * image.size.height;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return true;
}

@end
