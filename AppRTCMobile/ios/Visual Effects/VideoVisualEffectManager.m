//
//  LocalVideoVisualEffectManager.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "VideoVisualEffectManager.h"
#import "VisualEffect.h"
#import "ARDCaptureController.h"
#import "VisualEffectMessageChannel.h"

@interface VideoVisualEffectManager () <VisualEffectMessageChannelDelegate>

@property (nonatomic) VisualEffectMessageChannel *channel;
@property (nonatomic) ARDCaptureController *captureController;
@property (nonatomic) NSArray<VisualEffect *> *visualEffects;
@property (nonatomic) NSDictionary<NSString *, VisualEffect *> *visualEffectMap;

@end

@implementation VideoVisualEffectManager

- (instancetype)initWithCaptureController:(ARDCaptureController *)capture
                                  channel:(VisualEffectMessageChannel *)channel; {
  self = [super init];
  if (self) {
    _captureController = capture;
    _channel = channel;
    _visualEffects = @[[[ColorInvertEffect alloc] init], [[MonoEffect alloc] init]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (VisualEffect *effect in _visualEffects) {
      dict[effect.descriptor.key] = effect;
    }
    _visualEffectMap = [dict copy];
    [channel addDelegate:self];
  }
  return self;
}

- (void)dealloc{
  [_channel removeDelegate:self];
}

- (NSArray<VisualEffectDescriptor *> *)effects {
  NSMutableArray *result = [NSMutableArray array];
  for (VisualEffect *effect in self.visualEffects) {
    [result addObject:effect.descriptor];
  }
  return [result copy];
}

- (VisualEffectDescriptor *)appliedEffect {
  return self.captureController.visualEffect.descriptor;
}

- (void)applyEffectIfAvailable:(nullable VisualEffectDescriptor *)descriptor {
  if (!descriptor) {
    self.captureController.visualEffect = nil;
    [self notifyCurrentVisualEffect];
    [self notifyUpdateIfNeeded];
  } else if (self.visualEffectMap[descriptor.key]) {
    self.captureController.visualEffect = self.visualEffectMap[descriptor.key];
    [self notifyCurrentVisualEffect];
    [self notifyUpdateIfNeeded];
  }
}

- (void)messageChannel:(VisualEffectMessageChannel *)channel
     didReceiveMessage:(VisualEffectMessage *)message {
  if (![message isKindOfClass:[UpstreamMessage class]]) { return; }
  if ([message isKindOfClass:[SetEffectMessage class]]) {
    SetEffectMessage *req = (SetEffectMessage *)message;
    [self applyEffectIfAvailable:req.effect];
  } else if ([message.command isEqualToString:kGetEffectRequest]) {
    [self notifyCurrentVisualEffect];
  } else if ([message.command isEqualToString:kGetEffectListRequest]) {
    [self notifyVisualEffects];
  }
}

- (void)notifyUpdateIfNeeded {
  if (self.updateBlock) {
    self.updateBlock();
  }
}

- (void)notifyCurrentVisualEffect {
  [self.channel sendMessage:[[AppliedEffectMessage alloc] initWithEffect:self.appliedEffect]];
}

- (void)notifyVisualEffects {
  [self.channel sendMessage:[[EffectListMessage alloc] initWithEffects:self.effects]];
}

@end
