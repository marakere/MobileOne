//
//  SecondViewController.m
//  SinclairPoc
//
//  Created by Arun on 2/4/17.
//  Copyright © 2017 Object Frontier. Inc.,. All rights reserved.
//

#import "SecondViewController.h"
#import <AVKit/AVPlayerViewController.h>
#import <AVFoundation/AVPlayer.h>
#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>
@interface SecondViewController () <IMAAdsLoaderDelegate, IMAAdsManagerDelegate>

@property(nonatomic, strong) AVPlayerViewController *controller;
@property(nonatomic, strong) UIButton *playButton;

// SDK
/// Entry point for the SDK. Used to make ad requests.
@property(nonatomic, strong) IMAAdsLoader *adsLoader;

/// Playhead used by the SDK to track content video progress and insert mid-rolls.
@property(nonatomic, strong) IMAAVPlayerContentPlayhead *contentPlayhead;

/// Main point of interaction with the SDK. Created by the SDK as the result of an ad request.
@property(nonatomic, strong) IMAAdsManager *adsManager;
@end

@implementation SecondViewController

    NSString *const VOD = @"http://rmcdn.2mdn.net/Demo/html5/output.mp4"; //@"https://s3-eu-west-1.amazonaws.com/alf-proeysen/Bakvendtland-MASTER.mp4";
    NSString *const live = @"https://youtu.be/pCZeVTMEsik";

    // Pre-roll
    //NSString *const kTestAppAdTagUrl = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    //  @"iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&"
    //  @"output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&"
    //  @"correlator=";
    // Post-roll
    //NSString *const kTestAppAdTagUrl = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    //  @"iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&"
    //  @"output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpostonly&cmsid=496&vid=short_onecue&"
    //  @"correlator=";
    // All-roll
    NSString *const kTestAppAdTagUrl = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
        @"iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&"
        @"output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&"
        @"correlator=";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self createPlayer];
    [self setupAdsLoader];
}

- (void)createPlayer {
    
    NSURL *url = [[NSURL alloc] initWithString:VOD];
    
    // create a player view controller
    AVPlayer *player = [AVPlayer playerWithURL:url];
    self.controller = [[AVPlayerViewController alloc] init];
    
    [self addChildViewController:self.controller];
    [self.view addSubview:self.controller.view];
    
    double time = MAXFLOAT;
    [player seekToTime: CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    
    CGRect frame = self.view.bounds;
    frame.origin.y = 64;
    frame.size.height /= 2;
    frame.size.height -= 44 + 64;

    self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(onPlayButtonClick) forControlEvents:UIControlEventTouchDown];
    self.playButton.frame = CGRectMake(110, 40, 100, 100);
    [self.controller.view addSubview:self.playButton];
    
    self.controller.view.frame = frame;
    self.controller.player = player;
    self.controller.showsPlaybackControls = NO;
    player.closedCaptionDisplayEnabled = YES;
    
    
    // Set up our content playhead and contentComplete callback.
    self.contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:self.controller.player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.controller.player.currentItem];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onPlayButtonClick {
    
    if ([self.controller.player status] == AVPlayerStatusReadyToPlay) {
        
        [self requestAds];
        self.playButton.hidden = YES;
        self.controller.showsPlaybackControls = YES;
    }
    
}

#pragma mark SDK Setup

- (void)setupAdsLoader {
    self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
    self.adsLoader.delegate = self;
}

- (void)requestAds {
    // Create an ad display container for ad rendering.
    IMAAdDisplayContainer *adDisplayContainer =
    [[IMAAdDisplayContainer alloc] initWithAdContainer:self.controller.view companionSlots:nil];
    // Create an ad request with our ad tag, display container, and optional user context.
    IMAAdsRequest *request = [[IMAAdsRequest alloc] initWithAdTagUrl:kTestAppAdTagUrl
                                                  adDisplayContainer:adDisplayContainer
                                                     contentPlayhead:self.contentPlayhead
                                                         userContext:nil];
    [self.adsLoader requestAdsWithRequest:request];
    [self.controller.player play];
}

- (void)contentDidFinishPlaying:(NSNotification *)notification {
    // Make sure we don't call contentComplete as a result of an ad completing.
    if (notification.object == self.controller.player.currentItem) {
        [self.adsLoader contentComplete];
        self.playButton.hidden = NO;
    }
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    self.adsManager = adsLoadedData.adsManager;
    self.adsManager.delegate = self;
    // Create ads rendering settings to tell the SDK to use the in-app browser.
    IMAAdsRenderingSettings *adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
    adsRenderingSettings.webOpenerPresentingController = self;
   
    // Initialize the ads manager.
    [self.adsManager initializeWithAdsRenderingSettings:adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
    // Something went wrong loading ads. Log the error and play the content.
    NSLog(@"Error loading ads: %@", adErrorData.adError.message);
    [self.controller.player play];
}

#pragma mark AdsManager Delegates

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdEvent:(IMAAdEvent *)event {
    // When the SDK notified us that ads have been loaded, play them.
    if (event.type == kIMAAdEvent_LOADED) {
        [adsManager start];
    }
}

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
    // Something went wrong with the ads manager after ads were loaded. Log the error and play the
    // content.
    NSLog(@"AdsManager error: %@", error.message);
    [self.controller.player play];
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
    // The SDK is going to play ads, so pause the content.
    [self.controller.player pause];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
    // The SDK is done playing ads (at least for now), so resume the content.
    [self.controller.player play];
}
@end
