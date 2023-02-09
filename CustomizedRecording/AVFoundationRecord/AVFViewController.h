//
//  AVFViewController.h
//  AVDemo
//
//  Created by Jack Xue on 2022/7/6.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AVFRecConst.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVFViewController : UIViewController
@property(nonatomic, weak)id<AVFRecordingDataSource>dataSource;
@property(nonatomic, weak)id<AVFRecordingDelegate>delegate;
/**
 保存视频文件的子目录，即AVFloder/[flag]，默认存在AVFloder/pub目录下
 */
@property(nonatomic, copy)NSString *flag;
/**
 仅在JKAVViewController是被push出来时生效，target , action可直接设置为nil，本类内部会重新指定target, action
 */
@property(nonatomic, strong)UIBarButtonItem *backItem;
/**
 根据AVCaptureDevicePosition获取可用的DeviceFormat
 */
- (nullable NSArray <AVCaptureDeviceFormat *>*)jk_availableSizeAndFrameRateWithPos:(AVCaptureDevicePosition)pos;
- (nullable NSString *)jk_getVideoPath;
/**
 设置帧率，包括预览和保存
 */
- (void)jk_setFrameRate:(NSInteger)rate;
/**
 设置使用前后相机
 */
- (void)jk_setCameraPos:(AVCaptureDevicePosition)pos;
/**
 设置最大录制时间
 */
- (void)jk_setMaxRecordSecond:(NSInteger)maxSecond;
/**
 限制最少录制时间
 */
- (void)jk_setMinRecordSecond:(NSInteger)minSecond;
/**
 设置保存尺寸
 */
- (void)jk_setSaveVideoSize:(CGSize)size;

/**
 设置保存格式
 默认.mov格式，录制效果更加稳定
 */
- (void)jk_setRecordType:(AVRecordSaveType)type;

- (float)jk_getWhiteBalanceTemperature;

/// 删除视频文件
+ (BOOL)jk_removeAll;
+ (BOOL)jk_removeWithFlag:(NSString *)flag;
@end

NS_ASSUME_NONNULL_END
