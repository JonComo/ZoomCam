//
//  ViewController.m
//  ZoomCam
//
//  Created by Jon Como on 8/17/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "ViewController.h"

#import "Constants.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self clearClips];
}

- (void)clearClips {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *clips = [fileManager contentsOfDirectoryAtPath:[Constants clipsDirectory] error:nil];
    for (NSString *clipName in clips) {
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@", [Constants clipsDirectory], clipName] error:nil];
        NSLog(@"Cleared clip");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
