//
//  ShareManager.m
//  Blocstagram
//
//  Created by Matti Salokangas on 12/24/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import "ShareManager.h"
#import "Media.h"
#import "MediaTableViewCell.h"

@implementation ShareManager
+ (void) sharePhoto:(Media *)mediaItem imageView:(UIImageView *)imageView viewController:(UIViewController *)viewController {
    NSMutableArray *itemsToShare = [NSMutableArray array];
    
    if (mediaItem.caption.length > 0) {
        [itemsToShare addObject:mediaItem.caption];
    }
    
    if (mediaItem.image) {
        [itemsToShare addObject:mediaItem.image];
    }
    
    if (itemsToShare.count > 0) {
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        [viewController presentViewController:activityVC animated:YES completion:nil];
    }
}
@end
