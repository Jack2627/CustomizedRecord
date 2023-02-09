//
//  DemoRecordingView.h
//  CustomizedRecording
//
//  Created by Jack Xue on 2022/9/19.
//

#import "AVFRecBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DemoRecordingView : AVFRecBaseView
- (void)rec_updateRecordingTime:(NSInteger)recTime;
- (void)rec_hideDismissBtn;
- (void)rec_setTemperature:(float)temperature;
@end

NS_ASSUME_NONNULL_END
