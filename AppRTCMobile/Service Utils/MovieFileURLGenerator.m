//
//  MovieFileURLGenerator.m
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/13.
//  Copyright © 2019 Mike. All rights reserved.
//

#import "MovieFileURLGenerator.h"

@interface MovieFileURLGenerator ()
@property (nonatomic) int count;
@end

@implementation MovieFileURLGenerator

+ (MovieFileURLGenerator *)sharedInstance {
  static dispatch_once_t onceToken;
  static MovieFileURLGenerator *singleton;
  dispatch_once(&onceToken, ^{
    singleton = [[MovieFileURLGenerator alloc] init];
  });
  return singleton;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _count = 0;
  }
  return self;
}

- (NSURL *)generateFileURL {
  NSString *name = [[[NSDate date] description] stringByAppendingFormat:@"-%i", self.count];
  NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"mov"];
  return [NSURL fileURLWithPath:path];
}

@end
