//
//  WelcomeViewController.m
//  Paypoint
//
//  Created by Robert Nash on 16/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "WelcomeViewController.h"
#import "AVPlayerView.h"
#import "ColourManager.h"
#import "SubmitFormViewController.h"

@interface WelcomeViewController ()
@property (weak, nonatomic) IBOutlet AVPlayerView *playerView;
@property (nonatomic) BOOL hideStatusBar;
@property (nonatomic) CMTime currentTime;
@property (weak, nonatomic) IBOutlet UILabel *paypointLabel;
@property (weak, nonatomic) IBOutlet UIImageView *paypointLogo;
@property (weak, nonatomic) IBOutlet UIView *logoContainer;
@property (weak, nonatomic) IBOutlet UIView *splashView;
@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.paypointLabel.textColor = [ColourManager ppBlue];
    
    [self playVideo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.playerView.player currentItem]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWilLResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

-(UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (CMTIME_IS_VALID(self.currentTime)) {
        [self.playerView.player seekToTime:self.currentTime];
    }
    
    [self.playerView.player play];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.splashView) {
        [UIView animateWithDuration:.3 animations:^{
            self.splashView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.splashView removeFromSuperview];
            self.splashView = nil;
        }];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.currentTime = self.playerView.player.currentTime;
    [self.playerView.player pause];
}

-(void)playVideo {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Clouds" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    
    self.playerView.player = player;
}

-(void)playerItemDidReachEnd:(NSNotification*)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    [self.playerView.player play];
}

-(void)appDidBecomeActive:(NSNotification*)notification {
    if (CMTIME_IS_VALID(self.currentTime)) {
        [self.playerView.player seekToTime:self.currentTime];
    }
    [self.playerView.player play];
}

-(void)appWilLResignActive:(NSNotification*)notification {
    self.currentTime = self.playerView.player.currentTime;
    [self.playerView.player pause];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
