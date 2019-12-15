//
//  MovieFileURLGenerator.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/13.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MovieFileURLGenerator : NSObject

+ (MovieFileURLGenerator *)sharedInstance;
- (NSURL *)generateFileURL;

@end

NS_ASSUME_NONNULL_END
