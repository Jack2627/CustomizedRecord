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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)actionShowRec:(id)sender {
    AVFViewController *vc = [[AVFViewController alloc] init];
    vc.delegate = self;
    vc.dataSource = self;
    [vc jk_setCameraPos:(AVCaptureDevicePositionBack)];
    [self presentViewController:vc animated:YES completion:NULL];
}

//MARK: - AVFRecordingDataSource
- (AVFRecBaseView *)avfoundationView{
    DemoRecordingView *view = [[DemoRecordingView alloc] initWithFrame:CGRectZero];
    return view;
}

//MARK: - AVFRecordingDelegate
- (void)avf_viewController:(AVFViewController *)viewController commit:(NSDictionary *)dict{
    NSLog(@"%@ %@",NSStringFromSelector(_cmd),dict);
}

- (void)avf_viewControllerWillStartRecording:(AVFViewController *)viewController{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)avf_viewController:(AVFViewController *)viewController updateRecordingTime:(NSInteger)recordingTime{
    NSLog(@"%@ %@",NSStringFromSelector(_cmd), @(recordingTime));
}

- (void)avf_viewController:(AVFViewController *)viewController willStopRecordingWithReason:(AVFRecordingStopReason)reason{
    NSString *rea = @"unknown";
    switch (reason) {
        case AVFRecordingStopReasonUptoMaxTime:
            {
                rea = @"max time";
            }
            break;
        case AVFRecordingStopReasonUserStop:
            {
                rea = @"user stop";
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
    NSLog(@"%@ reason:%@",NSStringFromSelector(_cmd),rea);
}

- (void)avf_viewController:(AVFViewController *)viewController didStopRecordingWithResult:(BOOL)success{
    NSLog(@"%@ result: %@",NSStringFromSelector(_cmd),success ? @"success":@"fail");
}

- (void)avf_viewControllerWillDismiss:(AVFViewController *)viewController{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

@end
