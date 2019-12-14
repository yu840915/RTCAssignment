/*
 *  Copyright 2017 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDCaptureController.h"
@import CoreImage;

#import <WebRTC/RTCLogging.h>

#import "ARDSettingsModel.h"
#import "CGImageToCVImageBufferConverter.h"
#import "VisualEffect.h"


const Float64 kFramerateLimit = 30.0;

@interface ARDCaptureController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property CIContext *renderContext;
@property CGImageToCVImageBufferConverter *bufferConverter;
@end

@interface RTCCameraVideoCapturer () <AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@implementation ARDCaptureController  {
  RTCCameraVideoCapturer *_capturer;
  ARDSettingsModel *_settings;
  BOOL _usingFrontCamera;
}

- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer
                        settings:(ARDSettingsModel *)settings {
  if (self = [super init]) {
    _capturer = capturer;
    _settings = settings;
    _usingFrontCamera = YES;
    _renderContext = [CIContext contextWithEAGLContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    _bufferConverter = [[CGImageToCVImageBufferConverter alloc] init];
    AVCaptureVideoDataOutput *output = (AVCaptureVideoDataOutput *)capturer.captureSession.outputs.firstObject;
    [output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
  }

  return self;
}

- (void)startCapture {
  AVCaptureDevicePosition position =
      _usingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
  AVCaptureDevice *device = [self findDeviceForPosition:position];
  AVCaptureDeviceFormat *format = [self selectFormatForDevice:device];

  if (format == nil) {
    RTCLogError(@"No valid formats for device %@", device);
    NSAssert(NO, @"");

    return;
  }

  NSInteger fps = [self selectFpsForFormat:format];

  [_capturer startCaptureWithDevice:device format:format fps:fps];
}

- (void)stopCapture {
  [_capturer stopCapture];
}

- (void)switchCamera {
  _usingFrontCamera = !_usingFrontCamera;
  [self startCapture];
}

#pragma mark - Private

- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
  NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
  for (AVCaptureDevice *device in captureDevices) {
    if (device.position == position) {
      return device;
    }
  }
  return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device {
  NSArray<AVCaptureDeviceFormat *> *formats =
      [RTCCameraVideoCapturer supportedFormatsForDevice:device];
  int targetWidth = [_settings currentVideoResolutionWidthFromStore];
  int targetHeight = [_settings currentVideoResolutionHeightFromStore];
  AVCaptureDeviceFormat *selectedFormat = nil;
  int currentDiff = INT_MAX;

  for (AVCaptureDeviceFormat *format in formats) {
    CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
    FourCharCode pixelFormat = CMFormatDescriptionGetMediaSubType(format.formatDescription);
    int diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height);
    if (diff < currentDiff) {
      selectedFormat = format;
      currentDiff = diff;
    } else if (diff == currentDiff && pixelFormat == [_capturer preferredOutputPixelFormat]) {
      selectedFormat = format;
    }
  }

  return selectedFormat;
}

- (NSInteger)selectFpsForFormat:(AVCaptureDeviceFormat *)format {
  Float64 maxSupportedFramerate = 0;
  for (AVFrameRateRange *fpsRange in format.videoSupportedFrameRateRanges) {
    maxSupportedFramerate = fmax(maxSupportedFramerate, fpsRange.maxFrameRate);
  }
  return fmin(maxSupportedFramerate, kFramerateLimit);
}

#pragma - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
  CMSampleBufferRef buf = [self applyFilter:sampleBuffer];
  [_capturer captureOutput:output didOutputSampleBuffer:buf fromConnection:connection];
  [self.displayDelegate captureOutput:output didOutputSampleBuffer:buf fromConnection:connection];
}

- (CMSampleBufferRef)applyFilter:(CMSampleBufferRef)sampleBuffer {
  CVImageBufferRef inImgBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
  VisualEffect *effect = self.visualEffect;
  if (!effect) { return sampleBuffer;}
  
  CIImage *outCIImg = [effect processImage:[CIImage imageWithCVImageBuffer:inImgBuf]];
  if (!outCIImg) { return sampleBuffer;}
  
  CGImageRef outCGImg = [self.renderContext createCGImage:outCIImg fromRect:outCIImg.extent];
  if (!outCGImg) { return sampleBuffer;}
  
  CVImageBufferRef outImgBuf = [self.bufferConverter convertFromCGImage:outCGImg];
  if (!outImgBuf) { return sampleBuffer;}
  
  CMSampleBufferRef outBuf = [self createSampleBufferFromImageBuffer:outImgBuf
                                                  withOriginalBuffer:sampleBuffer];
  return outBuf ?: sampleBuffer;
}

- (CMSampleBufferRef)createSampleBufferFromImageBuffer:(CVImageBufferRef)imgBuf
                                    withOriginalBuffer:(CMSampleBufferRef)sampleBuffer {
  CMVideoFormatDescriptionRef format;
  if (CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, imgBuf, &format) != noErr) {
    return nil;
  }
  CMSampleTimingInfo timingInfo;
  if (CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timingInfo) != noErr) {
    return nil;
  }
  CMSampleBufferRef outBuf;
  if (CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, imgBuf, format, &timingInfo, &outBuf) != noErr) {
    return nil;
  }
  CFAutorelease(outBuf);
  return outBuf;
}

- (void)captureOutput:(AVCaptureOutput *)output
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  if ([_capturer respondsToSelector:@selector(captureOutput:didDropSampleBuffer:fromConnection:)]) {
    [_capturer captureOutput:output didDropSampleBuffer:sampleBuffer fromConnection:connection];
  }
}

@end

