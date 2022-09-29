# AVFoundationRecording
## 特性
    1.支持自定义视频录制过程中的UserInterface;
## 安装
    1.引入文件
    目前仅支持手动倒入，即下载demo后复制AVFoundationRecord文件夹下所有文件，使用时#import "AVFoundationRecording.h"即可。
    
## 使用
### 1.遵循AVFRecordingDataSource, AVFRecordingDelegate协议
    // AVFRecordingDataSource
    - (AVFRecBaseView *)avfoundationView{
        //提供AVFRecBaseView的子类，并在其中自定义你所需要的UI
        return subclass of AVFRecBaseView;
    }

    //AVFRecordingDelegate
    - (void)avf_viewControllerWillStartRecording:(AVFViewController *)viewController{
        // 开始录制
    }

    - (void)avf_viewController:(AVFViewController *)viewController updateRecordingTime:(NSInteger)recordingTime{
        // 更新已录制时间
    }

    - (void)avf_viewController:(AVFViewController *)viewController willStopRecordingWithReason:(AVFRecordingStopReason)reason{
        // 即将结束录制，并提供结束录制的原因
    }

    - (void)avf_viewController:(AVFViewController *)viewController didStopRecordingWithResult:(BOOL)success{
        //已经结束录制，并返回是否录制成功
    }

    - (void)avf_viewControllerWillDismiss:(AVFViewController *)viewController{
        //viewController dealloc前回调
    }

    - (void)avf_viewControllerWillAppear:(AVFViewController *)viewController{
        //AVFViewController viewWillAppear调用
    }

    - (void)avf_viewControllerWillDisappear:(AVFViewController *)viewController{
        //AVFViewController viewWillDisappear调用
    }

### 2.AVFRecBaseView的子类如何控制AVFViewController
    通过调用AVFRecViewDelegate的方法，如需要开始录制，只需要在点击事件中这样写就可以: [self.delegate avf_recViewTapRecordingButton];


    


