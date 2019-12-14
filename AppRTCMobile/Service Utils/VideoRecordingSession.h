//
//  VideoRecordingSession.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/13.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>
@import WebRTC;

typedef void (^VideoRecordingSessionCompletionBlock)(void);
NS_ASSUME_NONNULL_BEGIN

@interface VideoRecordingSession : NSObject <RTCVideoRenderer>

@property (nonatomic, readonly) NSError *error;
@property (nonatomic, nullable, readonly) NSURL *outputURL;
@property (nonatomic, nullable, copy) VideoRecordingSessionCompletionBlock completion;
- (void)startRecording;
- (void)stopRecording;

@end

NS_ASSUME_NONNULL_END
