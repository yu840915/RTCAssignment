//
//  VisualEffectMessageChannel.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VisualEffectMessage.h"

NS_ASSUME_NONNULL_BEGIN

@class VisualEffectMessageChannel;
@protocol VisualEffectMessageChannelDelegate <NSObject>

- (void)messageChannel:(VisualEffectMessageChannel *)channel didReceiveMessage:(VisualEffectMessage *)message;
@optional
- (void)messageChannelBecomeReady:(VisualEffectMessageChannel *)channel;

@end

@interface VisualEffectMessageChannel : NSObject

@property (nonatomic, assign) BOOL isReady;
- (void)addDelegate:(id<VisualEffectMessageChannelDelegate>)delegate;
- (void)removeDelegate:(id<VisualEffectMessageChannelDelegate>)delegate;
- (void)sendMessage:(VisualEffectMessage *)message;

@end

NS_ASSUME_NONNULL_END
