//
//  VideoRecordingSession.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/13.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "VideoRecordingSession.h"
#import "MovieFileURLGenerator.h"

@interface VideoRecordingSession ()
@property (nonatomic, assign) int32_t startTime;
@property (nonatomic) AVAssetWriter *assetWriter;
@property (nonatomic) AVAssetWriterInput *videoInput;
@property (nonatomic, assign) CGSize videoDimension;
@property BOOL isRecording;

@end

@implementation VideoRecordingSession


- (void)setSize:(CGSize)size {
}

- (void)startRecording {
  if (self.assetWriter) { return; }
  self.isRecording = YES;
}

- (void)stopRecording {
  if (!self.assetWriter || !self.isRecording) { return; }
  self.isRecording = NO;
  [self finishWriting];
}

- (void)finishWriting {
  [self.videoInput markAsFinished];
  __weak VideoRecordingSession *weakSelf = self;
  [self.assetWriter finishWritingWithCompletionHandler:^{
    VideoRecordingSession *strongSelf = weakSelf;
    [strongSelf didFinishWriting];
  }];
}

- (void)didFinishWriting {
  _outputURL = self.assetWriter.outputURL;
  [self notifyFinish];
}

- (void)notifyFinish {
  if (self.completion) {
    self.completion();
  }
}

- (void)renderFrame:(RTCVideoFrame *)frame {
  if (!self.isRecording) { return; }
  if (!self.assetWriter) {
    AVAssetWriter *writer = [self prepareAssetWriterWithInitialFrame:frame];
    if (!writer) { return; }
    self.assetWriter = writer;
  }
  [self recordFrame:frame];
}

- (AVAssetWriter *)prepareAssetWriterWithInitialFrame:(RTCVideoFrame *)frame {
  NSError *outError;
  AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:[MovieFileURLGenerator.sharedInstance generateFileURL] fileType:AVFileTypeQuickTimeMovie error:&outError];
  if (outError) {
    return nil;
  }
  AVAssetWriterInput *input = [self prepareVideoInputWithInitialFrame:frame];
  if (![assetWriter canAddInput:input]) {
    return nil;
  }
  self.videoDimension = CGSizeMake(frame.width, frame.height);
  [assetWriter addInput:input];
  if (![assetWriter startWriting]) {
    [self invalidateWithError:assetWriter.error];
    return nil;
  }
  self.videoInput = input;
  return assetWriter;
}

- (AVAssetWriterInput *)prepareVideoInputWithInitialFrame:(RTCVideoFrame *)frame {
  AVAssetWriterInput *input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                             outputSettings:@{AVVideoCodecKey: AVVideoCodecTypeH264,
                                                                              AVVideoWidthKey: @(frame.width),
                                                                              AVVideoHeightKey: @(frame.height)}];
  input.transform = CGAffineTransformRotate(CGAffineTransformIdentity, frame.rotation);
  input.expectsMediaDataInRealTime = YES;
  return input;
}

- (void)invalidateWithError:(NSError *)error {
  self.isRecording = false;
  _error = error;
  [self notifyFinish];
}

- (void)recordFrame:(RTCVideoFrame *)frame {
  if (!self.assetWriter || self.assetWriter.status != AVAssetWriterStatusWriting) {
    return;
  }
  if (self.startTime == 0) {
    CMTime ts;
    ts.timescale = 90000;
    ts.value = 0;
    [self.assetWriter startSessionAtSourceTime:ts];
    self.startTime = frame.timeStamp;
  }
  if (self.videoDimension.width != frame.width || self.videoDimension.height != frame.height) {
    [self stopRecording];
    return;
  }
  CMSampleBufferRef buf = [self convertToCMSampleBufferFromVideoFrame:frame];
  if (buf && self.videoInput.isReadyForMoreMediaData) {
    [self.videoInput appendSampleBuffer:buf];
  }
}

- (CMSampleBufferRef)convertToCMSampleBufferFromVideoFrame:(RTCVideoFrame *)frame {
  RTCCVPixelBuffer *rtcBuf = (RTCCVPixelBuffer *)frame.buffer;
  CVPixelBufferRef imgBuf = rtcBuf.pixelBuffer;

  CMVideoFormatDescriptionRef format;
  if (CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, imgBuf, &format) != noErr) {
    return nil;
  }
  
  CMSampleTimingInfo timingInfo;
  timingInfo.duration = kCMTimeInvalid;
  timingInfo.decodeTimeStamp = kCMTimeInvalid;
  CMTime ts;
  ts.timescale = 90000;
  ts.value = frame.timeStamp - self.startTime;
  timingInfo.presentationTimeStamp = ts;

  CMSampleBufferRef outBuf;
  if (CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, imgBuf, format, &timingInfo, &outBuf) != noErr) {
    return nil;
  }
  return outBuf;
}

@end
