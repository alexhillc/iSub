//
//  HomeAlbumViewController.h
//  iSub
//
//  Created by Ben Baron on 2/28/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

@class iSubAppDelegate, ViewObjectsSingleton, MusicControlsSingleton, DatabaseControlsSingleton, Artist, Album;

@interface HomeAlbumViewController : UITableViewController 
{
	iSubAppDelegate *appDelegate;
	ViewObjectsSingleton *viewObjects;
	MusicControlsSingleton *musicControls;
	DatabaseControlsSingleton *databaseControls;
		
	NSMutableArray *listOfAlbums;
	
	NSString *searchModifier;
	NSUInteger offset;
	BOOL isMoreAlbums;
	BOOL isLoading;
}

@property (nonatomic, retain) NSMutableArray *listOfAlbums;

@property (nonatomic, retain) NSString *modifier;
@property NSUInteger offset;
@property BOOL isMoreAlbums;

@end
