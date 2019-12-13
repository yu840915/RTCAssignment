//
//  CGImageToCVImageBufferConverter.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/13.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "CGImageToCVImageBufferConverter.h"

@interface CGImageToCVImageBufferConverter ()
@property (nonatomic) CGColorSpaceRef colorSpace;
@end

@implementation CGImageToCVImageBufferConverter

- (instancetype)init
{
  self = [super init];
  if (self) {
    _colorSpace = CGColorSpaceCreateDeviceRGB();
  }
  return self;
}

- (CVImageBufferRef)convertFromCGImage:(CGImageRef)cgImage {
  CVImageBufferRef outBuf = [self createImageBufferForImage:cgImage];
  if (!outBuf) {return nil;}
  CVPixelBufferLockBaseAddress(outBuf, 0);
  CGContextRef context = [self createBitmapContextWithBuffer:outBuf image:cgImage];
  if (context) {
    CGRect rect = CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
    CGContextDrawImage(context, rect, cgImage);
    CVPixelBufferUnlockBaseAddress(outBuf, 0);
    return outBuf;
  } else {
    CVPixelBufferUnlockBaseAddress(outBuf, 0);
    CFRelease(outBuf);
    return nil;
  }
}

- (CVImageBufferRef)createImageBufferForImage:(CGImageRef) cgImage  {
  CVImageBufferRef outBuf;
  NSDictionary *attr = @{(__bridge NSString *)kCVPixelBufferCGImageCompatibilityKey: @(NO),
                       (__bridge NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(NO)};
  OSStatus result = CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef _Nullable)(attr), &outBuf);
  if (result != kCVReturnSuccess) {
    return nil;
  }
  return outBuf;
}

- (CGContextRef)createBitmapContextWithBuffer:(CVImageBufferRef)buffer image:(CGImageRef) cgImage {
  return CGBitmapContextCreate(CVPixelBufferGetBaseAddress(buffer), CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 8, CVPixelBufferGetBytesPerRow(buffer), self.colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
}

@end
