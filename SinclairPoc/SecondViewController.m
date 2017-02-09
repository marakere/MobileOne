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
@property(nonatomic, strong) AVPlayerItem *mainPlayerItem;
@property(nonatomic) CMTime mainSTT;
@property(nonatomic, strong) AVPlayerItem *breakingNewsPlayerItem;
@property(nonatomic) BOOL iscalled;
// SDK
/// Entry point for the SDK. Used to make ad requests.
@property(nonatomic, strong) IMAAdsLoader *adsLoader;

/// Playhead used by the SDK to track content video progress and insert mid-rolls.
@property(nonatomic, strong) IMAAVPlayerContentPlayhead *contentPlayhead;

/// Main point of interaction with the SDK. Created by the SDK as the result of an ad request.
@property(nonatomic, strong) IMAAdsManager *adsManager;

@property(nonatomic, strong) IMAAdDisplayContainer *adDisplayContainer;
@property(nonatomic, strong) UIView *adView;

//Temp
@property(nonatomic, weak) IBOutlet UITextView *logView;
@property(nonatomic, strong) NSMutableString *logText;

@end

@implementation SecondViewController

    NSString *const VOD = @"http://clips.vorwaerts-gmbh.de/VfE_html5.mp4";
        //@"http://rmcdn.2mdn.net/Demo/html5/output.mp4";
        //@"https://s3-eu-west-1.amazonaws.com/alf-proeysen/Bakvendtland-MASTER.mp4";
    NSString *const live = @"https://youtu.be/pCZeVTMEsik";
    NSString *const breakingNews = @"http://techslides.com/demos/sample-videos/small.mp4";

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
    
    self.logText = [[NSMutableString alloc] initWithString:@"Main content video Started\n"];
    [self.logView setText:self.logText];
    
    if ([self.controller.player status] == AVPlayerStatusReadyToPlay) {
        
        [self requestAds];
        self.playButton.hidden = YES;
        self.controller.showsPlaybackControls = YES;
        self.iscalled = NO;
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(countDown)
                                       userInfo:nil
                                        repeats:YES];
    }
    
}

- (void) countDown {
    
//    NSLog(@"%f", self.controller.player.rate);
//    NSLog(@"%@", self.controller.player.currentItem);
//    NSLog(@"%f", CMTimeGetSeconds(self.controller.player.currentItem.currentTime));
    if(self.controller.player.rate == 0) {
        if(CMTimeGetSeconds(self.controller.player.currentItem.currentTime) < 1.00) {
            if(![self.logText hasSuffix:@"Playing Pre-roll ads\n"]){
                [self.logText appendString:@"Playing Pre-roll ads\n"];
                self.logView.text = self.logText;
            }
           
        } else if(CMTimeGetSeconds(self.controller.player.currentItem.currentTime) > 15.00 && !self.iscalled) {
            if(![self.logText hasSuffix:@"Playing Mid-roll ads @ 15 sec\n"]){
                [self.logText appendString:@"Playing Mid-roll ads @ 15 sec\n"];
                self.logView.text = self.logText;
            }
            self.iscalled = YES;
            self.mainPlayerItem = self.controller.player.currentItem;
            self.mainSTT = self.controller.player.currentItem.currentTime;
            [NSTimer scheduledTimerWithTimeInterval:5
                                             target:self
                                           selector:@selector(pauseAds)
                                           userInfo:nil
                                            repeats:NO];
        } else if(CMTimeGetSeconds(self.controller.player.currentItem.currentTime) > 20.00) {
            if(![self.logText hasSuffix:@"Playing Post-roll ads\n"]){
                [self.logText appendString:@"Playing Post-roll ads\n"];
                self.logView.text = self.logText;
            }
        }
    }
}

- (void) pauseAds {
    
    [self.adsManager pause];
    self.adView.hidden = YES;
    [self.logText appendString:@"Mid-roll ad paused @ 5th sec\n"];
    self.logView.text = self.logText;
    self.breakingNewsPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:breakingNews]];
    [self.controller.player replaceCurrentItemWithPlayerItem:self.breakingNewsPlayerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.controller.player.currentItem];
    [self.controller.player play];
    [self.logText appendString:@"Playing breaking content video\n"];
    self.logView.text = self.logText;
}

#pragma mark SDK Setup

- (void)setupAdsLoader {
    self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
    self.adsLoader.delegate = self;
}

- (void)requestAds {
    // Create an ad display container for ad rendering.
    self.adView = [[UIView alloc] initWithFrame:self.controller.view.frame];
    [self.view addSubview:self.adView];
    self.adView.hidden = YES;
    self.adDisplayContainer = [[IMAAdDisplayContainer alloc] initWithAdContainer:self.adView companionSlots:nil];
    // Create an ad request with our ad tag, display container, and optional user context.
    IMAAdsRequest *request = [[IMAAdsRequest alloc] initWithAdTagUrl:kTestAppAdTagUrl
                                                  adDisplayContainer:self.adDisplayContainer
                                                     contentPlayhead:self.contentPlayhead
                                                         userContext:nil];
    [self.adsLoader requestAdsWithRequest:request];
    [self.controller.player play];
}

- (void)contentDidFinishPlaying:(NSNotification *)notification {
    // Make sure we don't call contentComplete as a result of an ad completing.
    if (notification.object == self.controller.player.currentItem && notification.object == self.mainPlayerItem) {
        [self.adsLoader contentComplete];
        self.playButton.hidden = NO;
        [self.logText appendString:@"Video ended\n"];
        self.logView.text = self.logText;
    } else if(notification.object == self.breakingNewsPlayerItem) {
        [self.adsManager resume];
        self.adView.hidden = NO;
        [self.logText appendString:@"Resume Mid-roll ads from 5th sec\n"];
        self.logView.text = self.logText;
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
    self.adView.hidden = NO;
    [self.controller.player pause];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
    // The SDK is done playing ads (at least for now), so resume the content.
    self.adView.hidden = YES;
    if(self.mainPlayerItem && self.controller.player.currentItem != self.mainPlayerItem) {
        [self.controller.player replaceCurrentItemWithPlayerItem:self.mainPlayerItem];
        [self.controller.player.currentItem seekToTime:self.mainSTT];
    }
    [self.controller.player play];
    [self.logText appendString:@"Resume main content video after ads\n"];
    self.logView.text = self.logText;
}
@end
