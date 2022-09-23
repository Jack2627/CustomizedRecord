//
//  ViewController.m
//  CustomizedRecording
//
//  Created by Jack Xue on 2022/9/19.
//

#import "ViewController.h"
#import "AVFoundationRecord/AVFoundationRecording.h"
#import "DemoRecordingView.h"

@interface ViewController ()<AVFRecordingDataSource, AVFRecordingDelegate>
@property(nonatomic, strong)DemoRecordingView *recView;
@end

@implementation ViewController{
    NSInteger _recordingTime;   //-1:没开始，0:开始
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _recordingTime = -1;
    // Do any additional setup after loading the view.
}

#pragma mark - Private
- (IBAction)actionShowRec:(id)sender {
    AVFViewController *vc = [[AVFViewController alloc] init];
    vc.delegate = self;
    vc.dataSource = self;
    [vc jk_setCameraPos:(AVCaptureDevicePositionBack)];
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)updateRecordingTime{
    [self.recView rec_updateRecordingTime:_recordingTime];
}

//MARK: - AVFRecordingDataSource
- (AVFRecBaseView *)avfoundationView{
    return self.recView;
}

//MARK: - AVFRecordingDelegate
- (void)avf_viewController:(AVFViewController *)viewController commit:(NSDictionary *)dict{
    NSLog(@"%@ %@",NSStringFromSelector(_cmd),dict);
}

- (void)avf_viewControllerWillStartRecording:(AVFViewController *)viewController{
    _recordingTime = 0;
    [self updateRecordingTime];
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)avf_viewController:(AVFViewController *)viewController updateRecordingTime:(NSInteger)recordingTime{
    NSLog(@"%@ %@",NSStringFromSelector(_cmd), @(recordingTime));
    _recordingTime = recordingTime;
    [self updateRecordingTime];
}

- (void)avf_viewController:(AVFViewController *)viewController willStopRecordingWithReason:(AVFRecordingStopReason)reason{
    NSString *rea = @"unknown";
    NSString *path = @"nil";
    switch (reason) {
        case AVFRecordingStopReasonUptoMaxTime:
            {
                rea = @"max time";
                path = [viewController jk_getVideoPath];
            }
            break;
        case AVFRecordingStopReasonUserStop:
            {
                rea = @"user stop";
                path = [viewController jk_getVideoPath];
            }
            break;
        case AVFRecordingStopReasonDismiss:
            {
                rea = @"dismiss";
            }
            break;
        case AVFRecordingStopReasonEnterbackground:
            {
                rea = @"enter background";
            }
            break;
        default:
            break;
    }
    NSLog(@"%@ reason:%@ video path: %@",NSStringFromSelector(_cmd),rea,path);
}

- (void)avf_viewController:(AVFViewController *)viewController didStopRecordingWithResult:(BOOL)success{
    NSLog(@"%@ result: %@",NSStringFromSelector(_cmd),success ? @"success":@"fail");
    _recordingTime = -1;
    [self updateRecordingTime];
}

- (void)avf_viewControllerWillDismiss:(AVFViewController *)viewController{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    _recordingTime = -1;
    [self updateRecordingTime];
    self.recView = nil;
}

#pragma mark - Lazy
- (DemoRecordingView *)recView{
    if (!_recView) {
        _recView = [[DemoRecordingView alloc] initWithFrame:CGRectZero];
    }
    return _recView;
}

@end
