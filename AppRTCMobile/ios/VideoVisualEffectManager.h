//
//  VideoVisualEffectManager.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoVisualEffectManaging.h"

NS_ASSUME_NONNULL_BEGIN

@class ARDCaptureController, VisualEffectMessageChannel;
@interface VideoVisualEffectManager : NSObject <VideoVisualEffectManaging>

- (instancetype)initWithCaptureController:(ARDCaptureController *)capture channel:(VisualEffectMessageChannel *)channel;
@property (nonatomic, copy) VideoVisualEffectUpdateBlock updateBlock;
@property (nonatomic, readonly) NSArray<VisualEffectDescriptor *> *effects;
@property (nonatomic, readonly, nullable) VisualEffectDescriptor *appliedEffect;

@end

NS_ASSUME_NONNULL_END
