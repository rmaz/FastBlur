//
//  BPViewController.m
//  FastBlur
//
//  Created by Richard on 01/05/2014.
//  Copyright (c) 2014 Big Dot. All rights reserved.
//

#import "BPViewController.h"
#import "UIImage+blurredImage.h"
#import "UIImage+ImageEffects.h"

@interface BPViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *topImageView;
@property (nonatomic, weak) IBOutlet UIImageView *bottomImageView;
@end

@implementation BPViewController

#pragma mark - Constants

static const NSUInteger kNumLoops = 10;

#pragma mark - View Lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    UIImage *image = [UIImage imageNamed:@"tulips_one"];
    self.bottomImageView.image = [self applyFastBlur:image];
    self.topImageView.image = [self applyDarkBlur:image];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self timeImageEffectsWithImage:image];
        [self timeImageEffectsWithImage:[UIImage imageNamed:@"tulips_two"]];
    });
}

#pragma mark - Private

- (void)timeImageEffectsWithImage:(UIImage *)image
{
    NSTimeInterval fastBlurTime = [self timeBlurMethod:^(UIImage *image) {
        [self applyFastBlur:image];
    } withImage:image];

    NSTimeInterval darkBlurTime = [self timeBlurMethod:^(UIImage *image) {
        [self applyDarkBlur:image];
    } withImage:image];

    NSLog(@"\nimage scale: %.1f\nfast blur: %.0f ms\ndark blur: %.0f ms\nfactor: %.1f\n\n",
          image.scale, 1000*fastBlurTime, 1000*darkBlurTime, darkBlurTime / fastBlurTime);
}

- (NSTimeInterval)timeBlurMethod:(void(^)(UIImage *image))blurMethod withImage:(UIImage *)image
{
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

    for (NSUInteger i = 0; i < kNumLoops; i++) {
        @autoreleasepool {
            blurMethod(image);
        }
    }

    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    return end - start;
}

- (UIImage *)applyFastBlur:(UIImage *)image
{
    return [image blurredImage:YES];
}

- (UIImage *)applyDarkBlur:(UIImage *)image
{
    return [image applyDarkEffect];
}

@end
