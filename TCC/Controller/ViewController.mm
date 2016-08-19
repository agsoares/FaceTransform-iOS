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
    static std::vector<cv::Point2f> videoLandmarks;
    static std::vector<cv::Point2f>  faceLandmarks;
    static int fcount = 0;
    
    if (fcount%2 == 0) {
        videoLandmarks = [_detector detectLandmarks:frame andIsBlocking:YES];
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
            transpose(image, image);
            flip(image, image, 1); //transpose+flip(1)=CW
        } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
            transpose(image, image);
            flip(image, image, 0); //transpose+flip(0)=CCW
        }
        faceLandmarks  = [_detector detectLandmarks:image andIsBlocking:YES];
    }
    fcount ++;
    
    if (videoLandmarks.size() >= 68) {
        auto green = Scalar(0, 255, 0);
        NSArray *triangulation = [MaskHelper triangulation];
        for(int j = 0; j < [triangulation count]; j++ )
        {
            cv::Point pt[3];
            NSArray *t = triangulation[j];
            pt[0] = cv::Point(videoLandmarks[[t[0] integerValue]]);
            pt[1] = cv::Point(videoLandmarks[[t[1] integerValue]]);
            pt[2] = cv::Point(videoLandmarks[[t[2] integerValue]]);

            cv::line(frame, pt[0], pt[1], green, 1, CV_AA, 0);
            cv::line(frame, pt[1], pt[2], green, 1, CV_AA, 0);
            cv::line(frame, pt[2], pt[0], green, 1, CV_AA, 0);

        }
    }
    if (faceLandmarks.size() >= 68) {
        auto red = Scalar(0, 0, 255);
        NSArray *triangulation = [MaskHelper triangulation];
        for(int j = 0; j < [triangulation count]; j++ )
        {
            cv::Point pt[3];
            NSArray *t = triangulation[j];
            pt[0] = cv::Point(faceLandmarks[[t[0] integerValue]]);
            pt[1] = cv::Point(faceLandmarks[[t[1] integerValue]]);
            pt[2] = cv::Point(faceLandmarks[[t[2] integerValue]]);
            
            cv::line(frame, pt[0], pt[1], red, 1, CV_AA, 0);
            cv::line(frame, pt[1], pt[2], red, 1, CV_AA, 0);
            cv::line(frame, pt[2], pt[0], red, 1, CV_AA, 0);
            
        }
    }
    image = frame;

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
