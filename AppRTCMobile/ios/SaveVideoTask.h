//
//  SaveVideoTask.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/15.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SaveVideoTaskManager : NSObject

+ (instancetype)sharedManager;
- (void)saveVideoAtURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
