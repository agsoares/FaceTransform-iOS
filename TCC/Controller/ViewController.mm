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

    @property Detector *detector;

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
    
    _detector = Detector.sharedInstance;
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
    static std::vector<cv::Point2f> landmarks;
    static int fcount = 0;
    if (fcount%2 == 0) {
        landmarks = [_detector detectLandmarks:frame andIsBlocking:YES];
    }
    fcount ++;
    
    if (landmarks.size() >= 68) {
        auto green = Scalar(0, 255, 0);
        NSArray *triangulation = [MaskHelper triangulation];
        for(int j = 0; j < [triangulation count]; j++ )
        {
            cv::Point pt[3];
            NSArray *t = triangulation[j];
            pt[0] = cv::Point(landmarks[[t[0] integerValue]]);
            pt[1] = cv::Point(landmarks[[t[1] integerValue]]);
            pt[2] = cv::Point(landmarks[[t[2] integerValue]]);

            cv::line(frame, pt[0], pt[1], green, 1, CV_AA, 0);
            cv::line(frame, pt[1], pt[2], green, 1, CV_AA, 0);
            cv::line(frame, pt[2], pt[0], green, 1, CV_AA, 0);

        }
    }
    image = frame;

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
