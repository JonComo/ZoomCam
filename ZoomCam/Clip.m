//
//  Clip.m
//  Sequencer2
//
//  Created by Jon Como on 6/29/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "Clip.h"

#import "Constants.h"
#import "Composition.h"

@import AVFoundation;

@implementation Clip

+ (Clip *)clipWithURL:(NSURL *)url {
    Clip *clip = [Clip new];
    
    clip.asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    clip.timelineSize = CGSizeMake(CMTimeGetSeconds(clip.asset.duration) * defaultClipHeight, defaultClipHeight);
    
    return clip;
}

- (void)generateThumbnailsCompletion:(void(^)(NSError *error, NSArray *thumbnails))block
{
    NSMutableArray *thumbnails = [NSMutableArray array];
    
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    //imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    //imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    
    CGFloat picWidth = self.timelineSize.height;
    imageGenerator.maximumSize = CGSizeMake(picWidth, picWidth);
    
    //Generate rest of the images
    //CMTime duration = asset.duration;
    
    int numberToGenerate = ceil(self.timelineSize.width / picWidth);
    
    NSMutableArray *times = [NSMutableArray array];
    
    [times addObject:[NSValue valueWithCMTime:kCMTimeZero]]; //first image
    
    float offsetX = 0;
    
    for (int i = 0; i<numberToGenerate; i++)
    {
        offsetX += picWidth;
        
        //float ratio = offsetX / size.width;
        
        //CMTime timeFrame = CMTimeMultiplyByFloat64(duration, ratio);
        CMTime timeFrame = CMTimeMake(offsetX, 30);
        
        NSLog(@"Generating thumbnails for time: %lld timescale: %d", timeFrame.value, timeFrame.timescale);
        
        [times addObject:[NSValue valueWithCMTime:timeFrame]];
    }
    
    [times addObject:[NSValue valueWithCMTime:self.asset.duration]]; //last image
    
    
    __weak Clip *weakSelf = self;
    [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
            [thumbnails addObject:thumb];
            
            if (thumbnails.count == times.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.thumbnails = thumbnails;
                    if (block) block(nil, thumbnails);
                });
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result == AVAssetImageGeneratorFailed) {
                weakSelf.thumbnails = nil;
                if (block) block(error, nil);
            } else if (result == AVAssetImageGeneratorCancelled) {
                weakSelf.thumbnails = nil;
                if (block) block([NSError errorWithDomain:@"Canceled" code:0 userInfo:nil], nil);
            }
        });
    }];
}

+ (UIImage *)thumbnailFromURL:(NSURL *)assetURL {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CGImageRef rawRef = [imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil];
    
    CGImageRef cropped = CGImageCreateWithImageInRect(rawRef, CGRectMake(0.f, 0.f, CGImageGetWidth(rawRef), CGImageGetWidth(rawRef)));
    
    
    return [Clip resizeImage:cropped newSize:CGSizeMake(defaultClipHeight, defaultClipHeight)];
}

+ (UIImage *)resizeImage:(CGImageRef)imageRef newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (BOOL)isPlayingAtTime:(CMTime)time {
    BOOL withinTime = CMTimeRangeContainsTime(self.position, time);
    
    if (withinTime) return withinTime;
    
    //check if ends equal
    if (CMTimeCompare(time, CMTimeAdd(self.position.start, self.position.duration)) == 0) return YES;
    
    return NO;
}

- (void)duplicateCompletion:(ClipHandler)block {
    
    NSURL *newURL = [Constants uniqueClipURL];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtURL:self.asset.URL toURL:newURL error:&error];
    
    Clip *newClip = [Clip clipWithURL:newURL];
    newClip.thumbnails = self.thumbnails;
    
    if (block) {
        block(@[newClip]);
    }
}

- (void)exportTimeRange:(CMTimeRange)range completion:(ClipHandler)block {
    
    NSLog(@"Exporting time range: %f %f", CMTimeGetSeconds(range.start), CMTimeGetSeconds(range.duration));
    
    NSArray *comps = [Composition compositionFromClips:@[self] range:range];
    AVComposition *composition = [comps firstObject];
    AVVideoComposition *videoComposition = [comps lastObject];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = [Constants uniqueClipURL];
    
    //NSTimer *timerProgress = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{

            switch([exporter status])
            {
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusCancelled:
                case AVAssetExportSessionStatusCompleted:
                {
                    //success
                    Clip *newClip = [Clip clipWithURL:exporter.outputURL];
                    [newClip generateThumbnailsCompletion:^(NSError *error, NSArray *thumbnails) {
                        block(@[newClip]);
                    }];
                } break;
                    
                default:
                {
                    block(nil);
                }
            }
        });
    }];
}

- (void)splitAtTime:(CMTime)time completion:(ClipHandler)block {
    NSMutableArray *newClips = [NSMutableArray array];
    
    __weak Clip *weakSelf = self;
    
    [self exportTimeRange:CMTimeRangeMake(self.position.start, time) completion:^(NSArray *clips) {
        [newClips insertObject:[clips firstObject] atIndex:0];
        
        [self exportTimeRange:CMTimeRangeMake(time, CMTimeSubtract(weakSelf.asset.duration, time)) completion:^(NSArray *clips) {
            [newClips insertObject:[clips firstObject] atIndex:0];
            
            if (block) {
                block(newClips);
            }
        }];
    }];
}

@end