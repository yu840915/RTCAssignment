//
//  VisualEffectMessageChannel.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "VisualEffectMessageChannel.h"
@import WebRTC;

@interface ChannelDelegateHolder : NSObject
- (instancetype)initWithDelegate:(id<VisualEffectMessageChannelDelegate>)delegate;
@property (nonatomic, weak) id<VisualEffectMessageChannelDelegate> delegate;
@end;

@interface VisualEffectMessageChannel () <RTCDataChannelDelegate>

@property (nonatomic) RTCDataChannel *inChannel;
@property (nonatomic) RTCDataChannel *outChannel;
@property (nonatomic) NSArray<ChannelDelegateHolder *> *delegateHolders;

@end

@implementation VisualEffectMessageChannel

- (instancetype)init
{
  self = [super init];
  if (self) {
    _delegateHolders = [NSArray array];
  }
  return self;
}

- (void)addDelegate:(id<VisualEffectMessageChannelDelegate>)delegate {
  NSMutableArray *list = [NSMutableArray array];
  for (ChannelDelegateHolder *holder in self.delegateHolders) {
    if (holder.delegate == delegate) {
      return;
    }
    if (!holder.delegate) {continue;}
    [list addObject:holder];
  }
  [list addObject:[[ChannelDelegateHolder alloc] initWithDelegate:delegate]];
  _delegateHolders = [list copy];
}

- (void)removeDelegate:(id<VisualEffectMessageChannelDelegate>)delegate {
  NSMutableArray *list = [NSMutableArray array];
  for (ChannelDelegateHolder *holder in self.delegateHolders) {
    if (!holder.delegate || holder.delegate == delegate) {
      continue;
    }
    [list addObject:holder];
  }
  _delegateHolders = [list copy];
}

- (void)setOutChannel:(RTCDataChannel *)outChannel {
  _outChannel.delegate = nil;
  _outChannel = outChannel;
  outChannel.delegate = self;
}

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
  VisualEffectMessage *message = [VisualEffectMessage messageWithDataBuffer:buffer];
  if (message) {
    NSLog(@"[Message] %@", message.command);
    for (ChannelDelegateHolder *holder in self.delegateHolders) {
      [holder.delegate messageChannel:self didReceiveMessage:message];
    }
  }
}

- (void)dataChannelDidChangeState:(nonnull RTCDataChannel *)dataChannel {
  NSLog(@"[Message] data channel update state: %@", dataChannel);
  if (self.isReady) {
    for (ChannelDelegateHolder *holder in self.delegateHolders) {
      if ([holder.delegate respondsToSelector:@selector(messageChannelBecomeReady:)]) {
        [holder.delegate messageChannelBecomeReady:self];
      }
    }

  }
}

- (BOOL)isReady {
  return self.inChannel.readyState == RTCDataChannelStateOpen && self.outChannel.readyState == RTCDataChannelStateOpen;
}

@end

@implementation ChannelDelegateHolder

- (instancetype)initWithDelegate:(id<VisualEffectMessageChannelDelegate>)delegate {
  self = [super init];
  if (self) {
    _delegate = delegate;
  }
  return self;
}

@end
