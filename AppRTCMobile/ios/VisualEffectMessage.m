//
//  P2PMessage.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "VisualEffectMessage.h"
@import WebRTC;

@implementation VisualEffectMessage

- (instancetype)initWithCommand:(NSString *)command {

  self = [super init];
  if (self) {
    _command = [command copy];
  }
  return self;
}

- (NSDictionary *)jsonObject {
  return @{@"cmd": _command};
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
