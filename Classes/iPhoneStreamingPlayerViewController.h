//
//  iPhoneStreamingPlayerViewController.h
//  iSub
//
//  Created by Ben Baron on 2/27/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iSubAppDelegate, MusicControlsSingleton, DatabaseControlsSingleton, ViewObjectsSingleton, CoverArtImageView, MPVolumeView;

@interface iPhoneStreamingPlayerViewController : UIViewController
{
	IBOutlet UIButton *playButton;
	IBOutlet UIButton *nextButton;
	IBOutlet UIButton *prevButton;
	IBOutlet UIView *volumeSlider;
	MPVolumeView *volumeView;
	UISlider *jukeboxVolumeView;
	IBOutlet CoverArtImageView *coverArtImageView;
	IBOutlet UIImageView *reflectionView;
	IBOutlet UIButton *songInfoToggleButton;
	
	UILabel *artistLabel;
	UILabel *albumLabel;
	UILabel *titleLabel;
	
	iSubAppDelegate *appDelegate;
	MusicControlsSingleton *musicControls;
	DatabaseControlsSingleton *databaseControls;
	ViewObjectsSingleton *viewObjects;
	
	NSUInteger reflectionHeight;
	
	BOOL isFlipped;
	
	UIView *flipButtonView;
}

@property (nonatomic, retain) NSArray *listOfSongs;

- (void)setPlayButtonImage;
- (void)setPauseButtonImage;
- (IBAction)songInfoToggle:(id)sender;
- (IBAction)playButtonPressed:(id)sender;
- (IBAction)prevButtonPressed:(id)sender;
- (IBAction)nextButtonPressed:(id)sender;

- (void)setSongTitle;

@end

