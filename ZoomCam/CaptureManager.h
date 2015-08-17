//
//  CaptureManager.h
//  Sequencer2
//
//  Created by Jon Como on 6/29/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Clip, CaptureManager;

@protocol CaptureManagerDelegate <NSObject>

-(void)captureManagerDidBeginRecording:(CaptureManager *)manager;
-(void)captureManagerDidFinishRecording:(CaptureManager *)manager clip:(Clip *)clip;

@end

@import AVFoundation;

@interface CaptureManager : NSObject

@property (nonatomic, assign) BOOL recording;
@property (nonatomic, assign) BOOL canRecord;
@property (nonatomic, weak) id<CaptureManagerDelegate>delegate;
@property (nonatomic, assign) CGFloat timeRecording;

- (instancetype)initWithDelegate:(id<CaptureManagerDelegate>)delegate;

- (void)beginCaptureInView:(UIView *)previewView error:(NSError **)error success:(void(^)(void))successHandler;
- (void)endCapture;

- (AVCaptureVideoPreviewLayer *)previewLayer;

- (void)record;
- (void)stop;



@end
