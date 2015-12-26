//
//  MediaTableViewCell.h
//  Blocstagram
//
//  Created by Matti Salokangas on 12/6/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media, MediaTableViewCell;

@protocol MediaTableViewCellDelegate <NSObject>

- (void) cell:(MediaTableViewCell *)cell didTapImageView:(UIImageView *)imageView;
- (void) cell:(MediaTableViewCell *)cell didDoubleTouchImageView:(UIImageView *)imageView;
- (void) cell:(MediaTableViewCell *)cell didLongPressImageView:(UIImageView *)imageView;

@end

@interface MediaTableViewCell : UITableViewCell

@property (nonatomic, strong) Media *mediaItem;
@property (nonatomic, weak) id <MediaTableViewCellDelegate> delegate;

+ (CGFloat) heightForMediaItem:(Media *)mediaItem width:(CGFloat)width;

@end
