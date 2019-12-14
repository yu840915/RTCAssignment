//
//  RemoteVideoVisualEffectManagerProxy.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/15.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "RemoteVideoVisualEffectManagerProxy.h"
#import "VisualEffect.h"
#import "VisualEffectMessageChannel.h"

@interface RemoteVideoVisualEffectManagerProxy ()  <VisualEffectMessageChannelDelegate>
@property (nonatomic) VisualEffectMessageChannel *channel;

@end

@implementation RemoteVideoVisualEffectManagerProxy

- (instancetype)initWithChannel:(VisualEffectMessageChannel *)channel {
  self = [super init];
  if (self) {
    _channel = channel;
    [channel addDelegate:self];
    [self syncState];
  }
  return self;
}

- (void)dealloc {
  [self.channel removeDelegate:self];
}

- (void)syncState {
  [self.channel sendMessage:[UpstreamMessage getEffectListMessage]];
  [self.channel sendMessage:[UpstreamMessage getEffectMessage]];
}

- (void)messageChannel:(nonnull VisualEffectMessageChannel *)channel didReceiveMessage:(nonnull VisualEffectMessage *)message {
  if (![message isKindOfClass:[DownstreamMessage class]]) { return; }
  if ([message isKindOfClass:[AppliedEffectMessage class]]) {
    AppliedEffectMessage *res = (AppliedEffectMessage *)message;
    _appliedEffect = res.effect;
    //notify
  } else if ([message isKindOfClass:[EffectListMessage class]]) {
    EffectListMessage *res = (EffectListMessage *)message;
    _effects = res.effects;
    //notify
  }
}

- (void)applyEffectIfAvailable:(nullable VisualEffectDescriptor *)descriptor {
  [self.channel sendMessage:[[SetEffectMessage alloc] initWithEffect:descriptor]];
}

@end
