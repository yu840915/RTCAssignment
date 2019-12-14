//
//  VisualEffect.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreImage;

NS_ASSUME_NONNULL_BEGIN

@class VisualEffectDescriptor;
@interface VisualEffect : NSObject
@property (nonatomic, readonly) VisualEffectDescriptor *descriptor;
- (CIImage *)processImage:(CIImage *)image;
@end

@interface ColorInvertEffect : VisualEffect
@end

@interface MonoEffect : VisualEffect
@end

@interface VisualEffectDescriptor : NSObject
- (instancetype)initWithKey:(NSString *)key displayName:(NSString *)name;

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *defaultDisplayName;
@end

NS_ASSUME_NONNULL_END
