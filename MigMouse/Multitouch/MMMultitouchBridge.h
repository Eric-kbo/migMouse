#pragma once

#import <Foundation/Foundation.h>
#import "MultitouchSupportTypes.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MMTouchFrameBlock)(const MMMTouch * _Nullable touches,
                                  NSInteger count,
                                  double timestamp);

@interface MMMultitouchBridge : NSObject

@property(nonatomic, readonly, getter=isRunning) BOOL running;
@property(nonatomic, readonly) NSInteger activeDeviceCount;
@property(nonatomic, copy, readonly) NSString *statusMessage;

- (BOOL)startWithFrameHandler:(MMTouchFrameBlock)handler;

@end

NS_ASSUME_NONNULL_END
