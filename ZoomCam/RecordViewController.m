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
@property (weak, nonatomic) IBOutlet UIButton *buttonRecord;

@property (nonatomic, strong) NSMutableArray *zoomTimes;
@property (nonatomic, strong) NSTimer *zoomTimer;

@property (nonatomic, assign) BOOL touching;
@property (nonatomic, assign) CGFloat zoomLength;
@property (nonatomic, assign) BOOL latestTouchState;

@property (weak, nonatomic) IBOutlet UIButton *buttonSpin;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.zoomTimes = [NSMutableArray array];
    self.captureManager = [[CaptureManager alloc] initWithDelegate:self];
    
    self.zoomTimer = [NSTimer scheduledTimerWithTimeInterval:1.f/30.f target:self selector:@selector(checkTouch) userInfo:nil repeats:YES];
    
    self.touching = NO;
    self.latestTouchState = NO;
    
    [self.previewView.layer setZPosition:100.f];
}

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Record";
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIView *bgView = [[UIView alloc] initWithFrame:self.previewView.frame];
    bgView.backgroundColor = [UIColor blackColor];
    [self.view insertSubview:bgView belowSubview:self.previewView];
    
    self.zoomView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.previewView.bounds.size.width, self.previewView.bounds.size.height)];
    [self.previewView addSubview:self.zoomView];
    
    NSError *error = nil;
    [self.captureManager beginCaptureInView:self.zoomView error:&error success:^{
        
    }];
    
    if (error) {
        NSLog(@"Error %@", error);
    }
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

- (void)dealloc {
    NSLog(@"dealloc record");
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch.view == self.zoomView) {
            self.touching = YES;
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.touching = NO;
}

- (void)checkTouch {
    if (self.zoomLength < defaultZoomTime) {
        self.zoomLength += self.zoomTimer.timeInterval;
        return;
    }
    
    if (self.touching == self.latestTouchState) {
        return;
    }
    
    if (self.touching) {
        [UIView animateWithDuration:defaultZoomTime animations:^{
            self.zoomView.layer.transform = CATransform3DMakeScale(defaultZoomAmount, defaultZoomAmount, 1.f);
        }];
    } else {
        [UIView animateWithDuration:defaultZoomTime animations:^{
            self.zoomView.layer.transform = CATransform3DIdentity;
        }];
    }
    
    if (self.captureManager.recording) {
        [self.zoomTimes addObject:@(self.captureManager.timeRecording)];
    }
    
    self.zoomLength = 0.f;
    self.latestTouchState = self.touching;
}

- (IBAction)record:(id)sender {
    if (!self.captureManager.canRecord) {
        return;
    }
    
    if (!self.captureManager.recording) {
        [self.captureManager record];
        [self.buttonRecord setImage:[UIImage imageNamed:@"done"] forState:UIControlStateNormal];
        
        self.buttonSpin.userInteractionEnabled = NO;
        self.buttonCancel.userInteractionEnabled = NO;
        
        __weak RecordViewController *weakSelf = self;
        [UIView animateWithDuration:.3f animations:^{
            weakSelf.buttonCancel.layer.transform = CATransform3DMakeTranslation(0.f, 100.f, 0.f);
            weakSelf.buttonSpin.layer.transform = CATransform3DMakeTranslation(0.f, 100.f, 0.f);
        }];
        
    } else {
        [sender setUserInteractionEnabled:NO];
        
        [self.buttonRecord setImage:[UIImage imageNamed:@"circle"] forState:UIControlStateNormal];
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activity.center = self.buttonRecord.center;
        [activity startAnimating];
        activity.color = [UIColor blackColor];
        [self.view addSubview:activity];
        
        [self.captureManager stop];
    }
}

- (IBAction)spinCam:(id)sender {
    const CGFloat time = .15f;
    
    self.buttonSpin.userInteractionEnabled = NO;
    
    __weak RecordViewController *weakSelf = self;
    
    self.buttonSpin.layer.transform = CATransform3DIdentity;
    [UIView animateWithDuration:.3f animations:^{
        weakSelf.buttonSpin.layer.transform = CATransform3DMakeRotation(M_PI * 2.f, 0.f, 0.f, 1.f);
    }];
    
    [UIView animateWithDuration:time animations:^{
        weakSelf.previewView.layer.transform = CATransform3DMakeRotation(M_PI_2, 0.f, 1.f, 0.f);
    } completion:^(BOOL finished) {
        
        [weakSelf.captureManager toggleCamera];

        [UIView animateWithDuration:time animations:^{
            weakSelf.previewView.layer.transform = CATransform3DIdentity;
        } completion:^(BOOL finished) {
            weakSelf.buttonSpin.userInteractionEnabled = YES;
        }];
    }];
}

- (IBAction)cancel:(id)sender {
    __weak RecordViewController *weakSelf = self;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)captureManagerDidBeginRecording:(CaptureManager *)manager {
    self.previewView.layer.borderColor = [UIColor redColor].CGColor;
    self.previewView.layer.borderWidth = 2.f;
    self.buttonSpin.userInteractionEnabled = NO;
}

- (void)captureManagerDidFinishRecording:(CaptureManager *)manager clip:(Clip *)clip {
    self.previewView.layer.borderWidth = 0.f;
    self.buttonSpin.userInteractionEnabled = YES;
    
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
