//
//  AVSampleBufferDisplayView.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/13.
//  Copyright © 2019 Mike. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

@interface AVSampleBufferDisplayView : UIView

- (void)enqueueBuffer:(CMSampleBufferRef)buffer;

@end

NS_ASSUME_NONNULL_END
