//
//  VisualEffect.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "VisualEffect.h"

@interface VisualEffect ()
@property CIFilter *filter;
@end

@implementation VisualEffect

- (VisualEffectDescriptor *)descriptor {
  return [[VisualEffectDescriptor alloc] init];
}

- (CIImage *)processImage:(CIImage *)image {
  [self.filter setValue:image forKey:kCIInputImageKey];
  return [self.filter outputImage];
}

@end

@implementation ColorInvertEffect

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.filter = [CIFilter filterWithName:@"CIColorInvert"];
  }
  return self;
}

- (VisualEffectDescriptor *)descriptor {
  return [[VisualEffectDescriptor alloc] initWithKey:@"color_invert" displayName:@"Invert"];
}

@end

@implementation MonoEffect

- (instancetype)init {
  self = [super init];
  if (self) {
    self.filter = [CIFilter filterWithName:@"CIPhotoEffectMono"];
  }
  return self;
}

- (VisualEffectDescriptor *)descriptor {
  return [[VisualEffectDescriptor alloc] initWithKey:@"photo_mono" displayName:@"Mono"];
}

@end

@implementation VisualEffectDescriptor

- (instancetype)initWithKey:(NSString *)key
                displayName:(NSString *)name {
  self = [super init];
  if (self) {
    _key = [key copy];
    _defaultDisplayName = [name copy];
  }
  return self;
}

@end
