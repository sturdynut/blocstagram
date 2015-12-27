//
//  DataSource.m
//  Blocstagram
//
//  Created by Matti Salokangas on 12/2/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import "DataSource.h"
#import "User.h"
#import "Media.h"
#import "Comment.h"
#import "LoginViewController.h"
#import <UICKeyChainStore.h>
#import <AFNetworking.h>

@interface DataSource()

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSMutableArray *mediaItems;

@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isLoadingOlderItems;
@property (nonatomic, assign) BOOL thereAreNoMoreOlderMessages;

@property (nonatomic, strong) AFHTTPSessionManager *instagramOperationManager;

@end

@implementation DataSource

+ (instancetype) sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (NSString *) instagramClientID {
    return @"c75b8443cdf7421f8f54c1b80cfa74be";
}

- (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    self.thereAreNoMoreOlderMessages = NO;
    
    if (self.isRefreshing == NO) {
        self.isRefreshing = YES;
        
        NSString *minID = [[self.mediaItems firstObject] idNumber];
        NSDictionary *parameters;
        
        if (minID) {
            parameters = @{@"min_id": minID};
        }
        
        [self populateDataWithParameters:parameters completionHandle:^(NSError *error) {
            self.isRefreshing = NO;
            
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    }
}

- (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    if (self.isLoadingOlderItems == NO && self.thereAreNoMoreOlderMessages == NO) {
        self.isLoadingOlderItems = YES;
        
        NSString *maxID = [[self.mediaItems lastObject] idNumber];
        NSDictionary *parameters;
        
        if (maxID) {
            parameters = @{@"max_id": maxID};
        }
        
        [self populateDataWithParameters:parameters completionHandle:^(NSError *error) {
            self.isLoadingOlderItems = NO;
            
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    }
}

- (void) deleteMediaItem:(Media *)item {
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    [mutableArrayWithKVO removeObject:item];
}

- (instancetype) init {
    self = [super init];
    
    if (self) {
        [self createOperationManager];
        
        self.accessToken = [UICKeyChainStore stringForKey:@"access token"];
        
        if (self.accessToken) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *fullPath = [self pathForFilename:NSStringFromSelector(@selector(mediaItems))];
                NSArray *storedMediaItems = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (storedMediaItems.count > 0) {
                        NSMutableArray *mutableMediaItems = [storedMediaItems mutableCopy];
                        
                        [self willChangeValueForKey:@"mediaItems"];
                        self.mediaItems = mutableMediaItems;
                        [self didChangeValueForKey:@"mediaItems"];
                        
                    } else {
                        [self populateDataWithParameters:nil completionHandle:nil];
                    }
                });
            });
        }
        else {
            [self registerForAccessTokenNotification];
        }
    }
    
    return self;
}

- (void) registerForAccessTokenNotification {
    [[NSNotificationCenter defaultCenter] addObserverForName:LoginViewControllerDidGetAccessTokenNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.accessToken = note.object;
        
        [UICKeyChainStore setString:self.accessToken forKey:@"access token"];
        
        // Got a token; populate the initial data
        [self populateDataWithParameters:nil completionHandle:nil];
    }];
}

- (void) populateDataWithParameters:(NSDictionary *)parameters completionHandle:(NewItemCompletionBlock)completionHandler {
    if (self.accessToken) {
        // only try to get the data if there's an access token
        
        NSMutableDictionary *mutableParameters = [@{@"access_token": self.accessToken} mutableCopy];
        
        [mutableParameters addEntriesFromDictionary:parameters];
        
        [self.instagramOperationManager GET:@"users/self/media/recent"
                                 parameters: mutableParameters
                                   progress: nil
                                    success: ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                        if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                            [self parseDataFromFeedDictionary:responseObject fromRequestWithParameters:parameters];
                                        }
                                        
                                        if (completionHandler) {
                                            completionHandler(nil);
                                        }
                                    } failure: ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                        if (completionHandler) {
                                            completionHandler(error);
                                        }
                                    }
         ];
    }
}

- (void) parseDataFromFeedDictionary:(NSDictionary *) feedDictionary fromRequestWithParameters:(NSDictionary *)parameters {

    NSArray *mediaArray = feedDictionary[@"data"];
    
    NSMutableArray *tmpMediaItems = [NSMutableArray array];
    
    for (NSDictionary *mediaDictionary in mediaArray) {
        Media *mediaItem = [[Media alloc] initFromDictionary:mediaDictionary];
        
        if (mediaItem) {
            [tmpMediaItems addObject:mediaItem];
        }
    }
    
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    
    if (parameters[@"min_id"]) {
        // Pull to refresh request
        
        NSRange rangeOfIndexes = NSMakeRange(0, tmpMediaItems.count);
        NSIndexSet *indexSetOfNewObjects = [NSIndexSet indexSetWithIndexesInRange:rangeOfIndexes];
        
        [mutableArrayWithKVO insertObjects:tmpMediaItems atIndexes:indexSetOfNewObjects];
    } else if(parameters[@"max_id"]) {
        // Infinite scroll request
        
        if (tmpMediaItems.count == 0) {
            self.thereAreNoMoreOlderMessages = YES;
        } else {
            [mutableArrayWithKVO addObjectsFromArray:tmpMediaItems];
        }
    }
    else {
        [self willChangeValueForKey:@"mediaItems"];
        self.mediaItems = tmpMediaItems;
        [self didChangeValueForKey:@"mediaItems"];
    }
    
    [self saveImages];
}

- (void) downloadImageForMediaItem:(Media *)mediaItem {
    if (mediaItem.mediaURL && !mediaItem.image) {
        
        mediaItem.downloadState = MediaDownloadStateDownloadInProgress;
        
        [self.instagramOperationManager GET:mediaItem.mediaURL.absoluteString
                                 parameters:nil
                                    success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                        if ([responseObject isKindOfClass:[UIImage class]]) {
                                            mediaItem.image = responseObject;
                                            mediaItem.downloadState = MediaDownloadStateHasImage;
                                            NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
                                            NSUInteger index = [mutableArrayWithKVO indexOfObject:mediaItem];
                                            [mutableArrayWithKVO replaceObjectAtIndex:index withObject:mediaItem];
                                            [self saveImages];
                                        }
                                        else {
                                            mediaItem.downloadState = MediaDownloadStateNonRecoverableError;
                                        }
                                    } failure: ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                        NSLog(@"Error downloading image: %@", error);
                                        
                                        mediaItem.downloadState = MediaDownloadStateNonRecoverableError;
                                        
                                        if (error.code == NSURLErrorTimedOut ||
                                            error.code == NSURLErrorCancelled ||
                                            error.code == NSURLErrorCannotConnectToHost ||
                                            error.code == NSURLErrorNetworkConnectionLost ||
                                            error.code == NSURLErrorNotConnectedToInternet ||
                                            error.code == kCFURLErrorInternationalRoamingOff ||
                                            error.code == kCFURLErrorCallIsActive ||
                                            error.code == kCFURLErrorDataNotAllowed ||
                                            error.code == kCFURLErrorRequestBodyStreamExhausted) {
                                            
                                            // Could try again.
                                            mediaItem.downloadState = MediaDownloadStateNeedsImage;
                                        }
                                    }];
    }
}

#pragma mark - Key/Value Observing (KVO)

- (NSUInteger) countOfMediaItems {
    return self.mediaItems.count;
}

- (id) objectInMediaItemsAtIndex:(NSUInteger)index {
    return [self.mediaItems objectAtIndex:index];
}

- (NSArray *) mediaItemsAtIndexes:(NSIndexSet *)indexes {
    return [self.mediaItems objectsAtIndexes:indexes];
}

- (void) insertObject:(Media *)object inMediaItemsAtIndex:(NSUInteger)index {
    [_mediaItems insertObject:object atIndex: index];
}

- (void) removeObjectFromMediaItemsAtIndex:(NSUInteger)index {
    [_mediaItems removeObjectAtIndex:index];
}

- (void) replaceObjectInMediaItemsAtIndex:(NSUInteger)index withObject:(id)object {
    [_mediaItems replaceObjectAtIndex:index withObject:object];
}

#pragma mark - NSKeyedArchiver

- (NSString *) pathForFilename:(NSString *) filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    return dataPath;
}

- (void) saveImages {
    if (self.mediaItems.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSUInteger numberOfItemsToSave = MIN(self.mediaItems.count, 50);
            NSArray *mediaItemsToSave = [self.mediaItems subarrayWithRange:NSMakeRange(0, numberOfItemsToSave)];
            
            NSString *fullPath = [self pathForFilename:NSStringFromSelector(@selector(mediaItems))];
            NSData *mediaItemData = [NSKeyedArchiver archivedDataWithRootObject:mediaItemsToSave];
            
            NSError *dataError;
            BOOL wroteSuccessfully = [mediaItemData writeToFile:fullPath options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&dataError];
            
            if (!wroteSuccessfully) {
                NSLog(@"Couldn't write file: %@", dataError);
            }
        });
    }
}

#pragma mark - AFNetworking

- (void) createOperationManager {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.instagram.com/v1/"];
    self.instagramOperationManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    
    AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializer];
    
    AFImageResponseSerializer *imageSerializer = [AFImageResponseSerializer serializer];
    imageSerializer.imageScale = 1.0;
    
    AFCompoundResponseSerializer *serializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[jsonSerializer, imageSerializer]];
    self.instagramOperationManager.responseSerializer = serializer;
}

#pragma mark - Comments

- (void) commentOnMediaItem:(Media *)mediaItem withCommentText:(NSString *)commentText {
    if (!commentText || commentText.length == 0) {
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"media/%@/comments", mediaItem.idNumber];
    NSDictionary *parameters = @{@"access_token": self.accessToken, @"text": commentText};
    
    [self.instagramOperationManager POST:urlString parameters:parameters constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        
        mediaItem.temporaryComment = nil;
        
        NSString *refreshMediaUrlString = [NSString stringWithFormat:@"media/%@", mediaItem.idNumber];
        NSDictionary *parameters = @{@"access_token": self.accessToken};
        
        
        [self.instagramOperationManager GET:refreshMediaUrlString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            Media *newMediaItem = [[Media alloc] initFromDictionary:responseObject];
            NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
            NSUInteger index = [mutableArrayWithKVO indexOfObject:mediaItem];
            [mutableArrayWithKVO replaceObjectAtIndex:index withObject:newMediaItem];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self reloadMediaItem:mediaItem];
        }];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        NSLog(@"Response: %@", task.response);
        [self reloadMediaItem:mediaItem];
    }];

}

- (void) reloadMediaItem:(Media *)mediaItem {
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    NSUInteger index = [mutableArrayWithKVO indexOfObject:mediaItem];
    [mutableArrayWithKVO replaceObjectAtIndex:index withObject:mediaItem];
}

@end
