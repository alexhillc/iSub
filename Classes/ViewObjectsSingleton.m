//
//  ViewObjectsSingleton.m
//  iSub
//
//  Created by Ben Baron on 10/15/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import "ViewObjectsSingleton.h"
#import "Imports.h"

@implementation ViewObjectsSingleton

#pragma mark -
#pragma mark Class instance methods


- (void)enableCells
{
	self.isCellEnabled = YES;
}

- (void)hudWasHidden:(MBProgressHUD *)hud 
{
    // Remove HUD from screen when the HUD was hidden
    [self.HUD removeFromSuperview];
	self.HUD = nil;
}

static NSString * const kViewKey = @"view";
static NSString * const kMessageKey = @"message";
static NSString * const kSenderKey = @"sender";
static NSTimeInterval const kDelay = .5;

- (void)showLoadingScreenOnMainWindowNotification:(NSNotification *)notification
{
    [self showLoadingScreenOnMainWindowWithMessage:notification.userInfo[@"message"]];
}

- (void)showLoadingScreenOnMainWindowWithMessage:(NSString *)message
{	
	[self showLoadingScreen:appDelegateS.window withMessage:message];
}

- (void)showLoadingScreen:(UIView *)view withMessage:(NSString *)message
{
    if (self.isLoadingScreenShowing)
    {
        self.HUD.labelText = message ? message : self.HUD.labelText;
        return;
    }
    
    NSDictionary *options = @{ kViewKey: view, kMessageKey: n2N(message) };
    [self performSelector:@selector(_showLoadingScreenWithOptions:) withObject:options afterDelay:kDelay];
}

- (void)_showLoadingScreenWithOptions:(NSDictionary *)options
{
    UIView *view = options[kViewKey];
    NSString *message = N2n(options[kMessageKey]);
    
    self.isLoadingScreenShowing = YES;
    
    self.HUD = [[MBProgressHUD alloc] initWithView:view];
    [appDelegateS.window addSubview:self.HUD];
    self.HUD.delegate = self;
    self.HUD.labelText = message ? message : @"Loading";
    [self.HUD show:YES];
}

- (void)showAlbumLoadingScreenOnMainWindowNotification:(NSNotification *)notification
{
    [self showAlbumLoadingScreenOnMainWindowWithSender:notification.userInfo[@"sender"]];
}

- (void)showAlbumLoadingScreenOnMainWindowWithSender:(id)sender
{
    [self showAlbumLoadingScreen:appDelegateS.window sender:sender];
}

- (void)showAlbumLoadingScreen:(UIView *)view sender:(id)sender
{	
	if (self.isLoadingScreenShowing)
		return;
    
    NSDictionary *options = @{ kViewKey: view, kSenderKey: sender };
    [self performSelector:@selector(_showAlbumLoadingScreenWithOptions:) withObject:options afterDelay:kDelay];
}

- (void)_showAlbumLoadingScreenWithOptions:(NSDictionary *)options
{
    //UIView *view = options[kViewKey];
    id sender = options[kSenderKey];
    
    self.isLoadingScreenShowing = YES;
    
    // TODO: See why was always using window here
    self.HUD = [[MBProgressHUD alloc] initWithView:appDelegateS.window];
    self.HUD.userInteractionEnabled = YES;
    
    // TODO: verify on iPad
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.bounds = CGRectMake(0, 0, 1024, 1024);
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [cancelButton addTarget:sender action:@selector(cancelLoad) forControlEvents:UIControlEventTouchUpInside];
    [self.HUD addSubview:cancelButton];
    
    [appDelegateS.window addSubview:self.HUD];
    self.HUD.delegate = self;
    self.HUD.labelText = @"Loading";
    self.HUD.detailsLabelText = @"tap to cancel";
    [self.HUD show:YES];
}
	
- (void)hideLoadingScreen
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
	if (!self.isLoadingScreenShowing)
		return;
	
	self.isLoadingScreenShowing = NO;
	
	[self.HUD hide:YES];
}

- (UIColor *)currentDarkColor
{
	//switch ([[appDelegateS.settingsDictionary objectForKey:@"cacheSongCellColorSetting"] intValue])
	switch(settingsS.cachedSongCellColorType)
	{
		case 0:
			return self.darkRed;
		case 1:
			return self.darkYellow;
		case 2:
			return self.darkGreen;
		case 3:
			return self.darkBlue;
		default:
			return self.darkNormal;
	}
	
	return self.darkNormal;
}

- (UIColor *) currentLightColor
{
	//switch ([[appDelegateS.settingsDictionary objectForKey:@"cacheSongCellColorSetting"] intValue])
	switch(settingsS.cachedSongCellColorType)
	{
		case 0:
			return self.lightRed;
		case 1:
			return self.lightYellow;
		case 2:
			return self.lightGreen;
		case 3:
			return self.lightBlue;
		default:
			return self.lightNormal;
	}
	
	return self.lightNormal;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
//DLog(@"received memory warning");
}

#pragma mark - Singleton methods

- (void)setup
{
	_lightRed = [UIColor colorWithRed:255/255.0 green:146/255.0 blue:115/255.0 alpha:1];
	_darkRed = [UIColor colorWithRed:226/255.0 green:0/255.0 blue:0/255.0 alpha:1];
	
	_lightYellow = [UIColor colorWithRed:255/255.0 green:233/255.0 blue:115/255.0 alpha:1];
	_darkYellow = [UIColor colorWithRed:255/255.0 green:215/255.0 blue:0/255.0 alpha:1];
	
	_lightGreen = [UIColor colorWithRed:169/255.0 green:241/255.0 blue:108/255.0 alpha:1];
	_darkGreen = [UIColor colorWithRed:103/255.0 green:227/255.0 blue:0/255.0 alpha:1];
	
	_lightBlue = [UIColor colorWithRed:87/255.0 green:198/255.0 blue:255/255.0 alpha:1];
	_darkBlue = [UIColor colorWithRed:28/255.0 green:163/255.0 blue:255/255.0 alpha:1];
	
	_lightNormal = [UIColor whiteColor];
	_darkNormal = ISMSHeaderColor;

	_windowColor = [UIColor colorWithWhite:.3 alpha:1];
	_jukeboxColor = [UIColor colorWithRed:140.0/255.0 green:0.0 blue:0.0 alpha:1.0];
	
	_isCellEnabled = YES;
	
	[NSNotificationCenter addObserverOnMainThread:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [NSNotificationCenter addObserverOnMainThread:self selector:@selector(showAlbumLoadingScreenOnMainWindowNotification:) name:ISMSNotification_ShowAlbumLoadingScreenOnMainWindow object:nil];
    [NSNotificationCenter addObserverOnMainThread:self selector:@selector(showLoadingScreenOnMainWindowNotification:) name:ISMSNotification_ShowLoadingScreenOnMainWindow object:nil];
    [NSNotificationCenter addObserverOnMainThread:self selector:@selector(hideLoadingScreen) name:ISMSNotification_HideLoadingScreen object:nil];
}

+ (instancetype)sharedInstance
{
    static ViewObjectsSingleton *sharedInstance = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
		[sharedInstance setup];
	});
    return sharedInstance;
}

@end
