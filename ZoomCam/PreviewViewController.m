//
//  PreviewViewController.m
//  ZoomCam
//
//  Created by Jon Como on 8/17/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "PreviewViewController.h"

@import MediaPlayer;
#import "Clip.h"

@interface PreviewViewController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (weak, nonatomic) IBOutlet UIButton *buttonShare;

@end

@implementation PreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.buttonShare addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:self.clip.asset.URL];
    [self.moviePlayer prepareToPlay];
    
    self.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    self.moviePlayer.shouldAutoplay = YES;
    self.moviePlayer.view.frame = CGRectMake(0.f, self.navigationController.navigationBar.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.width);
    
    [self.view addSubview:self.moviePlayer.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Preview";
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)share {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.clip.asset.URL] applicationActivities:nil];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)cancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
