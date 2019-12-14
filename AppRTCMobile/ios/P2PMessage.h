//
//  P2PMessage.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RTCDataBuffer;
@interface P2PMessage : NSObject

- (instancetype)initWithCommand:(NSString *)command;
- (instancetype)initWithDataBuffer:(RTCDataBuffer *)buffer;

@property (nonatomic, copy) NSString *command;

- (RTCDataBuffer *)toDataBuffer;

@end
