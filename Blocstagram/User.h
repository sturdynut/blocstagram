//
//  User.h
//  Blocstagram
//
//  Created by Matti Salokangas on 12/2/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface User : NSObject

@property (nonatomic, strong) NSString *idNumber;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSURL *profilePictureURL;
@property (nonatomic, strong) UIImage *profilePicture;

-(instancetype) initWithDictionary:(NSDictionary *)userDictionary;

@end
