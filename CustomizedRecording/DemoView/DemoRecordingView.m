//
//  DemoRecordingView.m
//  CustomizedRecording
//
//  Created by Jack Xue on 2022/9/19.
//

#import "DemoRecordingView.h"

@implementation DemoRecordingView{
    UIButton *_dismissBtn;
    UIButton *_recordingBtn;
    UIButton *_switchBtn;
    UIButton *_commitBtn;
    UILabel *_timeLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _dismissBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_dismissBtn addTarget:self action:@selector(actionDismiss) forControlEvents:(UIControlEventTouchUpInside)];
        _dismissBtn.backgroundColor = [UIColor redColor];
        [self addSubview:_dismissBtn];
        
        _recordingBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_recordingBtn addTarget:self action:@selector(actionRecording) forControlEvents:(UIControlEventTouchUpInside)];
        _recordingBtn.backgroundColor = [UIColor redColor];
        [self addSubview:_recordingBtn];
        
        _switchBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_switchBtn addTarget:self action:@selector(actionSwitchCamera) forControlEvents:(UIControlEventTouchUpInside)];
        _switchBtn.backgroundColor = [UIColor orangeColor];
        [self addSubview:_switchBtn];
        
        _commitBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_commitBtn addTarget:self action:@selector(actionCommit) forControlEvents:(UIControlEventTouchUpInside)];
        _commitBtn.backgroundColor = [UIColor orangeColor];
        [self addSubview:_commitBtn];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_timeLabel];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    static CGFloat btnSize = 50.0;
    _dismissBtn.frame = CGRectMake(50, 100, btnSize, btnSize);
    _recordingBtn.frame = CGRectMake((CGRectGetWidth(self.frame) - btnSize)/2, CGRectGetHeight(self.frame) - 100 - btnSize, btnSize, btnSize);
    _switchBtn.frame = CGRectMake(CGRectGetMaxX(_recordingBtn.frame) + btnSize, CGRectGetMinY(_recordingBtn.frame), btnSize, btnSize);
    _commitBtn.frame = CGRectMake(CGRectGetMinX(_recordingBtn.frame) - btnSize * 2, CGRectGetMinY(_recordingBtn.frame), btnSize, btnSize);
    
}

//MARK: - Private
- (void)actionDismiss{
    [self.delegate avf_recViewDismissAction];
}

- (void)actionRecording{
    [self.delegate avf_recViewTapRecordingButton];
}

- (void)actionCommit{
    [self.delegate avf_recViewCommit];
}

- (void)actionSwitchCamera{
    [self.delegate avf_recViewSwitchCamera];
}

@end
