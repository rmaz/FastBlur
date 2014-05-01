//
//  FastBlurTests.m
//  FastBlurTests
//
//  Created by Richard on 01/05/2014.
//  Copyright (c) 2014 Big Dot. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIImage+blurredImage.h"

@interface FastBlurTests : XCTestCase

@end

@implementation FastBlurTests
{
    UIImage *testImageOne;
    UIImage *testImageTwo;
}

#pragma mark - Setup & Teardown

- (void)setUp
{
    [super setUp];

    testImageOne = [UIImage imageNamed:@"tulips_one"];
    testImageTwo = [UIImage imageNamed:@"tulips_two"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Tests

- (void)testBlurredImageIsTheSameSize
{
    UIImage *blurredImage = [testImageOne blurredImage:YES];
    XCTAssertTrue(CGSizeEqualToSize(testImageOne.size, blurredImage.size), @"blurred image is the wrong size");

    blurredImage = [testImageTwo blurredImage:YES];
    XCTAssertTrue(CGSizeEqualToSize(testImageTwo.size, blurredImage.size), @"blurred image is the wrong size");
}

- (void)testBlurredImageIsTheSameScale
{
    UIImage *blurredImage = [testImageOne blurredImage:YES];
    XCTAssertEqual(testImageOne.scale, blurredImage.scale, @"blurred image is the wrong scale");

    blurredImage = [testImageTwo blurredImage:YES];
    XCTAssertEqual(testImageTwo.scale, blurredImage.scale, @"blurred image is the wrong scale");
}

- (void)testOpacityOption
{
    UIImage *blurredImage = [testImageOne blurredImage:YES];
    XCTAssertFalse([self imageHasAlpha:blurredImage], @"blurred image should be opaque");

    blurredImage = [testImageOne blurredImage:NO];
    XCTAssertTrue([self imageHasAlpha:blurredImage], @"blurred image should NOT be opaque");
}

#pragma mark - Helpers

- (BOOL)imageHasAlpha:(UIImage *)image
{
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image.CGImage);
    switch (alphaInfo) {
        case kCGImageAlphaNone:
        case kCGImageAlphaNoneSkipLast:
        case kCGImageAlphaNoneSkipFirst:
            return NO;

        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaPremultipliedFirst:
        case kCGImageAlphaLast:
        case kCGImageAlphaFirst:
        case kCGImageAlphaOnly:
            return YES;
    }
}

@end
