//
//  VideoVisualEffectAccessing.h
//  AppRTCMobile
//
//  Created by 立宣于 on 2019/12/14.
//  Copyright © 2019 Mike. All rights reserved.
//

#ifndef VideoVisualEffectAccessing_h
#define VideoVisualEffectAccessing_h

NS_ASSUME_NONNULL_BEGIN

@import Foundation;

@class VisualEffectDescriptor;
@protocol VideoVisualEffectAccessing <NSObject>

@property (nonatomic, readonly) NSArray<VisualEffectDescriptor *> *effects;
@property (nonatomic, nullable) VisualEffectDescriptor *appliedEffect;

@end

NS_ASSUME_NONNULL_END

#endif /* VideoVisualEffectAccessing_h */
