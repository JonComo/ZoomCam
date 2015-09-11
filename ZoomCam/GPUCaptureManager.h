//
//  GPUCaptureManager.h
//  Sequencer2
//
//  Created by Jon Como on 8/29/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^RecordFinished)(NSURL *fileURL);

@interface GPUCaptureManager : NSObject

@property (nonatomic, assign) CGFloat targetZoom;

- (void)beginCaptureInView:(UIView *)previewView;
- (void)endCapture;

- (void)record;
- (void)stopWithCompletion:(RecordFinished)handler;

- (void)toggleCamera;

+ (NSString *)clipsDirectory;

@end