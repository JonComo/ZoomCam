//
//  Composition.h
//  Sequencer2
//
//  Created by Jon Como on 7/10/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AVFoundation;

typedef void (^ExportBlock)(NSURL *fileURL);

@interface Composition : NSObject

+ (NSArray *)compositionFromClips:(NSArray *)clips;
+ (NSArray *)compositionFromClips:(NSArray *)clips range:(CMTimeRange)range;

+ (void)exportComps:(NSArray *)comps outputURL:(NSURL *)outputURL completion:(ExportBlock)completionHandler;

@end
