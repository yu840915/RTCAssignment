//
//  VisualEffectMessage.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kGetEffectRequest;
extern NSString * const kGetEffectListRequest;
extern NSString * const kSetEffectRequest;
extern NSString * const kEffectResponse;
extern NSString * const kEffectListResponse;

@class RTCDataBuffer, VisualEffectDescriptor;
@interface VisualEffectMessage : NSObject

+ (instancetype)messageWithDataBuffer:(RTCDataBuffer *)buffer;
- (instancetype)initWithCommand:(NSString *)command;

@property (nonatomic, copy) NSString *command;

- (RTCDataBuffer *)toDataBuffer;

@end

@interface UpstreamMessage : VisualEffectMessage
+ (instancetype)getEffectMessage;
+ (instancetype)getEffectListMessage;
@end

@interface SetEffectMessage : UpstreamMessage
- (instancetype)initWithEffect:(VisualEffectDescriptor *)effect;

@property (nonatomic, readonly) VisualEffectDescriptor *effect;
@end

@interface DownstreamMessage : VisualEffectMessage
@end

@interface AppliedEffectMessage : DownstreamMessage
- (instancetype)initWithEffect:(VisualEffectDescriptor *)effect;

@property (nonatomic, readonly) VisualEffectDescriptor *effect;
@end

@interface EffectListMessage : DownstreamMessage
- (instancetype)initWithEffects:(NSArray<VisualEffectDescriptor *> *)effects;

@property (nonatomic, readonly) NSArray<VisualEffectDescriptor *> *effects;
@end
