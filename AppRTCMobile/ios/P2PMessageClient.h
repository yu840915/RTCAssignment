//
//  P2PMessageClient.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "P2PMessage.h"

NS_ASSUME_NONNULL_BEGIN

@class P2PMessageClient;
@protocol P2PMessageClientDelegate <NSObject>

- (void)messageClient:(P2PMessageClient *)client didReceiveMessage:(P2PMessage *)message;

@end

@interface P2PMessageClient : NSObject

@property (nonatomic, weak) id<P2PMessageClientDelegate> delegate;
- (void)sendMessage:(P2PMessage *)message;

@end

NS_ASSUME_NONNULL_END
