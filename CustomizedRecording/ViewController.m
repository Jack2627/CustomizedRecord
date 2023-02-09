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
@property (weak, nonatomic) IBOutlet UITextField *inputMin;
@property (weak, nonatomic) IBOutlet UITextField *inputMax;
@property (weak, nonatomic) IBOutlet UITextField *inputRecSize;
@property (weak, nonatomic) IBOutlet UITextField *inputFPS;
@property (weak, nonatomic) IBOutlet UITextField *inputFlag;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segPos;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segRecType;

@end

@implementation ViewController{
    NSInteger _recordingTime;   //-1:没开始，0:开始
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _recordingTime = -1;
    // Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

#pragma mark - Private
- (void)showAlertWithMsg:(NSString *)msg{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tip" message:msg preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:(UIAlertActionStyleDefault) handler:NULL];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)showRecordingViewControllerWithMethod:(ShowRecordMethod)method{
    AVFViewController *vc = [[AVFViewController alloc] init];
    vc.delegate = self;
    vc.dataSource = self;

    NSInteger min = [self.inputMin.text integerValue];
    if (min > 0) {
        [vc jk_setMinRecordSecond:min];
    }
    
    NSInteger max = [self.inputMax.text integerValue];
    if (max > min) {
        [vc jk_setMaxRecordSecond:max];
    }
    
    NSInteger fps = [self.inputFPS.text integerValue];
    if (fps > 0) {
        [vc jk_setFrameRate:fps];
    }
    
    NSArray *size = [self.inputRecSize.text componentsSeparatedByString:@"#"];
    if (size.count == 2) {
        CGFloat width = [size.firstObject floatValue];
        CGFloat height = [size.lastObject floatValue];
        if (width > 0 && height > 0) {
            [vc jk_setSaveVideoSize:CGSizeMake(width, height)];
        }
    }
    
    NSString *flag = self.inputFlag.text;
    if (flag && flag.length > 0) {
        vc.flag = flag;
    }
    
    AVCaptureDevicePosition pos = AVCaptureDevicePositionFront;
    if (self.segPos.selectedSegmentIndex == 1) {
        pos = AVCaptureDevicePositionBack;
    }
    [vc jk_setCameraPos:pos];
    
    AVRecordSaveType type = AVRecordSaveTypeMov;
    if (self.segRecType.selectedSegmentIndex == 1) {
        type = AVRecordSaveTypeMp4;
    }
    [vc jk_setRecordType:type];
    
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

- (IBAction)actionRemoveByFlag:(id)sender {
    NSString *flag = self.inputFlag.text;
    NSAssert(flag.length > 0, @"需要输入flag, You need to inpur flag");
    [AVFViewController jk_removeWithFlag:flag];
    [self showAlertWithMsg:[NSString stringWithFormat:@"%@ has removed",flag]];
}

- (IBAction)actionRemoveAll:(id)sender {
    [AVFViewController jk_removeAll];
    [self showAlertWithMsg:@"All saved video has been removed"];
}

- (IBAction)actionPrintAllSupport:(id)sender {
    AVFViewController *vc = [[AVFViewController alloc] init];
    AVCaptureDevicePosition pos = AVCaptureDevicePositionFront;
    if (self.segPos.selectedSegmentIndex == 1) {
        pos = AVCaptureDevicePositionBack;
    }
    NSArray *array = [vc jk_availableSizeAndFrameRateWithPos:pos];
    NSLog(@"all support: %@",array);
}

- (void)updateRecordingTime{
    [self.recView rec_updateRecordingTime:_recordingTime];
}

- (void)updateWhiteBalance:(AVFViewController *)viewController{
    float temperature = [viewController jk_getWhiteBalanceTemperature];
    if (temperature > 0) {
        NSLog(@"当前色温:%f",temperature);
        [self.recView rec_setTemperature:temperature];
    } else {
        // 获取色温失败
        NSLog(@"获取色温失败");
    }
}

//MARK: - AVFRecordingDataSource
- (AVFRecBaseView *)avfoundationView{
    NSLog(@"jkdebug avview:%@",self.recView);
    return self.recView;
}

//MARK: - AVFRecordingDelegate
- (void)avf_viewControllerDidSwitchCamera:(AVFViewController *)viewController{
    [self updateWhiteBalance:viewController];
}

- (void)avf_viewController:(AVFViewController *)viewController commit:(NSDictionary *)dict{
    NSLog(@"%@ %@",NSStringFromSelector(_cmd),dict);
}

- (void)avf_viewControllerWillStartRecording:(AVFViewController *)viewController{
    NSLog(@"jkdebug will start");
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
    /*
     for demo userinterface
     进入设置导航栏颜色透明
     */
    if (viewController.navigationController) {
        viewController.navigationController.navigationBar.barTintColor = [UIColor clearColor];
        viewController.navigationController.navigationBar.translucent = NO;
    }
    
    [self updateWhiteBalance:viewController];
}

- (void)avf_viewControllerWillDisappear:(AVFViewController *)viewController{
    /*
     for demo userinterface
     退出还原导航栏
     */
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
