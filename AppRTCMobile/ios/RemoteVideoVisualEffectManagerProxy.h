//
//  RemoteVideoVisualEffectManagerProxy.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/15.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoVisualEffectManaging.h"

NS_ASSUME_NONNULL_BEGIN

@class VisualEffectMessageChannel;
@interface RemoteVideoVisualEffectManagerProxy : NSObject <VideoVisualEffectManaging>

- (instancetype)initWithChannel:(VisualEffectMessageChannel *)channel;
@property (nonatomic, readonly) NSArray<VisualEffectDescriptor *> *effects;
@property (nonatomic, readonly, nullable) VisualEffectDescriptor *appliedEffect;
- (void)syncState;

@end

NS_ASSUME_NONNULL_END
