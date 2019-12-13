//
//  AVSampleBufferDisplayView.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/13.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "AVSampleBufferDisplayView.h"

@interface AVSampleBufferDisplayView ()

@property (nonatomic, readonly) AVSampleBufferDisplayLayer *displayLayer;

@end

@implementation AVSampleBufferDisplayView

+ (Class)layerClass {
  return [AVSampleBufferDisplayLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.displayLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI_2, 0, 0, 1);
  }
  return self;
}

- (AVSampleBufferDisplayLayer *)displayLayer {
  return (AVSampleBufferDisplayLayer *)self.layer;
}

- (void)enqueueBuffer:(CMSampleBufferRef)buffer {
  if ([self.displayLayer status] == AVQueuedSampleBufferRenderingStatusFailed) {
    [self.displayLayer flush];
  }
  if (self.displayLayer.isReadyForMoreMediaData) {
    [self.displayLayer enqueueSampleBuffer:buffer];
  }
}


@end
