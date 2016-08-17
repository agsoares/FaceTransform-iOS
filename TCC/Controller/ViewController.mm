//
//  ViewController.m
//  TCC
//
//  Created by Adriano Soares on 11/08/16.
//  Copyright © 2016 Adriano Soares. All rights reserved.
//

#import "ViewController.h"


using namespace cv;
using namespace std;

@interface ViewController ()
    @property VideoCapture   sourceVideo;
    @property CvVideoCamera *videoCamera;
    @property BOOL cameraInitialized;
    @property BOOL videoLoaded;

    @property UIView *preview;

@end

@implementation ViewController {


}

- (void)viewDidLoad {
    [super viewDidLoad];
    _cameraInitialized  = NO;
    _videoLoaded        = NO;
    

    [_preview setContentMode:UIViewContentModeScaleAspectFill];
    [_preview setClipsToBounds:YES];
    
    
    [self loadVideo];
    [self setupVideoCamera];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)loadVideo {
    NSString   *path     = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mov"];
    const char *filePath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    if(_sourceVideo.open(filePath)){
        _videoLoaded = YES;
        NSLog(@"videoLoaded");
    }
}

- (void)setupVideoCamera {
    if (_cameraInitialized) {
        // already initialized
        return;
    }
    _preview = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_preview];
    
    
    _videoCamera = [[CvVideoCamera alloc] initWithParentView:_preview];
    _videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    _videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetLow;
    _videoCamera.defaultFPS = 30;
    
    
    _videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    _videoCamera.grayscaleMode = NO;
    _videoCamera.rotateVideo = NO;
    _videoCamera.delegate = self;
    
    [_videoCamera start];
}


#pragma mark - CvVideoCameraDelegate
- (void)processImage:(cv::Mat &)image {
    if (!_videoLoaded) {
        return;
    }
    cv::Mat frame;
    _sourceVideo >> frame;
    if (frame.empty()) {
        [self loadVideo];
        _sourceVideo >> frame;
    
    }
    cvtColor(frame, frame, CV_RGB2BGR);
    image = frame;

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
