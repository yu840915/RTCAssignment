/*
 *  Copyright 2015 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDVideoCallViewController.h"
@import AVFoundation;
@import Photos;

#import <WebRTC/RTCAudioSession.h>
#import <WebRTC/RTCCameraVideoCapturer.h>
#import <WebRTC/RTCDispatcher.h>
#import <WebRTC/RTCLogging.h>
#import <WebRTC/RTCMediaConstraints.h>

#import "ARDAppClient.h"
#import "ARDCaptureController.h"
#import "ARDFileCaptureController.h"
#import "ARDSettingsModel.h"
#import "ARDVideoCallView.h"
#import "AVSampleBufferDisplayView.h"
#import "VideoRecordingSession.h"
#import "VisualEffectMessageChannel.h"
#import "VisualEffect.h"
#import "VideoVisualEffectManager.h"
#import "RemoteVideoVisualEffectManagerProxy.h"
#import "SaveVideoTask.h"

@interface ARDVideoCallViewController () <ARDAppClientDelegate,
                                          ARDVideoCallViewDelegate,
                                          RTCAudioSessionDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, strong) RTCVideoTrack *remoteVideoTrack;
@property(nonatomic, readonly) ARDVideoCallView *videoCallView;
@property(nonatomic, assign) AVAudioSessionPortOverride portOverride;
@property(nonatomic) VideoRecordingSession *recordingSession;
@property(nonatomic) id<VideoVisualEffectManaging> remoteVisualEffectManager;
@property(nonatomic) VideoVisualEffectManager *localVisualEffectManager;
@end

@implementation ARDVideoCallViewController {
  ARDAppClient *_client;
  RTCVideoTrack *_remoteVideoTrack;
  ARDCaptureController *_captureController;
  ARDFileCaptureController *_fileCaptureController NS_AVAILABLE_IOS(10);
}

@synthesize videoCallView = _videoCallView;
@synthesize remoteVideoTrack = _remoteVideoTrack;
@synthesize delegate = _delegate;
@synthesize portOverride = _portOverride;

- (instancetype)initForRoom:(NSString *)room
                 isLoopback:(BOOL)isLoopback
                   delegate:(id<ARDVideoCallViewControllerDelegate>)delegate {
  if (self = [super init]) {
    ARDSettingsModel *settingsModel = [[ARDSettingsModel alloc] init];
    _delegate = delegate;

    _client = [[ARDAppClient alloc] initWithDelegate:self];
    [_client connectToRoomWithId:room settings:settingsModel isLoopback:isLoopback];
    self.modalPresentationStyle = UIModalPresentationFullScreen;
  }
  return self;
}

- (void)loadView {
  _videoCallView = [[ARDVideoCallView alloc] initWithFrame:CGRectZero];
  _videoCallView.delegate = self;
  _videoCallView.statusLabel.text =
      [self statusTextForState:RTCIceConnectionStateNew];
  self.view = _videoCallView;

  RTCAudioSession *session = [RTCAudioSession sharedInstance];
  [session addDelegate:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [_videoCallView.recordButton addTarget:self action:@selector(toggleRecordingIfAllowed:) forControlEvents:UIControlEventTouchUpInside];
  [_videoCallView.localVisualEffectButton addTarget:self action:@selector(showVisualEffectOptionsForLocalVideo:) forControlEvents:UIControlEventTouchUpInside];
  [_videoCallView.remoteVisualEffectButton addTarget:self action:@selector(showVisualEffectOptionsForRemoteVideo:) forControlEvents:UIControlEventTouchUpInside];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

- (void)setRecordingSession:(VideoRecordingSession *)recordingSession {
  _recordingSession = recordingSession;
  __weak ARDVideoCallViewController *weakSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [weakSelf updateViewsForRecording];
  }];
}

- (void)updateViewsForRecording {
  [self.videoCallView.recordButton setSelected:self.recordingSession];
}

- (void)updateViewsForVisualEffectStates {
  NSString *lEffect = self.localVisualEffectManager.appliedEffect.defaultDisplayName ?: @"Effect";
  [self.videoCallView.localVisualEffectButton setTitle:lEffect forState:UIControlStateNormal];

  NSString *rEffect = self.remoteVisualEffectManager.appliedEffect.defaultDisplayName ?: @"Effect";
  [self.videoCallView.remoteVisualEffectButton setTitle:rEffect forState:UIControlStateNormal];
}

#pragma mark - Action

- (void)toggleRecordingIfAllowed:(id)sender {
  __weak ARDVideoCallViewController *weakSelf = self;
  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [weakSelf toggleRecordingOrShowAlertOnAuthorizationStatus:status];
    }];
  }];
}

- (void)toggleRecordingOrShowAlertOnAuthorizationStatus:(PHAuthorizationStatus) status {
  switch (status) {
    case PHAuthorizationStatusNotDetermined:
      break;
    case PHAuthorizationStatusAuthorized:
      [self toggleRecording];
      break;
    case PHAuthorizationStatusDenied:
    case PHAuthorizationStatusRestricted:
      [self showAlertForPhotoLibraryAccess];
      break;
  }
}

- (void)toggleRecording {
  if (!_remoteVideoTrack) {return;}
  if (self.recordingSession) {
    [self stopRecording];
  } else {
    [self startRecording];
  }
}

- (void)showAlertForPhotoLibraryAccess {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot record video" message:@"Please grant access in \"Settings\"" preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:true completion:nil];
}

- (void)showVisualEffectOptionsForLocalVideo:(id)sender {
  [self showVisualEffectOptionsForManager:self.localVisualEffectManager];
}

- (void)showVisualEffectOptionsForRemoteVideo:(id)sender {
  if (self.remoteVisualEffectManager) {
    [self showVisualEffectOptionsForManager:self.remoteVisualEffectManager];
  }
}

- (void)showVisualEffectOptionsForManager:(id<VideoVisualEffectManaging>)manager {
  UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Original" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [manager applyEffectIfAvailable:nil];
  }]];
  for (VisualEffectDescriptor *descriptor in manager.effects) {
      [sheet addAction:[UIAlertAction actionWithTitle:descriptor.defaultDisplayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      [manager applyEffectIfAvailable:descriptor];
    }]];
  }
  [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:sheet animated:true completion:nil];
}

#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client
    didChangeState:(ARDAppClientState)state {
  switch (state) {
    case kARDAppClientStateConnected:
      RTCLog(@"Client connected.");
      break;
    case kARDAppClientStateConnecting:
      RTCLog(@"Client connecting.");
      break;
    case kARDAppClientStateDisconnected:
      RTCLog(@"Client disconnected.");
      [self hangup];
      break;
  }
}

- (void)appClient:(ARDAppClient *)client
    didChangeConnectionState:(RTCIceConnectionState)state {
  RTCLog(@"ICE state changed: %ld", (long)state);
  __weak ARDVideoCallViewController *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    ARDVideoCallViewController *strongSelf = weakSelf;
    strongSelf.videoCallView.statusLabel.text =
        [strongSelf statusTextForState:state];
  });
}

- (void)appClient:(ARDAppClient *)client
    didCreateLocalCapturer:(RTCCameraVideoCapturer *)localCapturer {
  ARDSettingsModel *settingsModel = [[ARDSettingsModel alloc] init];
  _captureController =
      [[ARDCaptureController alloc] initWithCapturer:localCapturer settings:settingsModel];
  VideoVisualEffectManager *manager = [[VideoVisualEffectManager alloc] initWithCaptureController:_captureController channel:client.messageChannel];
  _localVisualEffectManager = manager;
  __weak ARDVideoCallViewController *weakSelf = self;
  manager.updateBlock = ^{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [weakSelf updateViewsForVisualEffectStates];
    }];
  };
  _captureController.displayDelegate = self;
  [_captureController startCapture];
}

- (void)appClient:(ARDAppClient *)client
    didCreateLocalFileCapturer:(RTCFileVideoCapturer *)fileCapturer {
#if defined(__IPHONE_11_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
  if (@available(iOS 10, *)) {
    _fileCaptureController = [[ARDFileCaptureController alloc] initWithCapturer:fileCapturer];
    [_fileCaptureController startCapture];
  }
#endif
}

- (void)appClient:(ARDAppClient *)client
    didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
}

- (void)appClient:(ARDAppClient *)client
    didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
  self.remoteVideoTrack = remoteVideoTrack;
  RemoteVideoVisualEffectManagerProxy *manager = [[RemoteVideoVisualEffectManagerProxy alloc] initWithChannel:client.messageChannel];
  __weak ARDVideoCallViewController *weakSelf = self;
  manager.updateBlock = ^{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [weakSelf updateViewsForVisualEffectStates];
    }];
  };
  self.remoteVisualEffectManager = manager;
  dispatch_async(dispatch_get_main_queue(), ^{
    ARDVideoCallViewController *strongSelf = weakSelf;
    strongSelf.videoCallView.statusLabel.hidden = YES;
  });
}

- (void)appClient:(ARDAppClient *)client
      didGetStats:(NSArray *)stats {
  _videoCallView.statsView.stats = stats;
  [_videoCallView setNeedsLayout];
}

- (void)appClient:(ARDAppClient *)client
         didError:(NSError *)error {
  NSString *message =
      [NSString stringWithFormat:@"%@", error.localizedDescription];
  [self hangup];
  [self showAlertWithMessage:message];
}

#pragma mark - ARDVideoCallViewDelegate

- (void)videoCallViewDidHangup:(ARDVideoCallView *)view {
  [self hangup];
}

- (void)videoCallViewDidSwitchCamera:(ARDVideoCallView *)view {
  // TODO(tkchin): Rate limit this so you can't tap continously on it.
  // Probably through an animation.
  [_captureController switchCamera];
}

- (void)videoCallViewDidChangeRoute:(ARDVideoCallView *)view {
  AVAudioSessionPortOverride override = AVAudioSessionPortOverrideNone;
  if (_portOverride == AVAudioSessionPortOverrideNone) {
    override = AVAudioSessionPortOverrideSpeaker;
  }
  [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeAudioSession
                               block:^{
    RTCAudioSession *session = [RTCAudioSession sharedInstance];
    [session lockForConfiguration];
    NSError *error = nil;
    if ([session overrideOutputAudioPort:override error:&error]) {
      self.portOverride = override;
    } else {
      RTCLogError(@"Error overriding output port: %@",
                  error.localizedDescription);
    }
    [session unlockForConfiguration];
  }];
}

- (void)videoCallViewDidEnableStats:(ARDVideoCallView *)view {
  _client.shouldGetStats = YES;
  _videoCallView.statsView.hidden = NO;
}

#pragma mark - RTCAudioSessionDelegate

- (void)audioSession:(RTCAudioSession *)audioSession
    didDetectPlayoutGlitch:(int64_t)totalNumberOfGlitches {
  RTCLog(@"Audio session detected glitch, total: %lld", totalNumberOfGlitches);
}

#pragma mark - Private

- (void)setRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
  if (_remoteVideoTrack == remoteVideoTrack) {
    return;
  }
  [self stopRecording];
  [_remoteVideoTrack removeRenderer:_videoCallView.remoteVideoView];
  _remoteVideoTrack = nil;
  [_videoCallView.remoteVideoView renderFrame:nil];
  _remoteVideoTrack = remoteVideoTrack;
  [_remoteVideoTrack addRenderer:_videoCallView.remoteVideoView];
}

- (void)startRecording {
  if (self.recordingSession) { return; }
  VideoRecordingSession *session = [[VideoRecordingSession alloc] init];
  __weak ARDVideoCallViewController *weakSelf = self;
  session.completion = ^{
    [weakSelf handleRecordComplete];
  };
  self.recordingSession = session;
  [_remoteVideoTrack addRenderer:session];
  [session startRecording];
}

- (void)handleRecordComplete {
  NSURL *url = self.recordingSession.outputURL;
  if (url) {
    [SaveVideoTaskManager.sharedManager saveVideoAtURL:url];
  }
  self.recordingSession = nil;
}

- (void)stopRecording {
  if (!self.recordingSession) { return; }
  [self.recordingSession stopRecording];
  [_remoteVideoTrack removeRenderer:self.recordingSession];
}

- (void)hangup {
  [self stopRecording];
  self.remoteVideoTrack = nil;
  [_captureController stopCapture];
  _captureController = nil;
  [_fileCaptureController stopCapture];
  _fileCaptureController = nil;
  [_client disconnect];
  [_delegate viewControllerDidFinish:self];
}

- (NSString *)statusTextForState:(RTCIceConnectionState)state {
  switch (state) {
    case RTCIceConnectionStateNew:
    case RTCIceConnectionStateChecking:
      return @"Connecting...";
    case RTCIceConnectionStateConnected:
    case RTCIceConnectionStateCompleted:
    case RTCIceConnectionStateFailed:
    case RTCIceConnectionStateDisconnected:
    case RTCIceConnectionStateClosed:
    case RTCIceConnectionStateCount:
      return nil;
  }
}

- (void)showAlertWithMessage:(NSString*)message {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:nil
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action){
                                                        }];

  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  CFRetain(sampleBuffer);
  __weak ARDVideoCallViewController *weakSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    ARDVideoCallViewController *strongSelf = weakSelf;
    [strongSelf.videoCallView.localVideoView enqueueBuffer:sampleBuffer];
    CFRelease(sampleBuffer);
  }];
}

@end
