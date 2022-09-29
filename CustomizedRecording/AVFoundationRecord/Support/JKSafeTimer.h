//
//  JKSafeTimer.h
//  AVDemo
//
//  Created by Jack Xue on 2022/7/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JKSafeTimerDelegate <NSObject>
@optional
- (void)jk_safeTimerCallBack;
@end

@interface JKSafeTimer : NSObject
- (void)jk_safeTimerFireWithPerCallbackTime:(NSInteger)sec withDelegate:(id<JKSafeTimerDelegate>)delegate;
- (void)jk_safeTimerRelease;
@end

NS_ASSUME_NONNULL_END
