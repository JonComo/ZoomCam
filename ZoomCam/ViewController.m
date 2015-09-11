//
//  ViewController.m
//  ZoomCam
//
//  Created by Jon Como on 8/17/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "ViewController.h"

#import "GPUCaptureManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageViewLogo;
@property (nonatomic, strong) NSTimer *timerLogo;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.imageViewLogo.layer.zPosition = 100.f;
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self clearClips];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.timerLogo) {
        self.timerLogo = [NSTimer scheduledTimerWithTimeInterval:2.f target:self selector:@selector(animateLogo) userInfo:nil repeats:YES];
    }
}

- (void)animateLogo {
    if (self.presentedViewController) {
        return;
    }
    
    NSLog(@"boom");
    
    UIImageView *copy = [[UIImageView alloc] initWithFrame:self.imageViewLogo.frame];
    copy.image = self.imageViewLogo.image;
    copy.alpha = .2f;
    copy.layer.zPosition = 0.f;
    [self.view addSubview:copy];
        
    const CGFloat zoom = 2.f;
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView animateWithDuration:4.f animations:^{
        copy.layer.transform = CATransform3DMakeScale(zoom, zoom, zoom);
        copy.alpha = 0.f;
    } completion:^(BOOL finished) {
        [copy removeFromSuperview];
    }];
}

- (void)clearClips {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *clips = [fileManager contentsOfDirectoryAtPath:[GPUCaptureManager clipsDirectory] error:nil];
    for (NSString *clipName in clips) {
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@", [GPUCaptureManager clipsDirectory], clipName] error:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
