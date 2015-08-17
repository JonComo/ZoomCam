//
//  CaptureManager.m
//  Sequencer2
//
//  Created by Jon Como on 6/29/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "CaptureManager.h"

#import "Clip.h"

#import "Constants.h"

@interface CaptureManager () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureDevice *captureDevice;

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@property (nonatomic, strong) NSTimer *timerRecording;

@end

@implementation CaptureManager

-(instancetype)initWithDelegate:(id<CaptureManagerDelegate>)delegate {
    if (self = [super init]) {
        // init
        _delegate = delegate;
    }
    
    return self;
}

-(void)beginCaptureInView:(UIView *)previewView error:(NSError **)error success:(void(^)(void))successHandler {
    
    self.captureDevice = [CaptureManager cameraWithPosition:AVCaptureDevicePositionBack];
    
    if (!self.captureDevice) {
        *error = [NSError errorWithDomain:@"Couldn't find capture device" code:101 userInfo:nil];
        return;
    }
    
    self.captureSession = [[AVCaptureSession alloc] init];
    
    [self.captureSession beginConfiguration];
    
    self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:nil];
    
//    [self.videoInput.device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:NULL];
//    [self.videoInput.device addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:NULL];
    
    
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }else{
        *error = [NSError errorWithDomain:@"Error setting video input." code:101 userInfo:nil];
        return;
    }
    
    AVCaptureDevice *audioDevice = [CaptureManager audioDevice];
    
    if (!audioDevice) {
        *error = [NSError errorWithDomain:@"Error getting audio device" code:101 userInfo:nil];
        return;
    }
    
    NSError *audioInputError = nil;
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&audioInputError];
    
    if (audioInputError) {
        *error = [NSError errorWithDomain:@"Error setting audio input" code:101 userInfo:nil];
        return;
    }
    
    if ([self.captureSession canAddInput:self.audioInput]) {
        [self.captureSession addInput:self.audioInput];
    }else{
        *error = [NSError errorWithDomain:@"Error setting audio input to capture session." code:101 userInfo:nil];
        return;
    }
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if ([self.captureSession canAddOutput:self.movieFileOutput]) {
        [self.captureSession addOutput:self.movieFileOutput];
        
        [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo].preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation = AVCaptureVideoOrientationPortrait;
    }else{
        *error = [NSError errorWithDomain:@"Error setting file output." code:101 userInfo:nil];
        return;
    }
    
    // Setup video preview layer
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    
    self.previewLayer.frame = CGRectMake(0.f, 0.f, previewView.bounds.size.width, previewView.bounds.size.width * 640.f/480.f);
    self.previewLayer.backgroundColor = [UIColor blackColor].CGColor;
    [previewView.layer insertSublayer:self.previewLayer below:previewView.layer.sublayers[0]];
    
    [self.captureSession commitConfiguration];
    
    [self.captureSession startRunning];
    
    self.canRecord = YES;
    
    if (successHandler) {
        successHandler();
    }
}

- (void)endCapture {
    [self.captureSession stopRunning];
}

//-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    
//}

#pragma mark - Recording

- (void)record
{
    if (!self.canRecord) return;
    if (self.recording) return;
    if (![self.captureSession isRunning]) return;
    if (self.movieFileOutput.isRecording) return;
    
    NSLog(@"Recording");
    
    self.recording = YES;
    self.canRecord = NO;
    
    [self.movieFileOutput startRecordingToOutputFileURL:[Constants uniqueClipURL] recordingDelegate:self];
}

- (void)stop
{
    if (!self.recording) {
        return;
    }
    
    if ([self.movieFileOutput isRecording]) {
        [self.movieFileOutput stopRecording];
    }
}

- (void)recordTick:(NSTimer *)timer {
    self.timeRecording += timer.timeInterval;
}

#pragma mark - Device methods

+ (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    __block AVCaptureDevice *foundDevice = nil;
    
    [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] enumerateObjectsUsingBlock:^(AVCaptureDevice *device, NSUInteger idx, BOOL *stop) {
        
        if (device.position == position)
        {
            foundDevice = device;
            *stop = YES;
        }
        
    }];
    
    return foundDevice;
}

+ (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if (devices.count > 0)
    {
        return [devices firstObject];
    }
    
    return nil;
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    self.canRecord = NO;
    
    if ([self.delegate respondsToSelector:@selector(captureManagerDidBeginRecording:)]) {
        [self.delegate captureManagerDidBeginRecording:self];
    }
    
    self.timerRecording = [NSTimer scheduledTimerWithTimeInterval:.1f target:self selector:@selector(recordTick:) userInfo:nil repeats:YES];
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    self.canRecord = YES;
    self.recording = NO;
    
    [self.timerRecording invalidate];
    self.timerRecording = nil;
    
    Clip *clip = [Clip clipWithURL:outputFileURL];
    
    if ([self.delegate respondsToSelector:@selector(captureManagerDidFinishRecording:clip:)]) {
        [self.delegate captureManagerDidFinishRecording:self clip:clip];
    }
}

@end
