//
//  FirstViewController.m
//  SinclairPoc
//
//  Created by Arun on 2/4/17.
//  Copyright © 2017 Object Frontier. Inc.,. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Video Screen";
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self createPlayer];
    [self.view addSubview:self.player.view];
}

- (void)createPlayer
{
    /* JWConfig can be created with a single file reference */
    JWConfig *config = [JWConfig configWithContentURL:@"http://content.bitsontherun.com/videos/3XnJSIm4-injeKYZS.mp4"];
//    JWConfig *config = [JWConfig configWithContentURL:@"http://fish.schou.me/"];
    
    
    config.title = @"JWPlayer Demo";
    config.controls = YES;  //default
    config.repeat = NO;   //default
    config.premiumSkin = JWPremiumSkinRoundster;
    
    self.player = [[JWPlayerController alloc] initWithConfig:config];
    
    CGRect frame = self.view.bounds;
    frame.origin.y = 64;
    frame.size.height /= 2;
    frame.size.height -= 44 + 64;
    self.player.view.frame = frame;
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
    
    config.tracks = @[[JWTrack trackWithFile:@"http://playertest.longtailvideo.com/caption-files/sintel-en.srt" label:@"English" isDefault:YES],
                      [JWTrack trackWithFile:@"http://playertest.longtailvideo.com/caption-files/sintel-sp.srt" label:@"Spanish"],
                      [JWTrack trackWithFile:@"http://playertest.longtailvideo.com/caption-files/sintel-ru.srt" label:@"Russian"]];
    
    
    //MARK: JWCaptionStyling
    JWCaptionStyling* captionStyling = [JWCaptionStyling new];
    captionStyling.font = [UIFont fontWithName:@"Zapfino" size:20];
    captionStyling.edgeStyle = raised;
    captionStyling.windowColor = [UIColor orangeColor];
    captionStyling.backgroundColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.3 alpha:0.7];
    captionStyling.fontColor = [UIColor blueColor];
    config.captionStyling = captionStyling;
    
    JWAdConfig *adConfig = [JWAdConfig new];
    adConfig.adMessage = @"Ad duration countdown xx";
    adConfig.skipMessage = @"Skip in xx";
    adConfig.skipText = @"Move on";
    adConfig.skipOffset = 3;
    adConfig.adClient = vastPlugin;
    config.adConfig = adConfig;
    
    //MARK: JWAdBreak
    config.adSchedule = @[[JWAdBreak adBreakWithTag:@"http://demo.tremorvideo.com/proddev/vast/vast_inline_nonlinear.xml" offset:@"pre"],                             [JWAdBreak adBreakWithTag:@"http://playertest.longtailvideo.com/adtags/preroll_newer.xml" offset:@"50%"],
                          [JWAdBreak adBreakWithTag:@"http://playertest.longtailvideo.com/adtags/preroll_newer.xml" offset:@"post"]];
    
    
    self.player.openSafariOnAdClick = YES;
    self.player.forceFullScreenOnLandscape = YES;
    self.player.forceLandscapeOnFullScreen = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
