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
    cv::Mat staticFrame;

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
        _sourceVideo >> staticFrame;

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
    cv::Mat frame = staticFrame.clone();
    
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
            flip(image, image, 1);
        } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
            transpose(image, image);
            flip(image, image, 0);
        }
        faceLandmarks  = [_detector detectLandmarks:image andIsBlocking:YES];
    }
    fcount ++;
    std::vector<cv::Point2f> copyLandmarks(videoLandmarks);
    for (int i = 25; i < copyLandmarks.size(); i++) {
        copyLandmarks[i].y += 5;
    }
    
    
    if (/* DISABLES CODE */ (NO) && videoLandmarks.size() >= 68) {
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
    if (/* DISABLES CODE */ (NO) && faceLandmarks.size() >= 68) {
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
    if (videoLandmarks.size() >= 68 && faceLandmarks.size() >= 68) {
        NSArray *triangulation = [MaskHelper triangulation];
        Mat warpedFilter = Mat::zeros(frame.size().height, frame.size().width, CV_8UC3);
        Mat warpedMask   = Mat::zeros(frame.size().height, frame.size().width, CV_8UC1);
        /*
        cv::Rect boundingBox = boundingRect(copyLandmarks);
        Mat roi = frame(boundingBox);
        for (int i = 0; i < copyLandmarks.size(); i++) {
            copyLandmarks[i].x -= boundingBox.x;
            copyLandmarks[i].y -= boundingBox.y;
        }
        */
        dispatch_group_t group = dispatch_group_create();
        
        for(int j = 0; j < [triangulation count]; j++ ) {
            dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                std::vector<cv::Point2f> v1;
                std::vector<cv::Point2f> v2;
                
                NSArray *t = triangulation[j];
                int i1, i2, i3;
                i1 = (int)[t[0] integerValue];
                i2 = (int)[t[1] integerValue];
                i3 = (int)[t[2] integerValue];
                
                v1.push_back(copyLandmarks[i1]);
                v1.push_back(copyLandmarks[i2]);
                v1.push_back(copyLandmarks[i3]);
                
                v2.push_back(videoLandmarks[i1]);
                v2.push_back(videoLandmarks[i2]);
                v2.push_back(videoLandmarks[i3]);
                
                Mat warpMat = getAffineTransform(v2, v1);
                
                Mat outMask = Mat::zeros(frame.rows, frame.cols, CV_8UC1);
                
                cv::Point pt[3];
                pt[0] = cv::Point(v1[0]);
                pt[1] = cv::Point(v1[1]);
                pt[2] = cv::Point(v1[2]);
                cv::fillConvexPoly(warpedMask, pt, 3, Scalar(255));
                cv::fillConvexPoly(outMask   , pt, 3, Scalar(255));
                
                Mat outFilter = Mat::zeros(frame.rows, frame.cols, CV_8UC3);
                warpAffine(frame, outFilter, warpMat, outFilter.size());
                outFilter.copyTo(warpedFilter, outMask);
            });


        }
        
        warpedFilter.copyTo(frame, warpedMask);
        
    
    }
    image = frame;

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
