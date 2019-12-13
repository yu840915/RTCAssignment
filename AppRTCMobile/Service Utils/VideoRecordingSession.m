//
//  VideoRecordingSession.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/13.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "VideoRecordingSession.h"

@interface VideoRecordingSession ()
@property (nonatomic, assign) int32_t startTime;

@end

@implementation VideoRecordingSession


- (void)setSize:(CGSize)size {
}


- (void)renderFrame:(RTCVideoFrame *)frame {
  [self recordFrame:frame];
}

- (void)recordFrame:(RTCVideoFrame *)frame {
  if (self.startTime == 0) {
    self.startTime = frame.timeStamp;
  }
  CMSampleBufferRef buf = [self convertToCMSampleBufferFromVideoFrame:frame];
  if (buf) {
    
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
