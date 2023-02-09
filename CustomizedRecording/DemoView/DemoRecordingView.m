//
//  DemoRecordingView.m
//  CustomizedRecording
//
//  Created by Jack Xue on 2022/9/19.
//

#import "DemoRecordingView.h"
#import "JKRecordAnimationView.h"
@interface DemoRecordingView() <JKRecordAnimationViewDelegate>
@end

@implementation DemoRecordingView{
    UIButton *_dismissBtn;
    JKRecordAnimationView *_recordingBtn;
    UIButton *_switchBtn;
    UILabel *_timeLabel;
    UISlider *_slider;      // height staic 30
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _dismissBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_dismissBtn addTarget:self action:@selector(actionDismiss) forControlEvents:(UIControlEventTouchUpInside)];
        _dismissBtn.backgroundColor = [UIColor redColor];
        [_dismissBtn setTitle:@"x" forState:(UIControlStateNormal)];
        [self addSubview:_dismissBtn];
        
        _recordingBtn = [[JKRecordAnimationView alloc] initWithFrame:CGRectZero];
        _recordingBtn.delegate = self;
        _recordingBtn.sep = 3.0;
        _recordingBtn.recLineWidth = 7.0;
        [self addSubview:_recordingBtn];
        
        _switchBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_switchBtn addTarget:self action:@selector(actionSwitchCamera) forControlEvents:(UIControlEventTouchUpInside)];
        [_switchBtn setTitle:@"🔄" forState:(UIControlStateNormal)];
        [self addSubview:_switchBtn];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        _timeLabel.layer.borderColor = [UIColor grayColor].CGColor;
        _timeLabel.layer.borderWidth = 1.0;
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_timeLabel];
        
        _slider = [[UISlider alloc] initWithFrame:CGRectZero];
        [_slider addTarget:self action:@selector(actionWhiteBlanceChanged:) forControlEvents:(UIControlEventValueChanged)];
        // 白平衡色温范围1～10000
        _slider.minimumValue = 1.0;
        _slider.maximumValue = 10000.0;
        [self addSubview:_slider];
    }
    return self;
}

- (void)dealloc{
    NSLog(@"jkdebug dealloc %@",self);
}

- (void)layoutSubviews{
    [super layoutSubviews];
    static CGFloat btnSize = 70.0;
    _dismissBtn.frame = CGRectMake(50, 100, 50, 50);
    _recordingBtn.frame = CGRectMake((CGRectGetWidth(self.frame) - btnSize)/2, CGRectGetHeight(self.frame) - 100 - btnSize, btnSize, btnSize);
    _switchBtn.frame = CGRectMake(CGRectGetMaxX(_recordingBtn.frame) + btnSize, CGRectGetMinY(_recordingBtn.frame), btnSize, btnSize);
    _timeLabel.frame = CGRectMake(CGRectGetMinX(_recordingBtn.frame) - btnSize * 2, 0, btnSize, 20);
    CGPoint center = _timeLabel.center;
    center.y = _switchBtn.center.y;
    _timeLabel.center = center;
    
    _slider.frame = CGRectMake(20, 100, CGRectGetWidth(self.frame) - 40, 30);
}

//MARK: - Private
- (void)actionDismiss{
    [self.delegate avf_recViewDismissAction];
}

- (void)actionSwitchCamera{
    [self.delegate avf_recViewSwitchCamera];
}

- (void)actionWhiteBlanceChanged:(UISlider *)sender{
    [self.delegate avf_recViewUpdateWhiteBalanceWithTemperature:sender.value];
}

#pragma mark - Public
- (void)rec_updateRecordingTime:(NSInteger)recTime{
    if (recTime == -1) {
        //结束
        [_recordingBtn updateAnimation:NO];
        _timeLabel.text = nil;
    }else if (recTime == 0) {
        //开始
        [_recordingBtn updateAnimation:YES];
        _timeLabel.text = [NSString stringWithFormat:@"%@",@(recTime)];
    }else if (recTime > 0) {
        //正常更新
        _timeLabel.text = [NSString stringWithFormat:@"%@",@(recTime)];
    }else{
        //异常数据
        NSLog(@"error");
    }
}

- (void)rec_hideDismissBtn{
    _dismissBtn.hidden = YES;
}

- (void)rec_setTemperature:(float)temperature{
    [_slider setValue:temperature animated:NO];
}

#pragma mark - JKRecordAnimationViewDelegate
- (void)recordViewDidTap:(JKRecordAnimationView *)view{
    [self.delegate avf_recViewTapRecordingButton];
}

@end
