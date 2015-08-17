//
//  Composition.m
//  Sequencer2
//
//  Created by Jon Como on 7/10/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "Composition.h"

#import "Clip.h"

@import AVFoundation;

@implementation Composition

+ (NSArray *)compositionFromClips:(NSArray *)clips range:(CMTimeRange)range {
    if (clips.count == 0) {
        return nil;
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableVideoComposition *mutableVideoComposition = nil;
    NSMutableArray *instructions = [NSMutableArray array];
    
    CMTime startTime = kCMTimeZero;
    
    for (Clip *clip in clips)
    {
        AVURLAsset *asset = clip.asset;
        
        if (!mutableVideoComposition){
            mutableVideoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:asset];
        }
        
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        
        AVAssetTrack *clipVideoTrack = videoTracks.count != 0 ? videoTracks[0] : nil;
        AVAssetTrack *clipAudioTrack = audioTracks.count != 0 ? audioTracks[0] : nil;
        
        // If time range is invalid make it the range of the clip
        if (CMTimeRangeEqual(range, kCMTimeRangeInvalid)) {
            range = CMTimeRangeMake(kCMTimeZero, asset.duration);
        }
        
        if (clipVideoTrack) {
            [videoTrack insertTimeRange:range ofTrack:clipVideoTrack atTime:startTime error:nil];
        }
        
        if (clipAudioTrack) {
            [audioTrack insertTimeRange:range ofTrack:clipAudioTrack atTime:startTime error:nil];
        }
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        CMTimeRange range = CMTimeRangeMake(startTime, asset.duration);
        //[layerInstruction setTransform:videoTrack.preferredTransform atTime:startTime];
        
        instruction.layerInstructions = @[layerInstruction];
        instruction.timeRange = range;
        
        [instructions addObject:instruction];
        
        CMTime duration = clip.asset.duration;
        startTime = CMTimeAdd(startTime, duration);
    }
    
    mutableVideoComposition.instructions = instructions;
    //mutableVideoComposition.renderSize = CGSizeMake(640.f, 640.f);
    
    return @[composition, mutableVideoComposition];
}

+ (NSArray *)compositionFromClips:(NSArray *)clips
{
    return [Composition compositionFromClips:clips range:kCMTimeRangeInvalid];
}

+ (void)exportComps:(NSArray *)comps outputURL:(NSURL *)outputURL completion:(ExportBlock)completionHandler {
    AVComposition *compositon = [comps firstObject];
    AVMutableVideoComposition *videoComposition = [comps lastObject];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:compositon presetName:AVAssetExportPreset640x480];
    
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = outputURL;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        switch([exporter status])
        {
            case AVAssetExportSessionStatusFailed:
            case AVAssetExportSessionStatusCancelled:
            {
                completionHandler(nil);
            } break;
            case AVAssetExportSessionStatusCompleted:
            {
                completionHandler(outputURL);
            } break;
            default:
            {
                completionHandler(nil);
            } break;
        }
    }];
}

@end
