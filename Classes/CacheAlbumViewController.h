//
//  CacheAlbumsViewController.h
//  iSub
//
//  Created by Ben Baron on 6/16/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iSubAppDelegate, ViewObjectsSingleton, MusicControlsSingleton, DatabaseControlsSingleton;

@interface CacheAlbumViewController : UITableViewController 
{
	iSubAppDelegate *appDelegate;
	ViewObjectsSingleton *viewObjects;
	MusicControlsSingleton *musicControls;
	DatabaseControlsSingleton *databaseControls;
	
	NSMutableArray *listOfAlbums;
	NSMutableArray *listOfSongs;
	
	NSArray *sectionInfo;
	
	NSInteger segment;
	NSString *seg1;
}

@property (nonatomic, retain) NSMutableArray *listOfAlbums;
@property (nonatomic, retain) NSMutableArray *listOfSongs;

@property (nonatomic, retain) NSArray *sectionInfo;


@property NSInteger segment;
@property (nonatomic, retain) NSString *seg1;

@end
