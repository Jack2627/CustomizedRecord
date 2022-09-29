//
//  AVFRecConst.h
//  AVDemo
//
//  Created by iOS_Developer on 2022/9/11.
//

#ifndef AVFRecConst_h
#define AVFRecConst_h

//save video floder name
static NSString *const kAVVideoFloder           = @"AVFloder";

//AVView userInterface Key
static NSString *const kAVRecViewKeyTitle      = @"av_title";      //视频核验
static NSString *const kAVRecViewKeyTip        = @"av_tip";        //请您正对屏幕录制视频，阅读以下内容：
static NSString *const kAVRecViewKeyContent    = @"av_content";    //本人**
static NSString *const kAVRecViewKeyRecTip     = @"av_rec_tip";    //视频已开始录制，15秒内不可手动停止；若需重新录制，请在录制结束后操作
static NSString *const kAVRecViewKeyNoSwitch   = @"av_rec_noSwitch";

//commit out param key
static NSString *const kAVOutParamKeyPath      = @"path";
static NSString *const kAVOutParamKeyLength    = @"length";
static NSString *const kAVOutParamKeyTime      = @"time";
static NSString *const kAVOutParamKeyWidth     = @"width";
static NSString *const kAVOutParamKeyHeight    = @"height";

//Post Notification Key
static NSString *const KAVRecordNotificationBackground = @"AVRecordEnterBackground";
static NSString *const KAVRecordNotificationForeground = @"AVRecordEnterForeground";

typedef NS_ENUM(NSUInteger, AVFRecordingStopReason) {
    AVFRecordingStopReasonUptoMaxTime = 0,
    AVFRecordingStopReasonUserStop,
    AVFRecordingStopReasonDismiss,
    AVFRecordingStopReasonEnterbackground,
};

typedef NS_ENUM(NSUInteger, AVRecordSaveType) {
    AVRecordSaveTypeMov = 0,    //性能高
    AVRecordSaveTypeMp4,        //性能低，性能弱的机器效果差一些
};

@class AVFRecBaseView;
@protocol AVFRecordingDataSource <NSObject>
@required
- (AVFRecBaseView *)avfoundationView;
@end

@class AVFViewController;
@protocol AVFRecordingDelegate <NSObject>
@optional
- (void)avf_viewControllerWillStartRecording:(AVFViewController *)viewController;
- (void)avf_viewController:(AVFViewController *)viewController updateRecordingTime:(NSInteger)recordingTime;
- (void)avf_viewController:(AVFViewController *)viewController willStopRecordingWithReason:(AVFRecordingStopReason)reason;
- (void)avf_viewController:(AVFViewController *)viewController didStopRecordingWithResult:(BOOL)success;
- (void)avf_viewControllerWillDismiss:(AVFViewController *)viewController;
//对应系统方法
- (void)avf_viewControllerWillAppear:(AVFViewController *)viewController;
- (void)avf_viewControllerWillDisappear:(AVFViewController *)viewController;
@end

#endif /* AVFRecConst_h */
