//
//  ShareManager.h
//  Blocstagram
//
//  Created by Matti Salokangas on 12/24/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Media, MediaTableViewCell;

@interface ShareManager : NSObject

+ (void) sharePhoto:(Media *)mediaItem imageView:(UIImageView *)imageView viewController:(UIViewController *)viewController;
    
@end
