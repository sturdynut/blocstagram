//
//  MediaFullScreenViewController.m
//  Blocstagram
//
//  Created by Matti Salokangas on 12/24/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import "MediaFullScreenViewController.h"
#import "Media.h"
#import "ShareManager.h"

@interface MediaFullScreenViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) Media *media;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
@property (nonatomic, strong) UIButton *shareButton;

@end

@implementation MediaFullScreenViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView = [UIScrollView new];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.scrollView];
    
    self.imageView = [UIImageView new];
    self.imageView.image = self.media.image;
    
    [self.scrollView addSubview:self.imageView];
    
    self.scrollView.contentSize = self.media.image.size;
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFired:)];
    
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapFired:)];
    self.doubleTap.numberOfTapsRequired = 2;
    
    [self.tap requireGestureRecognizerToFail:self.doubleTap];
    
    [self.scrollView addGestureRecognizer:self.tap];
    [self.scrollView addGestureRecognizer:self.doubleTap];
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.shareButton addTarget:self action:@selector(shareClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.shareButton setTitle:NSLocalizedString(@"Share", @"Share") forState:UIControlStateNormal];
    self.shareButton.frame = CGRectMake(0, 20.0, 100.0, 50.0);
    
    [self.scrollView addSubview:self.shareButton];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.scrollView.frame = self.view.bounds;
    
    CGSize scrollViewFrameSize = self.scrollView.frame.size;
    CGSize scrollViewContentSize = self.scrollView.contentSize;
    
    CGFloat scaleWidth = scrollViewFrameSize.width / scrollViewContentSize.width;
    CGFloat scaleHeight = scrollViewFrameSize.height / scrollViewContentSize.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    
    self.scrollView.minimumZoomScale = minScale;
    self.scrollView.maximumZoomScale = 1;
    
    [self positionShareButton];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self centerScrollView];
}

- (instancetype) initWithMedia:(Media *)media {
    self = [super init];
    
    if (self) {
        self.media = media;
    }
    
    return self;
}

- (void) centerScrollView {
    [self.imageView sizeToFit];
    
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - CGRectGetWidth(contentsFrame)) / 2;
    } else {
        contentsFrame.origin.x = 0;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - CGRectGetHeight(contentsFrame)) / 2;
    } else {
        contentsFrame.origin.y = 0;
    }
    
    self.imageView.frame = contentsFrame;
    
    [self positionShareButton];
}

#pragma mark - UIScrollViewDelegate

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerScrollView];
}

#pragma mark - Gesture Recognizers

- (void) tapFired:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) doubleTapFired:(UITapGestureRecognizer *)sender {
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        // #8
        CGPoint locationPoint = [sender locationInView:self.imageView];
        
        CGSize scrollViewSize = self.scrollView.bounds.size;
        
        CGFloat width = scrollViewSize.width / self.scrollView.maximumZoomScale;
        CGFloat height = scrollViewSize.height / self.scrollView.maximumZoomScale;
        CGFloat x = locationPoint.x - (width / 2);
        CGFloat y = locationPoint.y - (height / 2);
        
        [self.scrollView zoomToRect:CGRectMake(x, y, width, height) animated:YES];
        
        [self positionShareButton];
    } else {
        // #9
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
        
        [self positionShareButton];
    }
}

#pragma mark - Custom Methods

- (void) shareClicked {
    [ShareManager sharePhoto:self.media imageView:self.imageView viewController:self];
}

- (void) positionShareButton {
    // Ref: http://stackoverflow.com/questions/8507333/set-view-position-to-top-right-programmatically-in-cocoa-touch
    CGRect frame = self.shareButton.frame;
    
    //align on top right
    CGFloat xPosition = CGRectGetWidth(self.scrollView.frame) - CGRectGetWidth(frame);
    frame.origin = CGPointMake(ceil(xPosition), 0.0);
    self.shareButton.frame = frame;
    
    //autoresizing so it stays at top right (flexible left and flexible bottom margin)
    self.shareButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
}
@end
