//
//  Clip.h
//  Sequencer2
//
//  Created by Jon Como on 6/29/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import <UIKit/UIKit.h>

@import AVFoundation;

@class Clip;

typedef void (^ClipHandler)(NSArray *clips);

@interface Clip : NSObject

@property (nonatomic, copy) NSArray *thumbnails;

@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, assign) CMTimeRange position;
@property (nonatomic, assign) BOOL highlightPlaying;
@property CGSize timelineSize;

+ (Clip *)clipWithURL:(NSURL *)url;
- (void)generateThumbnailsCompletion:(void(^)(NSError *error, NSArray *thumbnails))block;
- (BOOL)isPlayingAtTime:(CMTime)time;

#pragma export

- (void)duplicateCompletion:(ClipHandler)block;
- (void)exportTimeRange:(CMTimeRange)range completion:(ClipHandler)block;
- (void)splitAtTime:(CMTime)time completion:(ClipHandler)block;

@end
