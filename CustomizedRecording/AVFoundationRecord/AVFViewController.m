//
//  AVFViewController.m
//  AVDemo
//
//  Created by Jack Xue on 2022/7/6.
//

#import "AVFViewController.h"
#import "AVFRecBaseView.h"
#import "JKUtilities.h"
#import "JKSafeTimer.h"

static NSString *const kAVVideoTypeMOV          = @".mov";
static NSString *const kAVVideoTypeMP4          = @".mp4";
static NSString *const kAVVideoAlertTitle       = @"录制过程中断，请重新录制";
static NSString *const kAVVideoAlertCancel      = @"好的";
static NSString *const kAVVideoReject           = @"退出";
static NSString *const kAVVideoToSetting        = @"去设置";
static NSString *const kAVVideoNoPrivacyVideo   = @"无录像权限";
static NSString *const kAVVideoNoPrivacyAudio   = @"无录音权限";
static NSString *const kAVVideoDefaultFloder    = @"pub";

@interface AVFViewController ()<AVFRecViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, JKSafeTimerDelegate, UIGestureRecognizerDelegate>
@property(nonatomic, strong)AVCaptureDevice *audioDevice;
@property(nonatomic, strong)AVCaptureDevice *frontVideoDevice;
@property(nonatomic, strong)AVCaptureDevice *backVideoDevice;
@property(nonatomic, strong)AVCaptureDeviceInput *audioInput;
@property(nonatomic, strong)AVCaptureDeviceInput *videoInput;
@property(nonatomic, strong)AVCaptureSession *session;
@property(nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;
//使用MovieFileOutput输出
@property(nonatomic, strong)AVCaptureMovieFileOutput *movieOutput;
//使用DataOutput输出
@property(nonatomic, strong)AVCaptureAudioDataOutput *audioOutput;
@property(nonatomic, strong)AVCaptureVideoDataOutput *videoOutput;
@property(nonatomic, strong)AVAssetWriter *avWriter;
@property(nonatomic, strong)AVAssetWriterInput *avVideoInput;
@property(nonatomic, strong)AVAssetWriterInput *avAudioInput;

@property(nonatomic, assign)BOOL recording;
@property(nonatomic, assign)BOOL canWrite;
@property(nonatomic, assign)BOOL interrupted;   //录制过程中，进入后台，录制过程被打断
@property(nonatomic, copy)NSString *videoPath;
@end

@implementation AVFViewController{
    JKSafeTimer *_safeTimer;
    AVCaptureDevicePosition _pos;
    NSInteger _maxTime;
    NSInteger _minTime;
    NSInteger _frameRate;
    NSInteger _recTime;                     //已经录制的时间
    CGSize _saveSize;                       //保存的尺寸
    AVRecordSaveType _recordType;           //.mov | .mp4
    dispatch_queue_t _writing_queue;
    BOOL _needRunSession;                   //询问权限后需要主动调用startSession，因为viewWillAppear的时候self.session还没有初始化
    BOOL _sentDismissDelegate;              //右滑退出手势会造成dealloc的时候还没有向外发送avf_viewControllerWillDismiss
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _safeTimer = [[JKSafeTimer alloc] init];
        _safeTimer.delegate = self;
        
        _pos = AVCaptureDevicePositionFront;
        _maxTime = 0;
        _recTime = 0;
        
        _frameRate = 24;
        _saveSize = CGSizeMake(1920, 1080);
        _recordType = AVRecordSaveTypeMov;
        
        _flag = kAVVideoDefaultFloder;
        
        _writing_queue = dispatch_queue_create("com.customRecording.writing", DISPATCH_QUEUE_SERIAL);
        
        _needRunSession = NO;
        
    }
    return self;
}

- (void)loadView{
    [super loadView];
    
    AVFRecBaseView *view = nil;
    BOOL pass = NO;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(avfoundationView)]) {
        view = [self.dataSource avfoundationView];
        if (view && [view isKindOfClass:[AVFRecBaseView class]]) {
            pass = YES;
        }
    }
    NSAssert(pass, @"avfoundationView未提供");
    view.frame = self.view.bounds;
    view.delegate = self;
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL isPushed = self.navigationController && !self.presentingViewController;
    if (isPushed) {
        //push进来
        if (self.backItem) {
            self.backItem.target = self;
            self.backItem.action = @selector(actionDismiss);
        } else {
            self.backItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemCancel) target:self action:@selector(actionDismiss)];
        }
        self.navigationItem.leftBarButtonItems = @[self.backItem];
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    self.view.backgroundColor = [UIColor blackColor];
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus audioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoStatus == AVAuthorizationStatusDenied) {
        return;
    }else if (videoStatus == AVAuthorizationStatusNotDetermined) {
        //第一次进入
        _needRunSession = YES;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if ([NSThread isMainThread]) {
                [self dealVideoPrivacy:granted audioStatus:audioStatus];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dealVideoPrivacy:granted audioStatus:audioStatus];
                });
            }
        }];
        return;
    }
    
    if (audioStatus == AVAuthorizationStatusDenied) {
        return;
    }else if (audioStatus == AVAuthorizationStatusNotDetermined) {
        _needRunSession = YES;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if ([NSThread isMainThread]) {
                [self dealAudioPrivacy:granted];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dealAudioPrivacy:granted];
                });
            }
        }];
        return;
    }
    
    
    [self setUpVideoAudio];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.delegate && [self.delegate respondsToSelector:@selector(avf_viewControllerWillAppear:)]) {
        [self.delegate avf_viewControllerWillAppear:self];
    }
    if (self.session) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.session startRunning];
        });
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoStatus == AVAuthorizationStatusDenied) {
        [self showPrivacyAlertWithMsg:kAVVideoNoPrivacyVideo];
        return;
    }
    
    AVAuthorizationStatus audioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioStatus == AVAuthorizationStatusDenied) {
        [self showPrivacyAlertWithMsg:kAVVideoNoPrivacyAudio];
        return;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (self.delegate && [self.delegate respondsToSelector:@selector(avf_viewControllerWillDisappear:)]) {
        [self.delegate avf_viewControllerWillDisappear:self];
    }
    [self.session stopRunning];
}

- (void)dealloc{
    NSLog(@"jkdebug vc dealloc");
    if (!_sentDismissDelegate) {
        NSLog(@"jkdebug dismiss from dealloc");
        if (self.delegate && [self.delegate respondsToSelector:@selector(avf_viewControllerWillDismiss:)]) {
            [self.delegate avf_viewControllerWillDismiss:self];
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_safeTimer jk_safeTimerRelease];
    if (self.session) {
        [self.session stopRunning];
    }
}

#pragma mark - Private
- (AVFRecBaseView *)customView{
    return (AVFRecBaseView *)self.view;
}

- (void)dealVideoPrivacy:(BOOL)granted audioStatus:(AVAuthorizationStatus)audioStatus{
    if (granted) {
        if (audioStatus == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if ([NSThread isMainThread]) {
                    [self dealAudioPrivacy:granted];
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self dealAudioPrivacy:granted];
                    });
                }
            }];
        }
        return;
    }else{
        [self actionDismiss];
    }
}

- (void)dealAudioPrivacy:(BOOL)granted{
    if (granted) {
        [self setUpVideoAudio];
    }else{
        [self actionDismiss];
    }
}

- (void)setUpVideoAudio{
    [self addNotification];
    
    self.canWrite = NO;
    self.recording = NO;
    self.interrupted = NO;
    
    [self initDeviceAndInput];
    
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    //根据传入自定义参数找到合适的format
    [self searchUpdateFormatWithPos:_pos needLockSession:YES];
    
    if (_needRunSession) {
        [self.session startRunning];
    }
}

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notiEnterBackground) name:KAVRecordNotificationBackground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notiEnterForeground) name:KAVRecordNotificationForeground object:nil];
}

- (void)notiEnterBackground{
    if (self.recording) {
        self.interrupted = YES;
        [self stopRecordingWithReason:AVFRecordingStopReasonEnterbackground];
    }
}

- (void)notiEnterForeground{
    if (self.interrupted) {
        [self showFailAlertWithMsg:kAVVideoAlertTitle];
    }
}

- (void)initDeviceAndInput{
    self.audioDevice = [self searchAudioDevice];
    
    NSError *a_error = nil;
    self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioDevice error:&a_error];
    if (a_error) {
        //音频输入错误
        return;
    }
    
    NSError *v_error = nil;
    if (_pos == AVCaptureDevicePositionFront) {
        self.frontVideoDevice = [self searchVideoDeviceWithPos:AVCaptureDevicePositionFront];
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.frontVideoDevice error:&v_error];
    }else if (_pos == AVCaptureDevicePositionBack) {
        self.backVideoDevice = [self searchVideoDeviceWithPos:AVCaptureDevicePositionBack];
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backVideoDevice error:&v_error];
    }
    if (v_error) {
        //视频输入错误
        return;
    }
    
    if (_recordType == AVRecordSaveTypeMov) {
        self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
        //不分段
        self.movieOutput.movieFragmentInterval = kCMTimeInvalid;
        if (_maxTime > 0) {
            //CMTimeMakeWithSeconds(maxSecond, 600) 600表示1/600秒，因为是可以兼容各种帧率(24fps, 30fps, 25fps等)，因为是最小公倍数
            self.movieOutput.maxRecordedDuration = CMTimeMakeWithSeconds(_maxTime, 600);
        }
    }else if (_recordType == AVRecordSaveTypeMp4) {
        [self prepareOutput];
    }
    
    self.session = [[AVCaptureSession alloc] init];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    if (_recordType == AVRecordSaveTypeMov) {
        if ([self.session canAddOutput:self.movieOutput]) {
            [self.session addOutput:self.movieOutput];
        }
    }else if (_recordType == AVRecordSaveTypeMp4) {
        if ([self.session canAddOutput:self.videoOutput]) {
            [self.session addOutput:self.videoOutput];
        }
        if ([self.session canAddOutput:self.audioOutput]) {
            [self.session addOutput:self.audioOutput];
        }
    }
}

- (void)actionSwitchCameraInput{
    [self.session beginConfiguration];
    
    //remove current
    if (self.videoInput) {
        [self.session removeInput:self.videoInput];
        self.videoInput = nil;
    }
    
    //prepare new one
    NSError *v_error = nil;
    if (_pos == AVCaptureDevicePositionFront) {
        if (!self.backVideoDevice) {
            //try to init back
            self.backVideoDevice = [self searchVideoDeviceWithPos:AVCaptureDevicePositionBack];
        }
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backVideoDevice error:&v_error];
    }else if (_pos == AVCaptureDevicePositionBack) {
        if (!self.frontVideoDevice) {
            //try to init front
            self.frontVideoDevice = [self searchVideoDeviceWithPos:AVCaptureDevicePositionFront];
        }
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.frontVideoDevice error:&v_error];
    }
    if (v_error) {
        return;
    }
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    //update _pos
    if (_pos == AVCaptureDevicePositionFront) {
        _pos = AVCaptureDevicePositionBack;
    }else if (_pos == AVCaptureDevicePositionBack) {
        _pos = AVCaptureDevicePositionFront;
    }
    
    //更新format
    [self searchUpdateFormatWithPos:_pos needLockSession:NO];
    
    [self.session commitConfiguration];
}

- (void)updateFormat:(AVCaptureDeviceFormat *)format captureDevice:(AVCaptureDevice *)device needLockSession:(BOOL)needLockSession{
    //1.检查device是否支持format
    if ([self checkDevice:device supportFormat:format]) {
        //2.device锁定
        if ([device lockForConfiguration:nil]) {
            if (needLockSession) {
                [self.session beginConfiguration];
            }
            
            device.activeFormat = format;
            if (_frameRate > 0 && [self checkFrameRateAvalible:_frameRate inFormat:format]) {
                [device setActiveVideoMinFrameDuration:CMTimeMake(1, (int)_frameRate)];
                [device setActiveVideoMaxFrameDuration:CMTimeMake(1, (int)_frameRate)];
            }else{
                //不使用自定义帧率
                _frameRate = 0;
            }
            
            if (needLockSession) {
                [self.session commitConfiguration];
            }
        }
        [device unlockForConfiguration];
    }
}

- (void)searchUpdateFormatWithPos:(AVCaptureDevicePosition)pos needLockSession:(BOOL)needLockSession{
    AVCaptureDevice *device = nil;
    if (pos == AVCaptureDevicePositionFront) {
        device = self.frontVideoDevice;
    }else if (pos == AVCaptureDevicePositionBack) {
        device = self.backVideoDevice;
    }
    AVCaptureDeviceFormat *format = [self searchFormatInDevice:device size:_saveSize frameRate:_frameRate];
    if (format) {
        [self updateFormat:format captureDevice:device needLockSession:needLockSession];
    }
}

- (BOOL)checkFrameRateAvalible:(NSInteger)rate inFormat:(AVCaptureDeviceFormat *)format{
    if (!format) {
        return NO;
    }
    CGFloat min = [format.videoSupportedFrameRateRanges firstObject].minFrameRate;
    CGFloat max = [format.videoSupportedFrameRateRanges firstObject].maxFrameRate;
    if (rate >= min && rate <= max) {
        return YES;
    }
    return NO;
}

- (void)prepareOutput{
    dispatch_queue_t video_queue = dispatch_queue_create("cn.jack.video", DISPATCH_QUEUE_SERIAL);
    //设置优先级
    dispatch_set_target_queue(video_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    
    dispatch_queue_t audio_queue = dispatch_queue_create("cn.jack.audio", DISPATCH_QUEUE_SERIAL);
    
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoOutput setSampleBufferDelegate:self queue:video_queue];
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:audio_queue];
}

- (void)dataOutputStartRecord:(NSString *)videoPath{
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    
    //生成writer
    NSError *error = nil;
    self.avWriter = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:&error];
    if (error) {
        //创建writer失败
        return;
    }
    
    //视频输入
    CGFloat width = 100.0;
    CGFloat height = 100.0;
    
    CGSize size = [self currentDeviceFormatSize];
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        //当前format.size存在
        if (CGSizeEqualToSize(_saveSize, CGSizeZero)) {
            //未设置自定义size，直接使用format.size
            width = size.width;
            height = size.height;
        }else{
            //存在自定义size，最大值为format.size
            if (_saveSize.width <= size.width) {
                width = _saveSize.width;
            }else{
                width = size.width;
            }
            
            if (_saveSize.height <= size.height) {
                height = _saveSize.height;
            }else{
                height = size.height;
            }
        }
    }
    
    CGFloat bitsPerPixel = 12.0;
    NSInteger bitsPerSec = bitsPerPixel * width * height;
    NSInteger frameRate = 30;   //default framerate
    if (_frameRate > 0) {
        frameRate = _frameRate;
    }
    NSDictionary *compressionProperty = @{
        //码率
        AVVideoAverageBitRateKey:@(bitsPerSec),
        //帧率
        AVVideoExpectedSourceFrameRateKey:@(frameRate),
        AVVideoMaxKeyFrameIntervalKey:@(frameRate),
        AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel,
    };

    NSMutableDictionary *videoParam = [[NSMutableDictionary alloc] initWithDictionary:@{
        AVVideoWidthKey:@(width),
        AVVideoHeightKey:@(height),
        AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
        AVVideoCompressionPropertiesKey:compressionProperty,
    }];
    if (@available(iOS 11.0, *)) {
        [videoParam setObject:AVVideoCodecTypeH264 forKey:AVVideoCodecKey];
    } else {
        // Fallback on earlier versions
        [videoParam setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    }
    self.avVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoParam];
    //修正录制视频的方向
    self.avVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    self.avVideoInput.expectsMediaDataInRealTime = YES;
    
    if ([self.avWriter canAddInput:self.avVideoInput]) {
        [self.avWriter addInput:self.avVideoInput];
    }
    
    //音频输入
    NSDictionary *audioParam = @{
        AVEncoderBitRatePerChannelKey : @(28000),
        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey : @(1),
        AVSampleRateKey : @(22050),
    };
    self.avAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioParam];
    self.avAudioInput.expectsMediaDataInRealTime = YES;
    
    if ([self.avWriter canAddInput:self.avAudioInput]) {
        [self.avWriter addInput:self.avAudioInput];
    }
    
    self.canWrite = NO;
    
    [self.avWriter startWriting];
}

- (void)startRecording{
    //开始录制
    NSString *fileName = [JKUtilities currentTimeString];
    if (!self.flag || ![self.flag isKindOfClass:[NSString class]] || self.flag.length == 0) {
        self.flag = kAVVideoDefaultFloder;
    }
    NSString *subFloderPath = [NSString stringWithFormat:@"%@/%@",kAVVideoFloder,self.flag];
    NSString *floderPath = [JKUtilities floderPathInSupportWithFloderName:subFloderPath];
    if (floderPath) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(avf_viewControllerWillStartRecording:)]) {
            [self.delegate avf_viewControllerWillStartRecording:self];
        }
        self.recording = YES;
        //开始计时
        [_safeTimer jk_safeTimerFireWithPerCallbackTime:1];
        
        if (_recordType == AVRecordSaveTypeMp4) {
            NSString *videoPath = [NSString stringWithFormat:@"%@/%@%@",floderPath,fileName,kAVVideoTypeMP4];
            self.videoPath = videoPath;
            [self dataOutputStartRecord:videoPath];
        }else if (_recordType == AVRecordSaveTypeMov) {
            NSString *videoPath = [NSString stringWithFormat:@"%@/%@%@",floderPath,fileName,kAVVideoTypeMOV];
            self.videoPath = videoPath;
            NSURL *url = [NSURL fileURLWithPath:videoPath];
            [self.movieOutput startRecordingToOutputFileURL:url recordingDelegate:self];
        }
    }
}

- (void)stopRecordingWithReason:(AVFRecordingStopReason)reason{
    
    _recTime = 0;
    
    //更新录制按钮状态
    if (self.delegate && [self.delegate respondsToSelector:@selector(avf_viewController:willStopRecordingWithReason:)]) {
        [self.delegate avf_viewController:self willStopRecordingWithReason:reason];
    }
    [_safeTimer jk_safeTimerRelease];
    self.recording = NO;
    
    if (_recordType == AVRecordSaveTypeMp4) {
        if (self.avWriter.status == AVAssetWriterStatusWriting) {
            __weak typeof(self) weakSelf = self;
            [self.avWriter finishWritingWithCompletionHandler:^{
                //fix: iOS 16
                if ([NSThread isMainThread]) {
                    weakSelf.canWrite = NO;
                    weakSelf.avWriter = nil;
                    weakSelf.avAudioInput = nil;
                    weakSelf.avVideoInput = nil;
                    
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(avf_viewController:didStopRecordingWithResult:)]) {
                        [weakSelf.delegate avf_viewController:weakSelf didStopRecordingWithResult:YES];
                    }
                } else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        weakSelf.canWrite = NO;
                        weakSelf.avWriter = nil;
                        weakSelf.avAudioInput = nil;
                        weakSelf.avVideoInput = nil;
                        
                        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(avf_viewController:didStopRecordingWithResult:)]) {
                            [weakSelf.delegate avf_viewController:weakSelf didStopRecordingWithResult:YES];
                        }
                    });
                }
                
            }];
        }
    }else if (_recordType == AVRecordSaveTypeMov) {
        if ([self.movieOutput isRecording]) {
            [self.movieOutput stopRecording];
        }
    }
}

- (AVCaptureDevice *)searchDeviceWithMediaType:(AVMediaType)mediaType pos:(AVCaptureDevicePosition)pos{
    if (@available(iOS 10.0, *)) {
        NSArray *types = nil;
        if ([mediaType isEqualToString:AVMediaTypeVideo]) {
            types = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
        }else if ([mediaType isEqualToString:AVMediaTypeAudio]) {
            types = @[AVCaptureDeviceTypeBuiltInMicrophone];
        }
        if (!types) {
            return nil;
        }
        AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:types mediaType:mediaType position:pos];
        for (AVCaptureDevice *device in session.devices) {
            if ([device position] == pos) {
                return device;
            }
        }
    } else {
        // Fallback on earlier versions
        NSArray *devices = [AVCaptureDevice devices];
        BOOL needCheckPos = [mediaType isEqualToString:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device hasMediaType:mediaType]) {
                if (needCheckPos) {
                    if ([device position] == pos) {
                        return device;
                    }
                }else{
                    return device;
                }
            }
        }
    }
    
    return nil;
}

- (AVCaptureDevice *)searchAudioDevice{
    return [self searchDeviceWithMediaType:(AVMediaTypeAudio) pos:AVCaptureDevicePositionUnspecified];
}

- (AVCaptureDevice *)searchVideoDeviceWithPos:(AVCaptureDevicePosition)pos{
    return [self searchDeviceWithMediaType:(AVMediaTypeVideo) pos:pos];
}

- (BOOL)checkDevice:(AVCaptureDevice *)device supportFormat:(AVCaptureDeviceFormat *)format{
    if ([device.formats containsObject:format]) {
        return YES;
    }
    return NO;
}

- (AVCaptureDeviceFormat *)searchFormatInDevice:(AVCaptureDevice *)device size:(CGSize)size frameRate:(NSInteger)frameRate{
    if (!device) {
        return nil;
    }
    if (CGSizeEqualToSize(size, CGSizeZero) || frameRate <= 0) {
        //无搜索条件则返回无结果
        return nil;
    }
    for (AVCaptureDeviceFormat *mat in device.formats) {
        CMFormatDescriptionRef des = mat.formatDescription;
        CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(des);
        float maxFrameRate = [mat.videoSupportedFrameRateRanges firstObject].maxFrameRate;
        float minFrameRate = [mat.videoSupportedFrameRateRanges firstObject].minFrameRate;
        //优先比对尺寸，其次是帧率
        if (size.width == dims.width &&
            size.height == dims.height &&
            frameRate >= minFrameRate &&
            frameRate <= maxFrameRate) {
            return mat;
        }
    }
    return nil;
}

- (CGSize)currentDeviceFormatSize{
    if (_pos == AVCaptureDevicePositionFront) {
        if (self.frontVideoDevice) {
            CMFormatDescriptionRef des = self.frontVideoDevice.activeFormat.formatDescription;
            CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(des);
            return CGSizeMake(dim.width, dim.height);
        }
    }else if (_pos == AVCaptureDevicePositionBack) {
        if (self.backVideoDevice) {
            CMFormatDescriptionRef des = self.backVideoDevice.activeFormat.formatDescription;
            CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(des);
            return CGSizeMake(dim.width, dim.height);
        }
    }
    return CGSizeZero;
}

- (void)showFailAlertWithMsg:(NSString *)msg{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:kAVVideoAlertCancel style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)showPrivacyAlertWithMsg:(NSString *)msg{
    /*
     static NSString *const            = @"退出";
     static NSString *const         = @"去设置";
     */
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:kAVVideoReject style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
        [self actionDismiss];
    }];
    UIAlertAction *setting = [UIAlertAction actionWithTitle:kAVVideoToSetting style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
    [alert addAction:cancel];
    [alert addAction:setting];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)actionDismiss{
    if (self.delegate && [self.delegate respondsToSelector:@selector(avf_viewControllerWillDismiss:)]) {
        _sentDismissDelegate = YES;
        [self.delegate avf_viewControllerWillDismiss:self];
    }
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Public
- (NSArray<AVCaptureDeviceFormat *> *)jk_availableSizeAndFrameRateWithPos:(AVCaptureDevicePosition)pos{
    if (pos == AVCaptureDevicePositionFront) {
        if (self.frontVideoDevice) {
            return self.frontVideoDevice.formats;
        }else{
            self.frontVideoDevice = [self searchVideoDeviceWithPos:AVCaptureDevicePositionFront];
            if (self.frontVideoDevice) {
                return self.frontVideoDevice.formats;
            }
        }
        
    }else if (pos == AVCaptureDevicePositionBack) {
        if (self.backVideoDevice) {
            return self.backVideoDevice.formats;
        }else{
            self.backVideoDevice = [self searchVideoDeviceWithPos:AVCaptureDevicePositionBack];
            if (self.backVideoDevice) {
                return self.backVideoDevice.formats;
            }
        }
    }
    return nil;
}

- (NSString *)jk_getVideoPath{
    return self.videoPath;
}

- (void)jk_setFrameRate:(NSInteger)rate{
    if (rate > 0) {
        _frameRate = rate;
    }else{
        _frameRate = 0;
    }
}

- (void)jk_setCameraPos:(AVCaptureDevicePosition)pos{
    _pos = pos;
}

- (void)jk_setMaxRecordSecond:(NSInteger)maxSecond{
    if (maxSecond > 0) {
        _maxTime = maxSecond;
    }else{
        _maxTime = 0;
    }
}

- (void)jk_setMinRecordSecond:(NSInteger)minSecond{
    if (minSecond > 0) {
        _minTime = minSecond;
    }else{
        _minTime = 0;
    }
}

- (void)jk_setSaveVideoSize:(CGSize)size{
    _saveSize = size;
}

- (void)jk_setRecordType:(AVRecordSaveType)type{
    _recordType = type;
}

+ (BOOL)jk_removeAll{
    NSString *floderPath = [JKUtilities floderPathInSupportWithFloderName:kAVVideoFloder];
    if (floderPath) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error = nil;
        BOOL result = [manager removeItemAtPath:floderPath error:&error];
        if (result && !error) {
            return YES;
        }else{
            return NO;
        }
    }
    
    return NO;
}

+ (BOOL)jk_removeWithFlag:(NSString *)flag{
    if (!flag) {
        return NO;
    }
    NSString *floderPath = [JKUtilities floderPathInSupportWithFloderName:kAVVideoFloder];
    if (floderPath) {
        NSString *path = [NSString stringWithFormat:@"%@/%@",floderPath,flag];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error = nil;
        BOOL result = [manager removeItemAtPath:path error:&error];
        if (result && !error) {
            return YES;
        }else{
            return NO;
        }
    }
    return NO;
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error{
    BOOL success = YES;
    if ([error code] != noErr) {
        NSNumber *result = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (result && ([result isKindOfClass:[NSNumber class]] || [result isKindOfClass:[NSString class]])) {
            success = [result boolValue];
        }
    }
    /*
     AVErrorMaximumDurationReached  时间限制
     AVErrorMaximumFileSizeReached  文件大小限制
     AVErrorDiskFull                磁盘已满
     AVErrorDeviceWasDisconnected   device连接失败
     AVErrorSessionWasInterrupted   被切断（比如说来电话了）
     */
    BOOL isSuccess = NO;
    if (success) {
        isSuccess = YES;
        NSLog(@"jkdebug 录制成功");
    }else{
        NSLog(@"jkdebug 录制出现错误");
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(avf_viewController:didStopRecordingWithResult:)]) {
        [self.delegate avf_viewController:self didStopRecordingWithResult:isSuccess];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    CMFormatDescriptionRef desMedia = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(desMedia);
    
    if (self.recording) {
        if (sampleBuffer == NULL) {
            NSLog(@"empty");
            return;
        }
        
        @synchronized (self) {
            
            CFRetain(sampleBuffer);
            dispatch_async(_writing_queue, ^{
                @autoreleasepool {
                    if (mediaType == kCMMediaType_Video) {
                        if (!self.canWrite && self.avWriter && self.avWriter.status == AVAssetWriterStatusWriting) {
                            CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                            [self.avWriter startSessionAtSourceTime:timestamp];
                            self.canWrite = YES;
                        }
                    }

                    if (self.canWrite && self.avWriter && self.avWriter.status == AVAssetWriterStatusWriting) {
                        if (mediaType == kCMMediaType_Video) {
                            if (self.avVideoInput.readyForMoreMediaData) {
                                BOOL success = [self.avVideoInput appendSampleBuffer:sampleBuffer];
                                if (!success) {
                                    NSLog(@"video appending failed");
                                }
                            }
                        }else if (mediaType == kCMMediaType_Audio) {
                            if (self.avAudioInput.readyForMoreMediaData) {
                                BOOL success = [self.avAudioInput appendSampleBuffer:sampleBuffer];
                                if (!success) {
                                    NSLog(@"audio appending failed");
                                }
                            }
                        }
                    }
                    
                    CFRelease(sampleBuffer);
                }
            });//end - dispatch_async
        }//end - @synchronized
    }
}

#pragma mark - JKSafeTimerDelegate
- (void)jk_safeTimerCallBack{
    NSInteger updateTime = _recTime += 1;
    //更新录制时长UserInterface
    if (self.delegate && [self.delegate respondsToSelector:@selector(avf_viewController:updateRecordingTime:)]) {
        [self.delegate avf_viewController:self updateRecordingTime:updateTime];
    }
    if (_maxTime > 0 && updateTime >= _maxTime) {
        //结束录制
        [self stopRecordingWithReason:AVFRecordingStopReasonUptoMaxTime];
    }
}

#pragma mark - JKAVViewDelegate
- (void)avf_recViewTapRecordingButton{
    if (self.recording) {
        if (_recTime >= _minTime) {
            //结束录制
            [self stopRecordingWithReason:AVFRecordingStopReasonUserStop];
        }else{
            //不满足最小录制时间
        }
    }else{
        //开始录制
        [self startRecording];
    }
}

- (void)avf_recViewDismissAction{
    [self stopRecordingWithReason:AVFRecordingStopReasonDismiss];
    [self actionDismiss];
}

- (void)avf_recViewSwitchCamera{
    if (self.recording) {
        NSLog(@"can't switch cause already recording");
        return;
    }
    [self actionSwitchCameraInput];
}

- (void)avf_recViewCommit{
    //用户点击commit
    NSMutableDictionary *param = nil;
    if (self.videoPath) {
        NSURL *url = [NSURL fileURLWithPath:self.videoPath];
        if (url) {
            param = [[NSMutableDictionary alloc] init];
            
            [param setObject:self.videoPath forKey:kAVOutParamKeyPath];
            
            AVURLAsset *asset = [AVURLAsset assetWithURL:url];
            CMTime time = [asset duration];
            int sec = ceil(time.value/time.timescale);
            [param setObject:@(sec) forKey:kAVOutParamKeyTime];
            
            //文件长度
            NSInteger length = [[NSFileManager defaultManager] attributesOfItemAtPath:self.videoPath error:nil].fileSize;
            [param setObject:@(length) forKey:kAVOutParamKeyLength];
            
            //width + height
            CGSize size = CGSizeZero;
            for (AVAssetTrack *track in asset.tracks) {
                if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                    size = track.naturalSize;
                    break;
                }
            }
            
            //录制方向为landscape，所以需要宽高互换
            [param setObject:@(size.height) forKey:kAVOutParamKeyWidth];
            [param setObject:@(size.width) forKey:kAVOutParamKeyHeight];
        }
    }
    
    [self actionDismiss];
}

#pragma mark - 懒加载
- (AVCaptureVideoPreviewLayer *)previewLayer{
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.frame = [UIScreen mainScreen].bounds;
        _previewLayer.videoGravity = self.videoGravity;
        _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _previewLayer;
}

- (AVLayerVideoGravity)videoGravity{
    if (!_videoGravity) {
        _videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _videoGravity;
}

@end
