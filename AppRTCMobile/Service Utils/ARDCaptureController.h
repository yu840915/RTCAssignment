/*
 *  Copyright 2017 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <WebRTC/RTCCameraVideoCapturer.h>
@import AVFoundation;

@class ARDSettingsModel, VisualEffect;

// Controls the camera. Handles starting the capture, switching cameras etc.
@interface ARDCaptureController : NSObject

@property(nonatomic, weak) NSObject<AVCaptureVideoDataOutputSampleBufferDelegate> *displayDelegate;
@property(nonatomic) VisualEffect *visualEffect;

- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer
                        settings:(ARDSettingsModel *)settings;
- (void)startCapture;
- (void)stopCapture;
- (void)switchCamera;

@end
