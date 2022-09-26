//
//  ViewController.m
//  CustomizedRecording
//
//  Created by Jack Xue on 2022/9/19.
//

#import "ViewController.h"
#import "AVFoundationRecord/AVFoundationRecording.h"
#import "DemoRecordingView.h"

typedef NS_ENUM(NSUInteger, ShowRecordMethod) {
    ShowRecordMethodPush = 0,
    ShowRecordMethodHalfPresent,
    ShowRecordMethodFullPresent,
};

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
- (void)showRecordingViewControllerWithMethod:(ShowRecordMethod)method{
    AVFViewController *vc = [[AVFViewController alloc] init];
    vc.delegate = self;
    vc.dataSource = self;

    switch (method) {
        case ShowRecordMethodPush:
        {
            //自定义后退按钮
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"<-" style:(UIBarButtonItemStylePlain) target:nil action:nil];
            vc.backItem = item;
            //fix:push后导航栏设置透明向下偏移一个导航栏高度
            vc.extendedLayoutIncludesOpaqueBars = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case ShowRecordMethodHalfPresent:
        {
            [self presentViewController:vc animated:YES completion:NULL];
        }
            break;
        case ShowRecordMethodFullPresent:
        {
            vc.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:vc animated:YES completion:NULL];
        }
            break;
            
        default:
            break;
    }
}

- (IBAction)actionPush:(id)sender {
    [self.recView rec_hideDismissBtn];
    [self showRecordingViewControllerWithMethod:(ShowRecordMethodPush)];
}

- (IBAction)actionHalf:(id)sender {
    [self showRecordingViewControllerWithMethod:(ShowRecordMethodHalfPresent)];
}

- (IBAction)actionFull:(id)sender {
    [self showRecordingViewControllerWithMethod:(ShowRecordMethodFullPresent)];
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

- (void)avf_viewControllerWillAppear:(AVFViewController *)viewController{
    //进入设置导航栏颜色透明
    if (viewController.navigationController) {
        viewController.navigationController.navigationBar.barTintColor = [UIColor clearColor];
        viewController.navigationController.navigationBar.translucent = NO;
    }
}

- (void)avf_viewControllerWillDisappear:(AVFViewController *)viewController{
    //退出还原导航栏
    if (viewController.navigationController) {
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.navigationBar.translucent = YES;
    }
}

#pragma mark - Lazy
- (DemoRecordingView *)recView{
    if (!_recView) {
        _recView = [[DemoRecordingView alloc] initWithFrame:CGRectZero];
    }
    return _recView;
}

@end
