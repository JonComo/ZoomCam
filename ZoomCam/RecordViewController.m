//
//  RecordViewController.m
//  ZoomCam
//
//  Created by Jon Como on 8/17/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "RecordViewController.h"

#import "PreviewViewController.h"

#import "CaptureManager.h"
#import "Clip.h"
#import "Constants.h"

const float defaultZoomTime = .2f;
const float defaultZoomAmount = 3.f;

@interface RecordViewController () <CaptureManagerDelegate>

@property (nonatomic, strong) CaptureManager *captureManager;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (nonatomic, strong) UIView *zoomView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;

@property (nonatomic, strong) NSMutableArray *zoomTimes;


@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationItem.hidesBackButton = YES;
    
    self.zoomTimes = [NSMutableArray array];
    self.captureManager = [[CaptureManager alloc] initWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.zoomView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.previewView.bounds.size.width, self.previewView.bounds.size.height)];
    [self.previewView addSubview:self.zoomView];
    
    NSError *error = nil;
    [self.captureManager beginCaptureInView:self.zoomView error:&error success:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.captureManager stop];
    [self.captureManager endCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch.view == self.zoomView) {
            [UIView animateWithDuration:defaultZoomTime animations:^{
                self.zoomView.layer.transform = CATransform3DMakeScale(defaultZoomAmount, defaultZoomAmount, 1.f);
            }];
            
            if (self.captureManager.recording) {
                [self.zoomTimes addObject:@(self.captureManager.timeRecording)];
            }
            
            NSLog(@"zoom in ");
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [UIView animateWithDuration:defaultZoomTime animations:^{
        self.zoomView.layer.transform = CATransform3DIdentity;
    }];
    
    if (self.captureManager.recording) {
        [self.zoomTimes addObject:@(self.captureManager.timeRecording)];
    }
    
    NSLog(@"zoom out");
}

- (IBAction)record:(id)sender {
    if (!self.captureManager.recording) {
        [self.captureManager record];
        [self.recordButton setTitle:@"Done" forState:UIControlStateNormal];
    } else {
        [sender setUserInteractionEnabled:NO];
        [self.captureManager stop];
    }
}

- (void)captureManagerDidBeginRecording:(CaptureManager *)manager {
    self.previewView.layer.borderColor = [UIColor redColor].CGColor;
    self.previewView.layer.borderWidth = 2.f;
}

- (void)captureManagerDidFinishRecording:(CaptureManager *)manager clip:(Clip *)clip {
    self.previewView.layer.borderWidth = 0.f;
    
    __weak RecordViewController *weakSelf = self;
    [self renderFullClip:clip completion:^(NSURL *outputURL) {
        PreviewViewController *previewVC = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"previewVC"];
        previewVC.clip = [Clip clipWithURL:outputURL];
        [weakSelf.navigationController pushViewController:previewVC animated:YES];
    }];
}

- (void)renderFullClip:(Clip *)clip completion:(void(^)(NSURL *outputURL))completionHandler {
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVURLAsset *asset = clip.asset;
    
    NSMutableArray *instructions = [NSMutableArray array];
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:asset];

    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    AVAssetTrack *clipVideoTrack = videoTracks.count != 0 ? videoTracks[0] : nil;
    AVAssetTrack *clipAudioTrack = audioTracks.count != 0 ? audioTracks[0] : nil;
    
    if (clipVideoTrack) {
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
    }
    
    if (clipAudioTrack) {
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:clipAudioTrack atTime:kCMTimeZero error:nil];
    }
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    // Setup transforms
    
    CGAffineTransform transformIdentity = videoTrack.preferredTransform;
    
    float ratio = clipVideoTrack.naturalSize.width / clipVideoTrack.naturalSize.height;
    transformIdentity = CGAffineTransformScale(transformIdentity, ratio, ratio);
    transformIdentity = CGAffineTransformRotate(transformIdentity, M_PI_2);
    transformIdentity = CGAffineTransformTranslate(transformIdentity, 0.f, -clipVideoTrack.naturalSize.height);
    
    float translateAmount = videoTrack.naturalSize.height;
    CGAffineTransform transformZoom = CGAffineTransformTranslate(transformIdentity, -translateAmount, -translateAmount);
    transformZoom = CGAffineTransformScale(transformZoom, defaultZoomAmount, defaultZoomAmount);
    
    [layerInstruction setTransform:transformIdentity atTime:kCMTimeZero];
    
    BOOL zoomedIn = NO;
    
    for (NSNumber *zoomTime in self.zoomTimes) {
        
        CMTime startZoom = CMTimeMakeWithSeconds([zoomTime floatValue], NSEC_PER_SEC);
        CMTimeRange range = CMTimeRangeMake(startZoom, CMTimeMakeWithSeconds(defaultZoomTime, NSEC_PER_SEC));
        
        if (!zoomedIn) {
            
            [layerInstruction setTransformRampFromStartTransform:transformIdentity toEndTransform:transformZoom timeRange:range];
        } else {
            [layerInstruction setTransformRampFromStartTransform:transformZoom toEndTransform:transformIdentity timeRange:range];
        }
        
        zoomedIn = !zoomedIn;
    }
    
    instruction.layerInstructions = @[layerInstruction];
    instruction.timeRange = range;
    
    [instructions addObject:instruction];
    
    mutableVideoComposition.instructions = instructions;
    mutableVideoComposition.renderSize = CGSizeMake(640.f, 640.f);
    
    // Export composition
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPreset640x480];
    
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = mutableVideoComposition;
    exporter.outputURL = [Constants uniqueClipURL];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            switch([exporter status])
            {
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusCancelled:
                {
                    completionHandler(nil);
                } break;
                case AVAssetExportSessionStatusCompleted:
                {
                    completionHandler(exporter.outputURL);
                } break;
                default:
                {
                    completionHandler(nil);
                } break;
            }
        });
    }];
}

@end
