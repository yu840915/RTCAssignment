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
@property (nonatomic) AVAssetWriterInputPixelBufferAdaptor *adaptor;
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
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [weakSelf didFinishWriting];
    }];
  }];
}

- (void)didFinishWriting {
  if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
    _outputURL = self.assetWriter.outputURL;
  } 
  [self notifyFinish];
}

- (void)notifyFinish {
  if (self.completion) {
    self.completion();
  }
}

- (void)renderFrame:(RTCVideoFrame *)frame {
  if (!self.isRecording) { return; }
  __weak VideoRecordingSession *weakSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [weakSelf prepareAndRecordFrame:frame];
  }];
}

- (void)prepareAndRecordFrame:(RTCVideoFrame *)frame {
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
  self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input sourcePixelBufferAttributes:nil];
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
  CGFloat angle = 0;
  switch (frame.rotation) {
    case RTCVideoRotation_0:
      angle = 0;
      break;
    case RTCVideoRotation_90:
      angle = M_PI_2;
      break;
    case RTCVideoRotation_180:
      angle = M_PI;
      break;
    case RTCVideoRotation_270:
      angle = -M_PI_2;
      break;
  }
  input.transform = CGAffineTransformMakeRotation(angle);
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
    if (self.assetWriter.status == AVAssetWriterStatusFailed) {
      [self stopRecording];
    }
    return;
  }
  if (self.startTime == 0) {
    CMTime ts = CMTimeMake(frame.timeStamp, 90000);;
    [self.assetWriter startSessionAtSourceTime:ts];
    self.startTime = frame.timeStamp;
  }
  if (self.videoDimension.width != frame.width || self.videoDimension.height != frame.height) {
    [self stopRecording];
    return;
  }
  if (self.videoInput.isReadyForMoreMediaData) {
    RTCCVPixelBuffer *rtcBuf = (RTCCVPixelBuffer *)frame.buffer;
    if (![rtcBuf isKindOfClass:[RTCCVPixelBuffer class]]) {
      [self stopRecording];
      return;
    }
    CVPixelBufferRef imgBuf = rtcBuf.pixelBuffer;
    CMTime ts = CMTimeMake(frame.timeStamp, 90000);
    [self.adaptor appendPixelBuffer:imgBuf withPresentationTime:ts];
  }
}


@end
