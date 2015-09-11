//
//  GPUCaptureManager.m
//  Sequencer2
//
//  Created by Jon Como on 8/29/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "GPUCaptureManager.h"

#import "GPUImage.h"

@interface GPUCaptureManager ()

@property (nonatomic, strong) GPUImageVideoCamera *camera;
@property (nonatomic, strong) GPUImageCropFilter *cropFilter;
@property (nonatomic, strong) GPUImageTransformFilter *transformFilter;

@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, copy) NSURL *fileURL;

@property (nonatomic, assign) CGFloat currentZoom;

@end

@implementation GPUCaptureManager

- (void)beginCaptureInView:(UIView *)previewView {
    self.targetZoom = 1.f;
    
    self.camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    self.camera.horizontallyMirrorFrontFacingCamera = YES;
    self.camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, previewView.bounds.size.width, previewView.bounds.size.height)];
    [previewView addSubview:filteredVideoView];
    
    self.cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.f, 1.f, 480.f/640.f)];
    self.transformFilter = [GPUImageTransformFilter new];
    
    self.fileURL = [GPUCaptureManager uniqueClipURL];
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.fileURL size:CGSizeMake(480.f, 480.f)];
    
    [self.camera addTarget:self.cropFilter];
    [self.cropFilter addTarget:self.transformFilter];
    [self.transformFilter addTarget:filteredVideoView];
    [self.transformFilter addTarget:self.movieWriter];
    self.camera.audioEncodingTarget = self.movieWriter;
    
    [self.camera startCameraCapture];
    
    self.currentZoom = 1.f;
    self.targetZoom = 1.f;
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateZoom)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)setTargetZoom:(CGFloat)targetZoom {
    _targetZoom = MAX(MIN(targetZoom, 3.f), 1.f);
}

- (void)updateZoom {
    CGFloat lastZoom = self.currentZoom;
    self.currentZoom -= (self.currentZoom - self.targetZoom) * .3f;
    
    if (ABS(lastZoom - self.currentZoom) < 0.01f) {
        return;
    }
    
    self.transformFilter.transform3D = CATransform3DMakeScale(self.currentZoom, self.currentZoom, 1.f);
}

- (void)endCapture {
    [self.camera stopCameraCapture];
}

- (void)record {
    [self.movieWriter startRecording];
}

- (void)stopWithCompletion:(RecordFinished)handler {
    __weak GPUCaptureManager *weakSelf = self;
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(weakSelf.fileURL);
            }
        });
    }];
}

- (void)toggleCamera {
    [self.camera rotateCamera];
}

+ (NSURL *)uniqueClipURL {
    NSString *returnPath = nil;
    
    int i = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    do {
        returnPath = [NSString stringWithFormat:@"%@/clip%i.mov", [GPUCaptureManager clipsDirectory], i];
        i++;
    } while ([fileManager fileExistsAtPath:returnPath]);
    
    return [NSURL fileURLWithPath:returnPath];
}

+ (NSString *)clipsDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [directories firstObject];
    
    NSString *clipsDirectory = [NSString stringWithFormat:@"%@/%@", documents, @"clips"];
    
    if (![fileManager fileExistsAtPath:clipsDirectory isDirectory:nil]) {
        [fileManager createDirectoryAtPath:clipsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return clipsDirectory;
}

@end
