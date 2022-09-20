//
//  JKSafeTimer.m
//  AVDemo
//
//  Created by Jack Xue on 2022/7/7.
//

#import "JKSafeTimer.h"

@implementation JKSafeTimer{
    NSTimer *_timer;
}

- (void)dealloc{
    NSLog(@"jkdebug safeTimer release");
}

#pragma mark - Private
- (void)actionTic{
    if (self.delegate && [self.delegate respondsToSelector:@selector(jk_safeTimerCallBack)]) {
        [self.delegate jk_safeTimerCallBack];
    }
}

#pragma mark - Public
- (void)jk_safeTimerFireWithPerCallbackTime:(NSInteger)sec{
    if (sec <= 0) {
        return;
    }
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:sec target:self selector:@selector(actionTic) userInfo:nil repeats:YES];
}

- (void)jk_safeTimerRelease{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

@end
