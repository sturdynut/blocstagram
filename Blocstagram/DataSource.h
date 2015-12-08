//
//  DataSource.h
//  Blocstagram
//
//  Created by Matti Salokangas on 12/2/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Media;

@interface DataSource : NSObject

+ (instancetype) sharedInstance;

@property (nonatomic, strong, readonly) NSMutableArray *mediaItems;

- (void) deleteMediaItem:(Media *)item;

@end
