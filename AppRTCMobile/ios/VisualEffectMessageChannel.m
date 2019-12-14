//
//  VisualEffectMessageChannel.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "VisualEffectMessageChannel.h"
@import WebRTC;

@interface VisualEffectMessageChannel () <RTCDataChannelDelegate>

@property (nonatomic) RTCDataChannel *inChannel;
@property (nonatomic) RTCDataChannel *outChannel;

@end

@implementation VisualEffectMessageChannel

- (void)setInChannel:(RTCDataChannel *)inChannel {
  _inChannel.delegate = nil;
  _inChannel = inChannel;
  inChannel.delegate = self;
}

- (void)sendMessage:(VisualEffectMessage *)message {
  RTCDataBuffer *buf = [message toDataBuffer];
  if (buf) {
    [self.outChannel sendData:buf];
  }
}

- (void)dataChannel:(nonnull RTCDataChannel *)dataChannel didReceiveMessageWithBuffer:(nonnull RTCDataBuffer *)buffer {
  NSLog(@"[Message] %@", buffer);
}

- (void)dataChannelDidChangeState:(nonnull RTCDataChannel *)dataChannel {
  NSLog(@"%@, %@", dataChannel, @(dataChannel.readyState));
}

@end
