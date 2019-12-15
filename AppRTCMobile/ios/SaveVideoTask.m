//
//  SaveVideoTask.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/15.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "SaveVideoTask.h"
@import Photos;

typedef void(^SaveVideoTaskCompletion)(void);

@interface SaveVideoTask : NSObject

- (instancetype)initWithURL:(NSURL *)url;

@property (nonatomic, copy) SaveVideoTaskCompletion completion;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) BOOL isFinished;
@property (nonatomic, readonly) BOOL isSuccessful;
@property (nonatomic, readonly) NSError *error;
- (void)start;

@end

@interface SaveVideoTaskManager()
@property (nonatomic) NSMutableDictionary *tasks;
@end

@implementation SaveVideoTaskManager

+ (instancetype)sharedManager {
  static dispatch_once_t onceToken;
  static SaveVideoTaskManager *instance;
  dispatch_once(&onceToken, ^{
    instance = [[SaveVideoTaskManager alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _tasks = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)saveVideoAtURL:(NSURL *)url {
  if (self.tasks[url.absoluteString]) { return; }
  SaveVideoTask *task = [[SaveVideoTask alloc] initWithURL:url];
  __weak SaveVideoTaskManager *weakSelf;
  task.completion = ^{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [weakSelf removeTaskFor:url];
    }];
  };
  self.tasks[url.absoluteString] = task;
  [task start];
}

- (void)removeTaskFor:(NSURL *)url {
  [self.tasks removeObjectForKey:url.absoluteString];
}

@end

@implementation SaveVideoTask

- (instancetype)initWithURL:(NSURL *)url {
  self = [super init];
  if (self) {
    if (!url.isFileURL) {
      @throw @"URL is not file url";
    }
    _url = url;
  }
  return self;
}

- (void)start {
  __weak SaveVideoTask *weakSelf = self;
  [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
    [weakSelf savePhoto];
  } completionHandler:^(BOOL success, NSError * _Nullable error) {
    [weakSelf handleSaveCompletion:success error:error];
  }];
}

- (void)savePhoto {
  PHAssetCreationRequest *req = [PHAssetCreationRequest creationRequestForAsset];
  PHAssetResourceCreationOptions *op = [[PHAssetResourceCreationOptions alloc] init];
  op.shouldMoveFile = true;
  [req addResourceWithType:PHAssetResourceTypeVideo fileURL:self.url options:op];
}

- (void)handleSaveCompletion:(BOOL)success
                       error:(NSError *)error {
  _isFinished = YES;
  _isSuccessful = success;
  _error = error;
  if (self.completion) {
    self.completion();
  }
}

@end
