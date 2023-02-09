//
//  AVFRecBaseView.h
//  AVDemo
//
//  Created by iOS_Developer on 2022/9/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AVFRecViewDelegate <NSObject>
@optional
- (void)avf_recViewTapRecordingButton;
- (void)avf_recViewDismissAction;
- (void)avf_recViewSwitchCamera;
- (void)avf_recViewCommit;
- (void)avf_recViewUpdateWhiteBalanceWithTemperature:(float)temperature;
@end

@interface AVFRecBaseView : UIView
@property(nonatomic, weak)id<AVFRecViewDelegate>delegate;
@end

NS_ASSUME_NONNULL_END
