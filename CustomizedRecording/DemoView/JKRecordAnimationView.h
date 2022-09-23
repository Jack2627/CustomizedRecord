//
//  JKRecordAnimationView.h
//  CustomizedRecording
//
//  Created by Jack Xue on 2022/9/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class JKRecordAnimationView;
@protocol JKRecordAnimationViewDelegate <NSObject>
@optional
- (void)recordViewDidTap:(JKRecordAnimationView *)view;
@end

@interface JKRecordAnimationView : UIView
@property(nonatomic, weak)id<JKRecordAnimationViewDelegate> delegate;
@property(nonatomic, assign)CGFloat recLineWidth;
@property(nonatomic, assign)CGFloat sep;
- (void)updateAnimation:(BOOL)rec;
@end

NS_ASSUME_NONNULL_END
