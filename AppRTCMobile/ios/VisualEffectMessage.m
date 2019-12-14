//
//  P2PMessage.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "VisualEffectMessage.h"
@import WebRTC;
#import "VisualEffect.h"

static NSString * const kCommandKey = @"cmd";
static NSString * const kEffectKey = @"effect";
static NSString * const kEffectListKey = @"list";

NSString * const kGetEffectRequest = @"req.get.effect";
NSString * const kGetEffectListRequest = @"req.get.effects";
NSString * const kSetEffectRequest = @"req.put.effects";
NSString * const kEffectResponse = @"res.get.effect";
NSString * const kEffectListResponse = @"res.get.effects";


@interface VisualEffectMessage ()

- (instancetype)initWithJSONObject:(NSDictionary *)json;
- (NSDictionary *)jsonObject;

@end

@implementation VisualEffectMessage

+ (instancetype)messageWithDataBuffer:(RTCDataBuffer *)buffer {
  if (![buffer data]) {return nil;}
  NSError *outError;
  NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:[buffer data] options:NSJSONReadingFragmentsAllowed error:&outError];
  if (![obj isKindOfClass:NSDictionary.class] || outError) { return nil;}
  NSString *cmd = obj[kCommandKey];
  if (cmd.length == 0) {return nil; }
  return [self messageForCommand:cmd withJSONObject:obj];
}

+ (instancetype)messageForCommand:(NSString *)cmd
                   withJSONObject:(NSDictionary *)json {
  NSDictionary<NSString *, Class> *map = @{
    kGetEffectRequest: [UpstreamMessage class],
    kGetEffectListRequest: [UpstreamMessage class],
    kSetEffectRequest: [SetEffectMessage class],
    kEffectResponse: [kEffectResponse class],
    kEffectListResponse: [kEffectListResponse class]
  };
  if (!map[cmd]) {return nil;}
  return [(VisualEffectMessage *)[map[cmd] alloc] initWithJSONObject:json];
}

  
- (instancetype)initWithJSONObject:(NSDictionary *)json {
  NSParameterAssert(json[kCommandKey]);
  self = [super init];
  if (self) {
    _command = json[kCommandKey];
  }
  return self;
}

- (instancetype)initWithCommand:(NSString *)command {
  NSParameterAssert(command);
  self = [super init];
  if (self) {
    _command = [command copy];
  }
  return self;
}

- (NSDictionary *)jsonObject {
  return @{kCommandKey: _command};
}

- (RTCDataBuffer *)toDataBuffer {
  NSError *outError;
  NSDictionary *dict = [self jsonObject];
  NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&outError];
  if (outError) {
    NSLog(@"[Error] Cannot serialize message of command: %@, content: %@", self.command, dict);
    return nil;
  }
  if (data) {
    return [[RTCDataBuffer alloc] initWithData:data isBinary:YES];
  }
  return nil;
}

@end

@implementation UpstreamMessage
@end

@implementation SetEffectMessage

- (instancetype)initWithJSONObject:(NSDictionary *)json {
  self = [super initWithJSONObject:json];
  if (self) {
    if (!json[kEffectKey]) {
      _effect =  nil;
    } else {
      NSDictionary *dict = json[kEffectKey];
      if ([dict isKindOfClass:[NSDictionary class]]) {
        _effect = [VisualEffectDescriptor descriptorWithJSONObject:json];
      }
      if (!_effect) {
        self = nil;
        return nil;
      }
    }
  }
  return self;
}

- (instancetype)initWithEffect:(VisualEffectDescriptor *)effect {
  self = [super initWithCommand:kSetEffectRequest];
  if (self) {
    _effect = effect;
  }
  return self;
}

- (NSDictionary *)jsonObject {
  if (!self.effect) {return [super jsonObject];}
  NSMutableDictionary *result = [[super jsonObject] mutableCopy];
  result[kEffectKey] = [self.effect toJSONObject];
  return [result copy];
}
@end

@implementation DownstreamMessage
@end

@implementation AppliedEffectMessage

- (instancetype)initWithJSONObject:(NSDictionary *)json {
  self = [super initWithJSONObject:json];
  if (self) {
    if (!json[kEffectKey]) {
      _effect =  nil;
    } else {
      NSDictionary *dict = json[kEffectKey];
      if ([dict isKindOfClass:[NSDictionary class]]) {
        _effect = [VisualEffectDescriptor descriptorWithJSONObject:json];
      }
      if (!_effect) {
        self = nil;
        return nil;
      }
    }
  }
  return self;
}

- (instancetype)initWithEffect:(VisualEffectDescriptor *)effect {
  self = [super initWithCommand:kEffectResponse];
  if (self) {
    _effect = effect;
  }
  return self;
}

- (NSDictionary *)jsonObject {
  if (!self.effect) {return [super jsonObject];}
  NSMutableDictionary *result = [[super jsonObject] mutableCopy];
  result[kEffectKey] = [self.effect toJSONObject];
  return [result copy];
}
@end

@implementation EffectListMessage

- (instancetype)initWithJSONObject:(NSDictionary *)json {
  self = [super initWithJSONObject:json];
  if (self) {
    if (!json[kEffectListKey]) {
      _effects = @[];
    } else {
      NSArray *list = json[kEffectListKey];
      if (![list isKindOfClass:[NSArray class]]) {
        self = nil;
        return nil;
      }
      NSMutableArray *container = [NSMutableArray array];
      for (NSDictionary *dict in list) {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        VisualEffectDescriptor *e = [VisualEffectDescriptor descriptorWithJSONObject:dict];
        if (e) {
          [container addObject:e];
        }
      }
      _effects = [container copy];
    }
  }
  return self;
}


- (instancetype)initWithEffects:(NSArray<VisualEffectDescriptor *> *)effects {
  self = [super initWithCommand:kEffectListResponse];
  if (self) {
    _effects = [effects copy];
  }
  return self;
}

@end
