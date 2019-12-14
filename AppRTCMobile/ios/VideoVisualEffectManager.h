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

@class ARDCaptureController;
@interface VideoVisualEffectManager : NSObject <VideoVisualEffectManaging>

@property (nonatomic) ARDCaptureController *captureController;
@property (nonatomic, readonly) NSArray<VisualEffectDescriptor *> *effects;
@property (nonatomic, nullable) VisualEffectDescriptor *appliedEffect;

@end

NS_ASSUME_NONNULL_END
