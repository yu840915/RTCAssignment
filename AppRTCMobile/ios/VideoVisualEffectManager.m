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

@interface VideoVisualEffectManager ()

@property (nonatomic) NSArray<VisualEffect *> *visualEffect;
@property (nonatomic) NSDictionary<NSString *, VisualEffect *> *visualEffectMap;

@end

@implementation VideoVisualEffectManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    _visualEffect = @[[[ColorInvertEffect alloc] init], [[MonoEffect alloc] init]];
  }
  return self;
}


- (void)setAppliedEffect:(VisualEffectDescriptor *)appliedEffect {
  
}

- (VisualEffectDescriptor *)appliedEffect {
  return self.captureController.visualEffect.descriptor;
}

@end
