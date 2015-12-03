//
//  Comment.h
//  Blocstagram
//
//  Created by Matti Salokangas on 12/2/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface Comment : NSObject

@property (nonatomic, strong) NSString *idNumber;
@property (nonatomic, strong) User *from;
@property (nonatomic, strong) NSString *text;

@end