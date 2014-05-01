#import "UIImage+blurredImage.h"
#import <tgmath.h>
#import <Accelerate/Accelerate.h>

@implementation UIImage (blurredImage)

#pragma mark - Constants

static const CGFloat kBlurRadius = 20;
static const CGFloat kSaturationFactor = 1.8;
static const CGFloat kTintColor[4] = { 0.11, 0.11, 0.11, 0.73 };
static const int32_t kDivisor = 256;
static int16_t kSaturationMatrix[4*4];
static int32_t kTintBias[4];

#pragma mark - Init

+ (void)initialize
{
    [super initialize];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self calculateSaturationMatrixAndBias];
    });
}

#pragma mark - Public

- (UIImage *)blurredImage:(BOOL)opaque
{
    if (!self.CGImage) {
        return nil;
    }

    // create an input context and draw ourselves into it
    UIGraphicsBeginImageContextWithOptions(self.size, opaque, self.scale);
    [self drawIntoCurrentContext];
    vImage_Buffer inBuffer = [self vImageFromCurrentContext];

    // create an output context to blur the image into
    UIGraphicsBeginImageContextWithOptions(self.size, opaque, self.scale);
    vImage_Buffer outBuffer = [self vImageFromCurrentContext];

    // blur into the outBuffer
    [self blurInput:inBuffer toOutput:outBuffer];

    // saturate and tint the image back to the inBuffer
    [self saturateAndTintInput:outBuffer toOutput:inBuffer];

    // throw away the output buffer
    UIGraphicsEndImageContext();

    // get the image from the context and clean up
    UIImage *blurredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return blurredImage;
}

#pragma mark - Private

+ (void)calculateSaturationMatrixAndBias
{
    const CGFloat s = kSaturationFactor;
    const CGFloat floatingPointSaturationMatrix[] = {
        0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
        0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
        0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
        0,                    0,                    0,                    1,
    };

    const NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix) / sizeof(floatingPointSaturationMatrix[0]);
    const CGFloat tintAlpha = kTintColor[3];
    const CGFloat alphaFactor = 1 - tintAlpha;  // by scaling the saturation matrix, we pre apply the tint blending
    for (NSUInteger i = 0; i < matrixSize; i++) {
        kSaturationMatrix[i] = (int16_t) round(alphaFactor * floatingPointSaturationMatrix[i] * kDivisor);
    }

    // the bias is used to tint the output image after saturation
    // the tint color needs to be alpha premultiplied and scaled to post multiplication range
    for (NSUInteger i = 0; i < 4; i++) {
        const CGFloat alphaFactor = i < 3 ? tintAlpha : 1;
        kTintBias[i] = (int32_t) round(alphaFactor * kTintColor[i] * kDivisor * kDivisor);
    }
}

- (void)drawIntoCurrentContext
{
    CGContextRef inCtx = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(inCtx, 1.0, -1.0);
    CGContextTranslateCTM(inCtx, 0, -self.size.height);
    CGContextDrawImage(inCtx, (CGRect){ CGPointZero, self.size }, self.CGImage);
}

- (vImage_Buffer)vImageFromCurrentContext
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    vImage_Buffer buffer;
    buffer.data     = CGBitmapContextGetData(ctx);
    buffer.width    = CGBitmapContextGetWidth(ctx);
    buffer.height   = CGBitmapContextGetHeight(ctx);
    buffer.rowBytes = CGBitmapContextGetBytesPerRow(ctx);
    return buffer;
}

- (uint32_t)blurRadius
{
    // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
    CGFloat inputRadius = kBlurRadius * self.scale;
    uint32_t radius = floor(inputRadius * 3.0 * sqrt(2 * M_PI) / 4 + 0.5);
    if (radius % 2 != 1) {
        radius += 1; // force radius to be odd so that the three box-blur methodology works.
    }
    return radius;
}

- (void)blurInput:(vImage_Buffer)inBuffer toOutput:(vImage_Buffer)outBuffer
{
    uint32_t blurRadius = [self blurRadius];

    // create a temporary buffer for the box convolving
    vImage_Error err;
    err = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, blurRadius, blurRadius, 0, kvImageEdgeExtend | kvImageGetTempBufferSize);
    NSAssert(err > 0, @"failed to calculate convolve temp buffer size");
    uint8_t *tempBuffer = malloc(err);

    // apply the blur
    vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, tempBuffer, 0, 0, blurRadius, blurRadius, 0, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&outBuffer, &inBuffer, tempBuffer, 0, 0, blurRadius, blurRadius, 0, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, tempBuffer, 0, 0, blurRadius, blurRadius, 0, kvImageEdgeExtend);

    free(tempBuffer);
}

- (void)saturateAndTintInput:(vImage_Buffer)inBuffer toOutput:(vImage_Buffer)outBuffer
{
    vImageMatrixMultiply_ARGB8888(&inBuffer, &outBuffer, kSaturationMatrix, kDivisor, NULL, kTintBias, kvImageNoFlags);
}

@end
