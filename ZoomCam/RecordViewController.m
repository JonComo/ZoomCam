//
//  RecordViewController.m
//  ZoomCam
//
//  Created by Jon Como on 8/17/15.
//  Copyright (c) 2015 Jon Como. All rights reserved.
//

#import "RecordViewController.h"

#import "PreviewViewController.h"
#import "GPUCaptureManager.h"

@import AVFoundation;

@interface RecordViewController ()

@property (nonatomic, strong) GPUCaptureManager *captureManager;

@property (weak, nonatomic) IBOutlet UIView *previewView;

@property (weak, nonatomic) IBOutlet UIButton *buttonRecord;
@property (weak, nonatomic) IBOutlet UIButton *buttonSpin;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;

@property (nonatomic, assign) BOOL recording;

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.previewView.layer.zPosition = 100.f;
    
    self.captureManager = [GPUCaptureManager new];
    
    self.navigationItem.title = @"Record";
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIView *bgView = [[UIView alloc] initWithFrame:self.previewView.frame];
    bgView.backgroundColor = [UIColor blackColor];
    [self.view insertSubview:bgView belowSubview:self.previewView];
    
    [self.captureManager beginCaptureInView:self.previewView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.captureManager stopWithCompletion:nil];
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
        if (touch.view == self.previewView || touch.view == self.previewView.subviews[0]) {
            self.captureManager.targetZoom = 3.f;
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.captureManager.targetZoom = 1.f;
}

- (IBAction)record:(id)sender {
    
    if (!self.recording) {
        self.recording = YES;
        
        self.previewView.layer.borderColor = [UIColor redColor].CGColor;
        self.previewView.layer.borderWidth = 2.f;
        self.buttonSpin.userInteractionEnabled = NO;
        
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
        
        __weak RecordViewController *weakSelf = self;
        [self.captureManager stopWithCompletion:^(NSURL *fileURL) {
            weakSelf.previewView.layer.borderWidth = 0.f;
            
            PreviewViewController *previewVC = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"previewVC"];
            previewVC.fileURL = fileURL;
            [weakSelf.navigationController pushViewController:previewVC animated:YES];
        }];
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

@end
