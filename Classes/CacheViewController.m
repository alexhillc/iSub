//
//  CacheViewController.m
//  iSub
//
//  Created by Ben Baron on 6/1/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import "CacheViewController.h"
#import "CacheAlbumViewController.h"
#import "Song.h"
#import "NSString-md5.h"
#import "iSubAppDelegate.h"
#import "ViewObjectsSingleton.h"
#import "MusicControlsSingleton.h"
#import "DatabaseControlsSingleton.h"
#import "CacheQueueSongUITableViewCell.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "AsynchronousImageViewCached.h"
#import "ServerListViewController.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "Reachability.h"
#import "CacheArtistUITableViewCell.h"
#import "StoreViewController.h"
#import "CustomUIAlertView.h"

@implementation CacheViewController

@synthesize listOfArtists, listOfArtistsSections, sectionInfo;

//@synthesize queueDownloadProgressView;

#pragma mark -
#pragma mark View lifecycle

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inOrientation 
{
	if ([[[iSubAppDelegate sharedInstance].settingsDictionary objectForKey:@"lockRotationSetting"] isEqualToString:@"YES"] 
		&& inOrientation != UIInterfaceOrientationPortrait)
		return NO;
	
    return YES;
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	//NSLog(@"Cache viewDidLoad");
	
	appDelegate = (iSubAppDelegate *)[[UIApplication sharedApplication] delegate];
	viewObjects = [ViewObjectsSingleton sharedInstance];
	musicControls = [MusicControlsSingleton sharedInstance];
	databaseControls = [DatabaseControlsSingleton sharedInstance];
	
	jukeboxInputBlocker = nil;
	
	viewObjects.multiDeleteList = [NSMutableArray arrayWithCapacity:1];
	//viewObjects.multiDeleteList = nil; viewObjects.multiDeleteList = [[NSMutableArray alloc] init];
	isNoSongsScreenShowing = NO;
	isSaveEditShowing = NO;
	
	firstLoad = YES;
	
	self.tableView.separatorColor = [UIColor clearColor];
	
	if (viewObjects.isOfflineMode)
	{
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] 
																				  style:UIBarButtonItemStyleBordered 
																				 target:self 
																				 action:@selector(settingsAction:)] autorelease];
	}
	
	headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
	headerView.backgroundColor = [UIColor colorWithWhite:.3 alpha:1];
	segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Cached", @"Queue", nil]];
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.frame = CGRectMake(5, 5, 310, 36);
	segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	segmentedControl.tintColor = [UIColor colorWithWhite:.57 alpha:1];
	segmentedControl.selectedSegmentIndex = 0;
	if (viewObjects.isOfflineMode) 
	{
		segmentedControl.hidden = YES;
	}
	[headerView addSubview:segmentedControl];
	
	if (viewObjects.isOfflineMode) 
	{
		headerView.frame = CGRectMake(0, 0, 320, 50);
		
		headerView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
		headerView2.backgroundColor = viewObjects.darkNormal;
		[headerView addSubview:headerView2];
		[headerView2 release];
		
		playAllImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play-all-note.png"]];
		playAllImage.frame = CGRectMake(10, 10, 19, 30);
		[headerView2 addSubview:playAllImage];
		[playAllImage release];
		
		playAllLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 160, 50)];
		playAllLabel.backgroundColor = [UIColor clearColor];
		playAllLabel.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
		playAllLabel.textAlignment = UITextAlignmentCenter;
		playAllLabel.font = [UIFont boldSystemFontOfSize:30];
		playAllLabel.text = @"Play All";
		[headerView2 addSubview:playAllLabel];
		[playAllLabel release];
		
		playAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
		playAllButton.frame = CGRectMake(0, 0, 160, 40);
		[playAllButton addTarget:self action:@selector(playAllAction:) forControlEvents:UIControlEventTouchUpInside];
		[headerView2 addSubview:playAllButton];
		
		spacerLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(158, -2, 6, 50)];
		spacerLabel2.backgroundColor = [UIColor clearColor];
		spacerLabel2.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
		spacerLabel2.font = [UIFont systemFontOfSize:40];
		spacerLabel2.text = @"|";
		[headerView2 addSubview:spacerLabel2];
		[spacerLabel2 release];
		
		shuffleImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shuffle-small.png"]];
		shuffleImage.frame = CGRectMake(180, 12, 24, 26);
		[headerView2 addSubview:shuffleImage];
		[shuffleImage release];
		
		shuffleLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 0, 160, 50)];
		shuffleLabel.backgroundColor = [UIColor clearColor];
		shuffleLabel.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
		shuffleLabel.textAlignment = UITextAlignmentCenter;
		shuffleLabel.font = [UIFont boldSystemFontOfSize:30];
		shuffleLabel.text = @"Shuffle";
		[headerView2 addSubview:shuffleLabel];
		[shuffleLabel release];
		
		shuffleButton = [UIButton buttonWithType:UIButtonTypeCustom];
		shuffleButton.frame = CGRectMake(160, 0, 160, 40);
		[shuffleButton addTarget:self action:@selector(shuffleAction:) forControlEvents:UIControlEventTouchUpInside];
		[headerView2 addSubview:shuffleButton];
		
		// Add the top fade
		UIImageView *fadeTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-fade-top.png"]];
		fadeTop.frame =CGRectMake(0, -10, self.tableView.bounds.size.width, 10);
		fadeTop.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.tableView addSubview:fadeTop];
		[fadeTop release];
	}
	
	self.tableView.tableHeaderView = headerView;
	
	
	/*// Setup segmented control in the header view
	UIView *spacerView;
	if (viewObjects.isOfflineMode) 
	{
		spacerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)] autorelease];
		headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)] autorelease];
	}
	else
	{
		if (IS_IPAD())
		{
			spacerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 48)] autorelease];
			headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 48)] autorelease];
		}
		else
		{
			spacerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)] autorelease];
			headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)] autorelease];
		}
	}
	spacerView.backgroundColor = [UIColor clearColor];
	headerView.backgroundColor = [UIColor colorWithWhite:.3 alpha:1];
	segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Cached", @"Queue", nil]];
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	if (IS_IPAD())
	{
		segmentedControl.segmentedControlStyle = UISegmentedControlStyleBezeled;
		segmentedControl.frame = CGRectMake(5, 4, 310, 40);
	}
	else 
	{
		segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		segmentedControl.frame = CGRectMake(5, 2, 310, 36);
	}
	segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	segmentedControl.tintColor = [UIColor colorWithWhite:.57 alpha:1];
	segmentedControl.selectedSegmentIndex = 0;
	if (viewObjects.isOfflineMode) 
	{
		segmentedControl.hidden = YES;
	}
	[headerView addSubview:segmentedControl];
	self.tableView.tableHeaderView = spacerView;
	[self.tableView.superview addSubview:headerView];*/
	
	UIImageView *fadeBottom = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-fade-bottom.png"]] autorelease];
	fadeBottom.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 10);
	fadeBottom.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.tableView.tableFooterView = fadeBottom;
	
	if (viewObjects.isOfflineMode)
	{
		self.title = @"Artists";
	}
	else 
	{
		self.title = @"Cache";
		
		// Setup the update timer
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:.25 target:self selector:@selector(updateQueueDownloadProgress) userInfo:nil repeats:YES];
		
		// Set notification receiver for when queued songs finish downloading to reload the table
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(segmentAction:) name:@"queuedSongDone" object:nil];
		
		// Set notification receiver for when cached songs are deleted to reload the table
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(segmentAction:) name:@"cachedSongDeleted" object:nil];
		
		// Set notification receiver for when network status changes to reload the table
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(segmentAction:) name:kReachabilityChangedNotification object: nil];
	}
}

- (void) updateQueueDownloadProgress
{
	//if (queueDownloadProgressView != nil && appDelegate.isQueueListDownloading)
	if (musicControls.isQueueListDownloading)
	{
		NSString *songMD5 = [NSString md5:musicControls.queueSongObject.path];
		
		NSString *fileName;
		if (musicControls.queueSongObject.transcodedSuffix)
			fileName = [musicControls.audioFolderPath stringByAppendingString:[NSString stringWithFormat:@"/%@.%@", songMD5, musicControls.queueSongObject.transcodedSuffix]];
		else
			fileName = [musicControls.audioFolderPath stringByAppendingString:[NSString stringWithFormat:@"/%@.%@", songMD5, musicControls.queueSongObject.suffix]];
		
		queueDownloadProgress = (unsigned long long int)[[[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:NULL] fileSize];
		
		// Reload the cells
		if (segmentedControl.selectedSegmentIndex == 1)
		{
			[self.tableView reloadData];
		}
	}
}


- (Song *) songFromDbRow:(NSUInteger)row inTable:(NSString *)table
{
	row++;
	Song *aSong = [[Song alloc] init];
	FMResultSet *result = [databaseControls.songCacheDb executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE ROWID = %i", table, row]];
	[result next];
	if ([databaseControls.songCacheDb hadError]) {
		NSLog(@"Err %d: %@", [databaseControls.songCacheDb lastErrorCode], [databaseControls.songCacheDb lastErrorMessage]);
	}
	
	aSong.title = [result stringForColumnIndex:4];
	aSong.songId = [result stringForColumnIndex:5];
	aSong.artist = [result stringForColumnIndex:6];
	aSong.album = [result stringForColumnIndex:7];
	aSong.genre = [result stringForColumnIndex:8];
	aSong.coverArtId = [result stringForColumnIndex:9];
	aSong.path = [result stringForColumnIndex:10];
	aSong.suffix = [result stringForColumnIndex:11];
	aSong.transcodedSuffix = [result stringForColumnIndex:12];
	aSong.duration = [NSNumber numberWithInt:[result intForColumnIndex:13]];
	aSong.bitRate = [NSNumber numberWithInt:[result intForColumnIndex:14]];
	aSong.track = [NSNumber numberWithInt:[result intForColumnIndex:15]];
	aSong.year = [NSNumber numberWithInt:[result intForColumnIndex:16]];
	aSong.size = [NSNumber numberWithInt:[result intForColumnIndex:17]];
	
	[result close];
	return [aSong autorelease];
}


- (void)createCachedSongsList
{
	// Create the cachedSongsList table
	[databaseControls.songCacheDb executeUpdate:@"DROP TABLE cachedSongsList"];
	[databaseControls.songCacheDb executeUpdate:@"CREATE TABLE cachedSongsList (md5 TEXT UNIQUE, finished TEXT, cachedDate INTEGER, playedDate INTEGER, title TEXT, songId TEXT, artist TEXT, album TEXT, genre TEXT, coverArtId TEXT, path TEXT, suffix TEXT, transcodedSuffix TEXT, duration INTEGER, bitRate INTEGER, track INTEGER, year INTEGER, size INTEGER)"];
	[databaseControls.songCacheDb executeUpdate:@"INSERT INTO cachedSongsList SELECT * FROM cachedSongs WHERE finished = 'YES' ORDER BY playedDate DESC"];	
}

- (void)createQueuedSongsList
{
	// Create the queuedSongsList table
	[databaseControls.cacheQueueDb executeUpdate:@"DROP TABLE queuedSongsList"];
	[databaseControls.cacheQueueDb executeUpdate:@"CREATE TABLE queuedSongsList (md5 TEXT UNIQUE, finished TEXT, cachedDate INTEGER, playedDate INTEGER, title TEXT, songId TEXT, artist TEXT, album TEXT, genre TEXT, coverArtId TEXT, path TEXT, suffix TEXT, transcodedSuffix TEXT, duration INTEGER, bitRate INTEGER, track INTEGER, year INTEGER, size INTEGER)"];
	[databaseControls.cacheQueueDb executeUpdate:@"INSERT INTO queuedSongsList SELECT * FROM cacheQueue ORDER BY cachedDate ASC"];
}

- (void)removeSaveEditButtons
{
	if (isSaveEditShowing == YES)
	{
		isSaveEditShowing = NO;
		[songsCountLabel removeFromSuperview];
		[deleteSongsButton removeFromSuperview];
		[spacerLabel removeFromSuperview];
		[editSongsLabel removeFromSuperview];
		[editSongsButton removeFromSuperview];
		[deleteSongsLabel removeFromSuperview];
		[cacheSizeLabel removeFromSuperview];
		[headerView2 removeFromSuperview];
		
		/*[playAllImage removeFromSuperview];
		[playAllLabel removeFromSuperview];
		[playAllButton removeFromSuperview];
		[spacerLabel2 removeFromSuperview];
		[shuffleImage removeFromSuperview];
		[shuffleLabel removeFromSuperview];
		[shuffleButton removeFromSuperview];*/
		headerView.frame = CGRectMake(0, 0, 320, 44);
		
		self.tableView.tableHeaderView = headerView;
	}
}

- (void)addSaveEditButtons
{
	[self removeSaveEditButtons];
	
	if (isSaveEditShowing == NO)
	{
		// Modify the header view to include the save and edit buttons
		isSaveEditShowing = YES;
		int y = 45;
		
		headerView.frame = CGRectMake(0, 0, 320, y + 100);
		if (segmentedControl.selectedSegmentIndex == 1)
			headerView.frame = CGRectMake(0, 0, 320, y + 50);
		
		songsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 227, 34)];
		songsCountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
		songsCountLabel.backgroundColor = [UIColor clearColor];
		songsCountLabel.textColor = [UIColor whiteColor];
		songsCountLabel.textAlignment = UITextAlignmentCenter;
		songsCountLabel.font = [UIFont boldSystemFontOfSize:22];
		if (segmentedControl.selectedSegmentIndex == 0)
		{
			if ([databaseControls.songCacheDb intForQuery:@"SELECT COUNT(*) FROM cachedSongs WHERE finished = 'YES' AND md5 != ''"] == 1)
				songsCountLabel.text = [NSString stringWithFormat:@"1 Song"];
			else 
				songsCountLabel.text = [NSString stringWithFormat:@"%i Songs", [databaseControls.songCacheDb intForQuery:@"SELECT COUNT(*) FROM cachedSongs WHERE finished = 'YES' AND md5 != ''"]];
		}
		else if (segmentedControl.selectedSegmentIndex == 1)
		{
			if ([databaseControls.songCacheDb intForQuery:@"SELECT COUNT(*) FROM cacheQueue"] == 1)
				songsCountLabel.text = [NSString stringWithFormat:@"1 Song"];
			else 
				songsCountLabel.text = [NSString stringWithFormat:@"%i Songs", [databaseControls.songCacheDb intForQuery:@"SELECT COUNT(*) FROM cacheQueue"]];
		}
		[headerView addSubview:songsCountLabel];
		[songsCountLabel release];
		
		cacheSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y + 33, 227, 14)];
		cacheSizeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
		cacheSizeLabel.backgroundColor = [UIColor clearColor];
		cacheSizeLabel.textColor = [UIColor whiteColor];
		cacheSizeLabel.textAlignment = UITextAlignmentCenter;
		cacheSizeLabel.font = [UIFont boldSystemFontOfSize:12];
		if (segmentedControl.selectedSegmentIndex == 0)
		{
			/*unsigned long long combinedSize = 0;
			for (NSString *path in [[NSFileManager defaultManager] subpathsAtPath:musicControls.audioFolderPath]) 
			{
				combinedSize += [[[NSFileManager defaultManager] attributesOfItemAtPath:[musicControls.audioFolderPath stringByAppendingPathComponent:path] error:NULL] fileSize];
			}
			cacheSizeLabel.text = [appDelegate formatFileSize:combinedSize];*/
			unsigned long long combinedSize = 0;
			FMResultSet *result = [databaseControls.songCacheDb executeQuery:@"SELECT size FROM cachedSongs"];
			while ([result next])
			{
				combinedSize += [result longLongIntForColumnIndex:0];
			}
			cacheSizeLabel.text = [appDelegate formatFileSize:combinedSize];
		}
		else if (segmentedControl.selectedSegmentIndex == 1)
		{
			unsigned long long combinedSize = 0;
			FMResultSet *result = [databaseControls.songCacheDb executeQuery:@"SELECT size FROM cacheQueue"];
			while ([result next])
			{
				combinedSize += [result longLongIntForColumnIndex:0];
			}
			cacheSizeLabel.text = [appDelegate formatFileSize:combinedSize];
		}
		[headerView addSubview:cacheSizeLabel];
		[cacheSizeLabel release];
		
		deleteSongsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		deleteSongsButton.frame = CGRectMake(0, y, 230, 50);
		deleteSongsButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
		[deleteSongsButton addTarget:self action:@selector(deleteSongsAction:) forControlEvents:UIControlEventTouchUpInside];
		[headerView addSubview:deleteSongsButton];
		
		spacerLabel = [[UILabel alloc] initWithFrame:CGRectMake(226, y - 2, 6, 50)];
		spacerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		spacerLabel.backgroundColor = [UIColor clearColor];
		spacerLabel.textColor = [UIColor whiteColor];
		spacerLabel.font = [UIFont systemFontOfSize:40];
		spacerLabel.text = @"|";
		[headerView addSubview:spacerLabel];
		[spacerLabel release];	
		
		editSongsLabel = [[UILabel alloc] initWithFrame:CGRectMake(234, y, 86, 50)];
		editSongsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
		editSongsLabel.backgroundColor = [UIColor clearColor];
		editSongsLabel.textColor = [UIColor whiteColor];
		editSongsLabel.textAlignment = UITextAlignmentCenter;
		editSongsLabel.font = [UIFont boldSystemFontOfSize:22];
		editSongsLabel.text = @"Edit";
		[headerView addSubview:editSongsLabel];
		[editSongsLabel release];
		
		editSongsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		editSongsButton.frame = CGRectMake(234, y, 86, 40);
		editSongsButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
		[editSongsButton addTarget:self action:@selector(editSongsAction:) forControlEvents:UIControlEventTouchUpInside];
		[headerView addSubview:editSongsButton];	
		
		deleteSongsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 227, 50)];
		deleteSongsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
		deleteSongsLabel.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:.5];
		deleteSongsLabel.textColor = [UIColor whiteColor];
		deleteSongsLabel.textAlignment = UITextAlignmentCenter;
		deleteSongsLabel.font = [UIFont boldSystemFontOfSize:22];
		deleteSongsLabel.adjustsFontSizeToFitWidth = YES;
		deleteSongsLabel.minimumFontSize = 12;
		deleteSongsLabel.text = @"Delete # Songs";
		deleteSongsLabel.hidden = YES;
		[headerView addSubview:deleteSongsLabel];
		[deleteSongsLabel release];
		
		headerView2 = nil;
		if (segmentedControl.selectedSegmentIndex == 0)
		{
			headerView2 = [[UIView alloc] initWithFrame:CGRectMake(0, y + 50, 320, 50)];
			headerView2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			headerView2.backgroundColor = viewObjects.darkNormal;
			[headerView addSubview:headerView2];
			[headerView2 release];
			
			playAllImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play-all-note.png"]];
			playAllImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			playAllImage.frame = CGRectMake(10, 10, 19, 30);
			[headerView2 addSubview:playAllImage];
			[playAllImage release];
			
			playAllLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 160, 50)];
			playAllLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
			playAllLabel.backgroundColor = [UIColor clearColor];
			playAllLabel.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
			playAllLabel.textAlignment = UITextAlignmentCenter;
			playAllLabel.font = [UIFont boldSystemFontOfSize:30];
			playAllLabel.text = @"Play All";
			[headerView2 addSubview:playAllLabel];
			[playAllLabel release];
			
			playAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
			playAllButton.frame = CGRectMake(0, 0, 160, 40);
			playAllButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
			[playAllButton addTarget:self action:@selector(playAllAction:) forControlEvents:UIControlEventTouchUpInside];
			[headerView2 addSubview:playAllButton];
			
			spacerLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(158, -2, 6, 50)];
			spacerLabel2.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			spacerLabel2.backgroundColor = [UIColor clearColor];
			spacerLabel2.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
			spacerLabel2.font = [UIFont systemFontOfSize:40];
			spacerLabel2.text = @"|";
			[headerView2 addSubview:spacerLabel2];
			[spacerLabel2 release];
			
			shuffleImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shuffle-small.png"]];
			shuffleImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			shuffleImage.frame = CGRectMake(180, 12, 24, 26);
			[headerView2 addSubview:shuffleImage];
			[shuffleImage release];
			
			shuffleLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 0, 160, 50)];
			shuffleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
			shuffleLabel.backgroundColor = [UIColor clearColor];
			shuffleLabel.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
			shuffleLabel.textAlignment = UITextAlignmentCenter;
			shuffleLabel.font = [UIFont boldSystemFontOfSize:30];
			shuffleLabel.text = @"Shuffle";
			[headerView2 addSubview:shuffleLabel];
			[shuffleLabel release];
			
			shuffleButton = [UIButton buttonWithType:UIButtonTypeCustom];
			shuffleButton.frame = CGRectMake(160, 0, 160, 40);
			shuffleButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
			[shuffleButton addTarget:self action:@selector(shuffleAction:) forControlEvents:UIControlEventTouchUpInside];
			[headerView2 addSubview:shuffleButton];
		}
		
		self.tableView.tableHeaderView = headerView;
	}
}

- (void)removeNoSongsScreen
{
	if (isNoSongsScreenShowing == YES)
	{
		[noSongsScreen removeFromSuperview];
		isNoSongsScreenShowing = NO;
	}
}

- (void)addNoSongsScreen
{
	[self removeNoSongsScreen];
	
	if (isNoSongsScreenShowing == NO)
	{
		isNoSongsScreenShowing = YES;
		noSongsScreen = [[UIImageView alloc] init];
		noSongsScreen.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
		noSongsScreen.frame = CGRectMake(40, 100, 240, 180);
		noSongsScreen.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
		noSongsScreen.image = [UIImage imageNamed:@"loading-screen-image.png"];
		noSongsScreen.alpha = .80;
		noSongsScreen.userInteractionEnabled = YES;
		
		UILabel *textLabel = [[UILabel alloc] init];
		textLabel.backgroundColor = [UIColor clearColor];
		textLabel.textColor = [UIColor whiteColor];
		textLabel.font = [UIFont boldSystemFontOfSize:32];
		textLabel.textAlignment = UITextAlignmentCenter;
		textLabel.numberOfLines = 0;
		if (viewObjects.isCacheUnlocked)
		{
			if (segmentedControl.selectedSegmentIndex == 0)
				[textLabel setText:@"No Cached\nSongs"];
			else if (segmentedControl.selectedSegmentIndex == 1)
				[textLabel setText:@"No Queued\nSongs"];
			
			textLabel.frame = CGRectMake(20, 20, 200, 140);
		}
		else
		{
			textLabel.text = @"Caching\nLocked";
			textLabel.frame = CGRectMake(20, 0, 200, 100);
		}
		[noSongsScreen addSubview:textLabel];
		[textLabel release];
		
		if (viewObjects.isCacheUnlocked == NO)
		{
			UILabel *textLabel2 = [[UILabel alloc] init];
			textLabel2.backgroundColor = [UIColor clearColor];
			textLabel2.textColor = [UIColor whiteColor];
			textLabel2.font = [UIFont boldSystemFontOfSize:14];
			textLabel2.textAlignment = UITextAlignmentCenter;
			textLabel2.numberOfLines = 0;
			textLabel2.text = @"Tap to purchase the ability to cache songs for better streaming performance and offline playback";
			textLabel2.frame = CGRectMake(20, 90, 200, 70);
			[noSongsScreen addSubview:textLabel2];
			[textLabel2 release];
			
			UIButton *storeLauncher = [UIButton buttonWithType:UIButtonTypeCustom];
			storeLauncher.frame = CGRectMake(0, 0, noSongsScreen.frame.size.width, noSongsScreen.frame.size.height);
			[storeLauncher addTarget:self action:@selector(showStore) forControlEvents:UIControlEventTouchUpInside];
			[noSongsScreen addSubview:storeLauncher];
		}
		
		[self.view addSubview:noSongsScreen];
		
		[noSongsScreen release];
	}
}

- (void)showStore
{
	StoreViewController *store = [[StoreViewController alloc] init];
	[self.navigationController pushViewController:store animated:YES];
	[store release];
}

- (void)segmentAction:(id)sender
{
	if (segmentedControl.selectedSegmentIndex == 0)
	{
		if (self.tableView.editing)
		{
			[self editSongsAction:nil];
		}
		
		// Create the artist list
		self.listOfArtists = [NSMutableArray arrayWithCapacity:1];
		self.listOfArtistsSections = [NSMutableArray arrayWithCapacity:28];
		
		// Fix for slow load problem (EDIT: Looks like it didn't actually work :(
		[databaseControls.inMemoryDb executeUpdate:@"DROP TABLE cachedSongsArtistList"];
		[databaseControls.inMemoryDb executeUpdate:@"CREATE TABLE cachedSongsArtistList (artist TEXT UNIQUE)"];
		[databaseControls.inMemoryDb executeUpdate:@"ATTACH DATABASE ? AS songCacheDb", [NSString stringWithFormat:@"%@/songCache.db", databaseControls.databaseFolderPath]];
		if ([databaseControls.inMemoryDb hadError]) { NSLog(@"Err attaching the songCacheDb %d: %@", [databaseControls.inMemoryDb lastErrorCode], [databaseControls.inMemoryDb lastErrorMessage]); }
		[databaseControls.inMemoryDb executeUpdate:@"INSERT OR IGNORE INTO cachedSongsArtistList SELECT seg1 FROM cachedSongsLayout"];
		[databaseControls.inMemoryDb executeUpdate:@"DETACH DATABASE songCacheDb"];
		
		//FMResultSet *result = [databaseControls.songCacheDb executeQuery:@"SELECT seg1 FROM cachedSongsLayout GROUP BY seg1 ORDER BY seg1 COLLATE NOCASE"];
		FMResultSet *result = [databaseControls.inMemoryDb executeQuery:@"SELECT artist FROM cachedSongsArtistList ORDER BY artist COLLATE NOCASE"];
		while ([result next])
		{
			//
			// Cover up for blank insert problem
			//
			if ([[result stringForColumnIndex:0] length] > 0)
				[listOfArtists addObject:[result stringForColumnIndex:0]]; 
		}

		// Sort out The El La Los Las Le Les (Subsonic default)
		for (int i = 0; i < [listOfArtists count]; i++)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSString *artist = [listOfArtists objectAtIndex:i];
			if ([artist length] > 5)
			{
				if ([[[artist substringToIndex:4] lowercaseString] isEqualToString:@"the "])
				{
					artist = [NSString stringWithFormat:@"%@, The", [artist substringFromIndex:4]];
				}
				else if ([[[artist substringToIndex:4] lowercaseString] isEqualToString:@"los "])
				{
					artist = [NSString stringWithFormat:@"%@, Los", [artist substringFromIndex:4]];
				}
				else if ([[[artist substringToIndex:4] lowercaseString] isEqualToString:@"las "])
				{
					artist = [NSString stringWithFormat:@"%@, Las", [artist substringFromIndex:4]];
				}
				else if ([[[artist substringToIndex:4] lowercaseString] isEqualToString:@"les "])
				{
					artist = [NSString stringWithFormat:@"%@, Les", [artist substringFromIndex:4]];
				}
				[listOfArtists replaceObjectAtIndex:i withObject:artist];
			}
			else if ([artist length] > 4)
			{
				if ([[[artist substringToIndex:3] lowercaseString] isEqualToString:@"el "])
				{
					artist = [NSString stringWithFormat:@"%@, El", [artist substringFromIndex:3]];
				}
				else if ([[[artist substringToIndex:3] lowercaseString] isEqualToString:@"la "])
				{
					artist = [NSString stringWithFormat:@"%@, La", [artist substringFromIndex:3]];
				}
				else if ([[[artist substringToIndex:3] lowercaseString] isEqualToString:@"le "])
				{
					artist = [NSString stringWithFormat:@"%@, Le", [artist substringFromIndex:3]];
				}
				[listOfArtists replaceObjectAtIndex:i withObject:artist];
			}
			[pool release];
		}
		[listOfArtists sortUsingSelector:@selector(caseInsensitiveCompare:)];

		// Create the section index
		[databaseControls.inMemoryDb executeUpdate:@"DROP TABLE cachedSongsArtistIndex"];
		[databaseControls.inMemoryDb executeUpdate:@"CREATE TABLE cachedSongsArtistIndex (artist TEXT)"];
		for (NSString *artist in listOfArtists)
		{
			[databaseControls.inMemoryDb executeUpdate:@"INSERT INTO cachedSongsArtistIndex (artist) VALUES (?)", artist];
		}
		self.sectionInfo = nil; 
		self.sectionInfo = [databaseControls sectionInfoFromTable:@"cachedSongsArtistIndex" 
													   inDatabase:databaseControls.inMemoryDb 
													   withColumn:@"artist"];
		showIndex = YES;
		if ([sectionInfo count] < 5)
			showIndex = NO;

		// Sort into sections		
		if ([sectionInfo count] > 0)
		{
			int lastIndex = 0;
			for (int i = 0; i < [sectionInfo count] - 1; i++)
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				int index = [[[sectionInfo objectAtIndex:i+1] objectAtIndex:1] intValue];
				NSMutableArray *section = [NSMutableArray arrayWithCapacity:0];
				for (int i = lastIndex; i < index; i++)
				{
					[section addObject:[listOfArtists objectAtIndex:i]];
				}
				[listOfArtistsSections addObject:section];
				lastIndex = index;
				[pool release];
			}
			NSMutableArray *section = [NSMutableArray arrayWithCapacity:0];
			for (int i = lastIndex; i < [listOfArtists count]; i++)
			{
				[section addObject:[listOfArtists objectAtIndex:i]];
			}
			[listOfArtistsSections addObject:section];
		}
		
		
		// Move the definite article back to the beginning  Le El La The Los Las Les
		for (NSMutableArray *section in listOfArtistsSections)
		{
			for (int i = 0; i < [section count]; i++)
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				NSString *artist = [section objectAtIndex:i];
				NSUInteger length = [artist length];
				
				if (length > 6)
				{
					NSString *substring5 = [artist substringFromIndex:length - 5];
					if ([substring5 isEqualToString:@", The"] ||
						[substring5 isEqualToString:@", Los"] ||
						[substring5 isEqualToString:@", Las"] ||
						[substring5 isEqualToString:@", Les"])
					{
						artist = [NSString stringWithFormat:@"%@ %@", 
								  [artist substringFromIndex:length - 3], 
								  [artist substringToIndex:length - 5]];
					}
				}
				else if (length > 5)
				{
					NSString *substring4 = [artist substringFromIndex:length - 4];
					if ([substring4 isEqualToString:@", Le"] ||
						[substring4 isEqualToString:@", El"] ||
						[substring4 isEqualToString:@", La"])
					{
						artist = [NSString stringWithFormat:@"%@ %@", 
								  [artist substringFromIndex:length - 2], 
								  [artist substringToIndex:length - 4]];
					}
				}
				[section replaceObjectAtIndex:i withObject:artist];
				[pool release];
			}
		}
		
		//NSLog(@"sectionInfo: %@", sectionInfo);
		
		[self.tableView reloadData];
		
		if ([listOfArtists count] == 0)
		{
			[self removeSaveEditButtons];
						
			[self addNoSongsScreen];
		}
		else 
		{
			[self removeNoSongsScreen];
			
			if (viewObjects.isOfflineMode == NO)
			{
				[self addSaveEditButtons];
			}
		}
	}
	else if (segmentedControl.selectedSegmentIndex == 1)
	{
		if (self.tableView.editing)
		{
			[self editSongsAction:nil];
		}
		
		// Create the cachedSongsList table
		[self createQueuedSongsList];
		
		if ([databaseControls.songCacheDb intForQuery:@"SELECT COUNT(*) FROM cacheQueue"] == 0)
		{
			[self removeSaveEditButtons];
						
			[self addNoSongsScreen];
		}
		else
		{
			[self removeNoSongsScreen];
			
			[self addSaveEditButtons];
		}		
	}
	
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated 
{	
	[super viewWillAppear:animated];
	
	self.tableView.scrollEnabled = YES;
	[jukeboxInputBlocker removeFromSuperview];
	jukeboxInputBlocker = nil;
	if (viewObjects.isJukebox)
	{
		self.tableView.scrollEnabled = NO;
		
		jukeboxInputBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
		jukeboxInputBlocker.frame = CGRectMake(0, 0, 1004, 1004);
		[self.view addSubview:jukeboxInputBlocker];
		
		UIView *colorView = [[UIView alloc] initWithFrame:jukeboxInputBlocker.frame];
		colorView.backgroundColor = [UIColor blackColor];
		colorView.alpha = 0.5;
		[jukeboxInputBlocker addSubview:colorView];
		[colorView release];
	}
	
	if(musicControls.showPlayerIcon)
	{
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"now-playing.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(nowPlayingAction:)] autorelease];
	}
	else
	{
		self.navigationItem.rightBarButtonItem = nil;
	}
	
	// Reload the data in case it changed
	if (viewObjects.isCacheUnlocked)
	{
		self.tableView.tableHeaderView.hidden = NO;
		
		if (!firstLoad)
			[self segmentAction:nil];

		firstLoad = NO;
	}
	else
	{
		self.tableView.tableHeaderView.hidden = YES;
		[self addNoSongsScreen];
	}
}


-(void)viewWillDisappear:(BOOL)animated
{
	
}


- (void) settingsAction:(id)sender 
{
	ServerListViewController *serverListViewController = [[ServerListViewController alloc] initWithNibName:@"ServerListViewController" bundle:nil];
	serverListViewController.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:serverListViewController animated:YES];
	[serverListViewController release];
}


- (IBAction)nowPlayingAction:(id)sender
{
	musicControls.isNewSong = NO;
	iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
	streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:streamingPlayerViewController animated:YES];
	[streamingPlayerViewController release];
}


- (void) showDeleteButton
{
	if ([viewObjects.multiDeleteList count] == 0)
	{
		deleteSongsLabel.text = @"Delete All Songs";
	}
	else if ([viewObjects.multiDeleteList count] == 1)
	{
		deleteSongsLabel.text = @"Delete 1 Song  ";
	}
	else
	{
		deleteSongsLabel.text = [NSString stringWithFormat:@"Delete %i Songs", [viewObjects.multiDeleteList count]];
	}
	
	songsCountLabel.hidden = YES;
	deleteSongsLabel.hidden = NO;
}


- (void) hideDeleteButton
{
	if ([viewObjects.multiDeleteList count] == 0)
	{
		if (viewObjects.isEditing == NO)
		{
			songsCountLabel.hidden = NO;
			deleteSongsLabel.hidden = YES;
		}
		else
		{
			deleteSongsLabel.text = @"Delete All Songs";
		}
	}
	else if ([viewObjects.multiDeleteList count] == 1)
	{
		deleteSongsLabel.text = @"Delete 1 Song  ";
	}
	else 
	{
		deleteSongsLabel.text = [NSString stringWithFormat:@"Delete %i Songs", [viewObjects.multiDeleteList count]];
	}
}


- (void) showDeleteToggle
{
	// Show the delete toggle for already visible cells
	for (id cell in self.tableView.visibleCells) 
	{
		[[cell deleteToggleImage] setHidden:NO];
	}
}


- (void) editSongsAction:(id)sender
{
	if (segmentedControl.selectedSegmentIndex == 0)
	{
		if (viewObjects.isEditing == NO)
		{
			viewObjects.isEditing = YES;
			[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(showDeleteButton) name:@"showDeleteButton" object: nil];
			[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(hideDeleteButton) name:@"hideDeleteButton" object: nil];
			viewObjects.multiDeleteList = [NSMutableArray arrayWithCapacity:1];
			//viewObjects.multiDeleteList = nil; viewObjects.multiDeleteList = [[NSMutableArray alloc] init];
			editSongsLabel.backgroundColor = [UIColor colorWithRed:0.008 green:.46 blue:.933 alpha:1];
			editSongsLabel.text = @"Done";
			[self showDeleteButton];
			
			CustomUIAlertView *alert = [[CustomUIAlertView alloc] initWithTitle:@"Note" message:@"You can swipe to the right on any artist, album, or song and tap the delete button to remove them individually." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
		else 
		{
			viewObjects.isEditing = NO;
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"showDeleteButton" object:nil];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"hideDeleteButton" object:nil];
			viewObjects.multiDeleteList = [NSMutableArray arrayWithCapacity:1];
			//viewObjects.multiDeleteList = nil; viewObjects.multiDeleteList = [[NSMutableArray alloc] init];
			[self hideDeleteButton];
			editSongsLabel.backgroundColor = [UIColor clearColor];
			editSongsLabel.text = @"Edit";
			
			// Reload the table
			[self.tableView reloadData];
		}
	}
	else if (segmentedControl.selectedSegmentIndex == 1)
	{
		if (self.tableView.editing == NO)
		{
			viewObjects.isEditing = YES;
			[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(showDeleteButton) name:@"showDeleteButton" object: nil];
			[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(hideDeleteButton) name:@"hideDeleteButton" object: nil];
			viewObjects.multiDeleteList = [NSMutableArray arrayWithCapacity:1];
			//viewObjects.multiDeleteList = nil; viewObjects.multiDeleteList = [[NSMutableArray alloc] init];
			[self.tableView setEditing:YES animated:YES];
			editSongsLabel.backgroundColor = [UIColor colorWithRed:0.008 green:.46 blue:.933 alpha:1];
			editSongsLabel.text = @"Done";
			[self showDeleteButton];
			
			[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(showDeleteToggle) userInfo:nil repeats:NO];
		}
		else 
		{
			viewObjects.isEditing = NO;
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"showDeleteButton" object:nil];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"hideDeleteButton" object:nil];
			viewObjects.multiDeleteList = [NSMutableArray arrayWithCapacity:1];
			//viewObjects.multiDeleteList = nil; viewObjects.multiDeleteList = [[NSMutableArray alloc] init];
			[self hideDeleteButton];
			[self.tableView setEditing:NO animated:YES];
			editSongsLabel.backgroundColor = [UIColor clearColor];
			editSongsLabel.text = @"Edit";
			
			// Reload the table
			[self.tableView reloadData];
		}
	}
}

- (void)deleteRowsAtIndexPathsWithAnimation:(NSArray *)indexes
{
	[self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:YES];
}

- (void)clearCacheQueue
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// If there's a download in progress, stop it
	[musicControls stopDownloadQueue];
	
	// Delete each song from the database
	NSMutableArray *indexes = [[NSMutableArray alloc] init];
	NSInteger rowCount = [databaseControls.cacheQueueDb intForQuery:@"SELECT COUNT(*) FROM queuedSongsList"];
	for (int row = 1; row <= rowCount; row++)
	{
		NSInteger tableRow = row - 1;
		NSString *rowMD5 = [databaseControls.cacheQueueDb stringForQuery:@"SELECT md5 FROM queuedSongsList WHERE ROWID = ?", [NSNumber numberWithInt:row]];
		
		// Delete the row from the cacheQueue
		[databaseControls.cacheQueueDb executeUpdate:@"DELETE FROM cacheQueue WHERE md5 = ?", rowMD5];
		[databaseControls.cacheQueueDb executeUpdate:@"DELETE FROM queuedSongsList WHERE md5 = ?", rowMD5];
		
		// Add the row to the index array
		[indexes addObject:[NSIndexPath indexPathForRow:tableRow inSection:0]];
	}
	
	// Delete the rows from the table
	//[self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:YES];
	[self performSelectorOnMainThread:@selector(deleteRowsAtIndexPathsWithAnimation:) withObject:indexes waitUntilDone:YES];
	[indexes release];
	
	[viewObjects performSelectorOnMainThread:@selector(hideLoadingScreen) withObject:nil waitUntilDone:NO];
	
	[pool release];
}


- (void) deleteSongsAction:(id)sender
{
	if (viewObjects.isEditing)
	{
		if ([deleteSongsLabel.text isEqualToString:@"Delete All Songs"])
		{
			if (segmentedControl.selectedSegmentIndex == 0)
			{
				// Truncate the song cache genre tables
				[databaseControls.songCacheDb executeUpdate:@"DELETE FROM genres"];
				[databaseControls.songCacheDb executeUpdate:@"DELETE FROM genresSongs"];
				
				// Delete each song off the disk and from the songCacheDb
				FMResultSet *result = [databaseControls.songCacheDb executeQuery:@"SELECT md5, transcodedSuffix, suffix FROM cachedSongs WHERE finished = 'YES'"];
				while ([result next])
				{
					NSString *rowMD5 = [result stringForColumnIndex:0];
					NSString *transcodedSuffix = [result stringForColumnIndex:1];
					NSString *suffix = [result stringForColumnIndex:2];
					
					BOOL skipDelete = NO;
					// Check if we're deleting the song that's currently playing. If so, skip deleting it.
					if (musicControls.currentSongObject)
					{
						if ([[NSString md5:musicControls.currentSongObject.path] isEqualToString:rowMD5])
						{
							//[appDelegate destroyStreamer];
							skipDelete = YES;
						}
					}
					
					// Check if we're deleting the song that's about to play. If so, skip deleting it.
					if (musicControls.nextSongObject)
					{
						if ([[NSString md5:musicControls.nextSongObject.path] isEqualToString:rowMD5])
						{
							//[appDelegate destroyStreamer];
							skipDelete = YES;
						}
					}
					
					if (skipDelete == NO)
					{
						// Delete the row from the cachedSongs
						[databaseControls.songCacheDb executeUpdate:@"DELETE FROM cachedSongs WHERE md5 = ?", rowMD5];
						[databaseControls.songCacheDb executeUpdate:@"DELETE FROM cachedSongsLayout WHERE md5 = ?", rowMD5];
						
						// Delete the song from disk
						NSString *fileName;
						if (transcodedSuffix)
							fileName = [musicControls.audioFolderPath stringByAppendingString:[NSString stringWithFormat:@"/%@.%@", rowMD5, transcodedSuffix]];
						else
							fileName = [musicControls.audioFolderPath stringByAppendingString:[NSString stringWithFormat:@"/%@.%@", rowMD5, suffix]];
						[[NSFileManager defaultManager] removeItemAtPath:fileName error:NULL];
					}
				}
			}
			else if (segmentedControl.selectedSegmentIndex == 1)
			{
				/*[viewObjects showLoadingScreenOnMainWindow];
				[self performSelectorInBackground:@selector(clearCacheQueue) withObject:nil];*/
				
				// If there's a download in progress, stop it
				[musicControls stopDownloadQueue];
				
				// Delete each song from the database
				NSMutableArray *indexes = [[NSMutableArray alloc] init];
				NSInteger rowCount = [databaseControls.cacheQueueDb intForQuery:@"SELECT COUNT(*) FROM queuedSongsList"];
				for (int row = 1; row <= rowCount; row++)
				{
					NSInteger tableRow = row - 1;
					NSString *rowMD5 = [databaseControls.cacheQueueDb stringForQuery:@"SELECT md5 FROM queuedSongsList WHERE ROWID = ?", [NSNumber numberWithInt:row]];
					
					// Delete the row from the cacheQueue
					[databaseControls.cacheQueueDb executeUpdate:@"DELETE FROM cacheQueue WHERE md5 = ?", rowMD5];
					[databaseControls.cacheQueueDb executeUpdate:@"DELETE FROM queuedSongsList WHERE md5 = ?", rowMD5];
					
					// Add the row to the index array
					[indexes addObject:[NSIndexPath indexPathForRow:tableRow inSection:0]];
				}
				
				// Delete the rows from the table
				[self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:YES];
				[indexes release];
			}
		}
		else
		{
			if (segmentedControl.selectedSegmentIndex == 1)
			{
				// Sort the multiDeleteList to make sure it's accending
				[viewObjects.multiDeleteList sortUsingSelector:@selector(compare:)];
				
				// Delete each song from the database
				NSMutableArray *indexes = [[NSMutableArray alloc] init];
				for (NSNumber *rowNumber in viewObjects.multiDeleteList)
				{
					NSInteger row = [rowNumber intValue] + 1;
					NSString *rowMD5 = [databaseControls.cacheQueueDb stringForQuery:@"SELECT md5 FROM queuedSongsList WHERE ROWID = ?", [NSNumber numberWithInt:row]];
					
					// Check if we're deleting the song that's currently caching. If so, stop the download.
					if (musicControls.queueSongObject)
					{
						if ([[NSString md5:musicControls.queueSongObject.path] isEqualToString:rowMD5])
						{
							[musicControls stopDownloadQueue];
						}
					}
					
					// Delete the row from the cachedSongs
					[databaseControls.cacheQueueDb executeUpdate:@"DELETE FROM cacheQueue WHERE md5 = ?", rowMD5];
					[databaseControls.cacheQueueDb executeUpdate:@"DELETE FROM queuedSongsList WHERE md5 = ?", rowMD5];
					
					// Add the row to the index array
					[indexes addObject:[NSIndexPath indexPathForRow:[rowNumber intValue] inSection:0]];
				}
				
				// Delete the rows from the table
				[self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:YES];
				[indexes release];
			}
		}
		
		// Reload the table
		[self editSongsAction:nil];
		[self viewWillAppear:NO];
	}
}

- (void)playAllAction:(id)sender
{	
	[viewObjects showLoadingScreenOnMainWindow];
	[self performSelectorInBackground:@selector(loadPlayAllPlaylist:) withObject:@"NO"];
}

- (void)shuffleAction:(id)sender
{
	[viewObjects showLoadingScreenOnMainWindow];
	[self performSelectorInBackground:@selector(loadPlayAllPlaylist:) withObject:@"YES"];
}


- (void)loadPlayAllPlaylist:(NSString *)shuffle
{	
	// Create an autorelease pool because this method runs in a background thread and can't use the main thread's pool
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	musicControls.isShuffle = NO;
	
	BOOL isShuffle;
	if ([shuffle isEqualToString:@"YES"])
		isShuffle = YES;
	else
		isShuffle = NO;
	
	[musicControls performSelectorOnMainThread:@selector(destroyStreamer) withObject:nil waitUntilDone:YES];
	[databaseControls resetCurrentPlaylistDb];
	
	FMResultSet *result = [databaseControls.songCacheDb executeQuery:@"SELECT md5 FROM cachedSongsLayout ORDER BY seg1 COLLATE NOCASE"];
	
	while ([result next])
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		Song *aSong = [databaseControls songFromCacheDb:[result stringForColumnIndex:0]];
		
		if (aSong.path)
			[databaseControls addSongToPlaylistQueue:aSong];
		
		[pool release];
	}
	
	if (isShuffle)
	{
		musicControls.isShuffle = YES;
		[databaseControls shufflePlaylist];
	}
	else
	{
		musicControls.isShuffle = NO;
	}
	
	if (viewObjects.isJukebox)
		[musicControls jukeboxReplacePlaylistWithLocal];
	
	// Must do UI stuff in main thread
	[viewObjects performSelectorOnMainThread:@selector(hideLoadingScreen) withObject:nil waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(playAllPlaySong) withObject:nil waitUntilDone:NO];	
	
	[autoreleasePool release];
}


- (void)playAllPlaySong
{
	musicControls.isNewSong = YES;
	
	[musicControls playSongAtPosition:0];
	
	if (IS_IPAD())
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"showPlayer" object:nil];
	}
	else
	{
		iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
		streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
		[self.navigationController pushViewController:streamingPlayerViewController animated:YES];
		[streamingPlayerViewController release];
	}
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if (segmentedControl.selectedSegmentIndex == 0 && viewObjects.isCacheUnlocked)
	{
		return [sectionInfo count];
	}
	
	return 1;
}

// Following 2 methods handle the right side index
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView 
{
	if (segmentedControl.selectedSegmentIndex == 0 && viewObjects.isCacheUnlocked && showIndex)
	{
		NSMutableArray *indexes = [[[NSMutableArray alloc] init] autorelease];
		for (int i = 0; i < [sectionInfo count]; i++)
		{
			[indexes addObject:[[sectionInfo objectAtIndex:i] objectAtIndex:0]];
		}
		return indexes;
	}
		
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	if (segmentedControl.selectedSegmentIndex == 0 && viewObjects.isCacheUnlocked)
	{
		return [[sectionInfo objectAtIndex:section] objectAtIndex:0];
	}
	
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index 
{
	if (segmentedControl.selectedSegmentIndex == 0)
	{
		/*if (index == 0)
		{
			[tableView scrollRectToVisible:CGRectMake(0, 90, 320, 40) animated:NO];
		}
		else
		{
			NSUInteger row = [[[sectionInfo objectAtIndex:(index - 1)] objectAtIndex:1] intValue];
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
			[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}*/
		
		if (index == 0) 
		{
			[tableView scrollRectToVisible:CGRectMake(0, 90, 320, 40) animated:NO];
			return -1;
		}
		
		return index;
	}
	
	return -1;
}


// Customize the height of individual rows to make the album rows taller to accomidate the album art.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (segmentedControl.selectedSegmentIndex == 0)
		return 44.0;
	else
		return 80.0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (viewObjects.isCacheUnlocked)
	{
		// Return the number of rows in the section.
		if (segmentedControl.selectedSegmentIndex == 0)
		{
			//return [listOfArtists count];
			return [[listOfArtistsSections objectAtIndex:section] count];
		}
		else if (segmentedControl.selectedSegmentIndex == 1)
		{
			return [databaseControls.songCacheDb intForQuery:@"SELECT COUNT(*) FROM cacheQueue"];
		}
	}
	
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	if (segmentedControl.selectedSegmentIndex == 0)
	{
		static NSString *CellIdentifier = @"Cell";
		
		CacheArtistUITableViewCell *cell = [[[CacheArtistUITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		//cell.indexPath = indexPath;
		
		if (showIndex)
			cell.isIndexShowing = YES;
		
		// Set up the cell...
		//[cell.artistNameLabel setText:[listOfArtists objectAtIndex:indexPath.row]];
		[cell.artistNameLabel setText:[[listOfArtistsSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
		
		cell.backgroundView = [[[UIView alloc] init] autorelease];
		if(indexPath.row % 2 == 0)
			cell.backgroundView.backgroundColor = viewObjects.lightNormal;
		else
			cell.backgroundView.backgroundColor = viewObjects.darkNormal;
		
		return cell;
	}
	else
	{
		static NSString *CellIdentifier = @"Cell";
		CacheQueueSongUITableViewCell *cell = [[[CacheQueueSongUITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.indexPath = indexPath;
		
		cell.deleteToggleImage.hidden = !viewObjects.isEditing;
		if ([viewObjects.multiDeleteList containsObject:[NSNumber numberWithInt:indexPath.row]])
		{
			cell.deleteToggleImage.image = [UIImage imageNamed:@"selected.png"];
		}
		
		// Set up the cell...
		Song *aSong = [self songFromDbRow:indexPath.row inTable:@"queuedSongsList"];

		if (aSong.coverArtId)
		{
			if ([databaseControls.coverArtCacheDb60 intForQuery:@"SELECT COUNT(*) FROM coverArtCache WHERE id = ?", [NSString md5:aSong.coverArtId]] == 1)
			{
				// If the image is already in the cache dictionary, load it
				cell.coverArtView.image = [UIImage imageWithData:[databaseControls.coverArtCacheDb60 dataForQuery:@"SELECT data FROM coverArtCache WHERE id = ?", [NSString md5:aSong.coverArtId]]];
			}
			else 
			{			
				// If not, grab it from the url and cache it
				NSString *imgUrlString;
				if (appDelegate.isHighRez)
				{
					imgUrlString = [NSString stringWithFormat:@"%@%@&size=120", [appDelegate getBaseUrl:@"getCoverArt.view"], aSong.coverArtId];
				}
				else
				{
					imgUrlString = [NSString stringWithFormat:@"%@%@&size=60", [appDelegate getBaseUrl:@"getCoverArt.view"], aSong.coverArtId];
				}
				[cell.coverArtView loadImageFromURLString:imgUrlString coverArtId:aSong.coverArtId];
			}
		}
		else
		{
			cell.coverArtView.image = [UIImage imageNamed:@"default-album-art-small.png"];
		}
		
		cell.backgroundView = [[[UIView alloc] init] autorelease];
		if(indexPath.row % 2 == 0)
			cell.backgroundView.backgroundColor = viewObjects.lightNormal;
		else
			cell.backgroundView.backgroundColor = viewObjects.darkNormal;
		
		NSDate *cached = [NSDate dateWithTimeIntervalSince1970:(double)[databaseControls.songCacheDb intForQuery:@"SELECT cachedDate FROM queuedSongsList WHERE ROWID = ?", [NSNumber numberWithInt:(indexPath.row + 1)]]];
		if ([[NSString md5:aSong.path] isEqualToString:musicControls.downloadFileNameHashQueue] && musicControls.isQueueListDownloading)
		{
			[cell.cacheInfoLabel setText:[NSString stringWithFormat:@"Queued %@ - Progress: %@", [appDelegate relativeTime:cached], [appDelegate formatFileSize:queueDownloadProgress]]];
		}
		else if (indexPath.row == 0)
		{
			[cell.cacheInfoLabel setText:[NSString stringWithFormat:@"Queued %@ - Progress: Need Wifi", [appDelegate relativeTime:cached]]];
		}
		else
		{
			[cell.cacheInfoLabel setText:[NSString stringWithFormat:@"Queued %@ - Progress: Waiting...", [appDelegate relativeTime:cached]]];
		}
		
		[cell.songNameLabel setText:aSong.title];
		if (aSong.album)
			[cell.artistNameLabel setText:[NSString stringWithFormat:@"%@ - %@", aSong.artist, aSong.album]];
		else
			[cell.artistNameLabel setText:aSong.artist];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		return cell;
	}
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Set the editing style, set to none for no delete minus sign (overriding with own custom multi-delete boxes)
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
	//return UITableViewCellEditingStyleDelete;
}


#pragma mark -
#pragma mark Table view delegate

NSInteger trackSort1(id obj1, id obj2, void *context)
{
	NSUInteger track1 = [(NSNumber*)[(NSArray*)obj1 objectAtIndex:1] intValue];
	NSUInteger track2 = [(NSNumber*)[(NSArray*)obj2 objectAtIndex:1] intValue];
	if (track1 < track2)
		return NSOrderedAscending;
	else if (track1 == track2)
		return NSOrderedSame;
	else
		return NSOrderedDescending;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (segmentedControl.selectedSegmentIndex == 0)
	{
		if (viewObjects.isCellEnabled)
		{
			CacheAlbumViewController *cacheAlbumViewController = [[CacheAlbumViewController alloc] initWithNibName:@"CacheAlbumViewController" bundle:nil];
			//cacheAlbumViewController.title = [listOfArtists objectAtIndex:indexPath.row];
			cacheAlbumViewController.title = [[listOfArtistsSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
			cacheAlbumViewController.listOfAlbums = [NSMutableArray arrayWithCapacity:1];
			cacheAlbumViewController.listOfSongs = [NSMutableArray arrayWithCapacity:1];
			//cacheAlbumViewController.listOfAlbums = [[NSMutableArray alloc] init];
			//cacheAlbumViewController.listOfSongs = [[NSMutableArray alloc] init];
			cacheAlbumViewController.segment = 2;
			cacheAlbumViewController.seg1 = [[listOfArtistsSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
			FMResultSet *result = [databaseControls.songCacheDb executeQuery:@"SELECT md5, segs, seg2, track FROM cachedSongsLayout JOIN cachedSongs USING(md5) WHERE seg1 = ? GROUP BY seg2 ORDER BY seg2 COLLATE NOCASE", [[listOfArtistsSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
			while ([result next])
			{
				if ([result intForColumnIndex:1] > 2)
				{
					[cacheAlbumViewController.listOfAlbums addObject:[NSArray arrayWithObjects:[result stringForColumnIndex:0], 
																							   [result stringForColumnIndex:2], nil]];
				}
				else
				{
					[cacheAlbumViewController.listOfSongs addObject:[NSArray arrayWithObjects:[result stringForColumnIndex:0], 
																							  [NSNumber numberWithInt:[result intForColumnIndex:3]], nil]];
					
					/*// Sort by track number -- iOS 4.0+ only
					[cacheAlbumViewController.listOfSongs sortUsingComparator: ^NSComparisonResult(id obj1, id obj2) {
						NSUInteger track1 = [(NSNumber*)[(NSArray*)obj1 objectAtIndex:1] intValue];
						NSUInteger track2 = [(NSNumber*)[(NSArray*)obj2 objectAtIndex:1] intValue];
						if (track1 < track2)
							return NSOrderedAscending;
						else if (track1 == track2)
							return NSOrderedSame;
						else
							return NSOrderedDescending;
					}];*/
					
					BOOL multipleSameTrackNumbers = NO;
					NSMutableArray *trackNumbers = [NSMutableArray arrayWithCapacity:[cacheAlbumViewController.listOfSongs count]];
					for (NSArray *song in cacheAlbumViewController.listOfSongs)
					{
						NSNumber *track = [song objectAtIndex:1];
						
						if ([trackNumbers containsObject:track])
						{
							multipleSameTrackNumbers = YES;
							break;
						}
						
						[trackNumbers addObject:track];
					}
					
					// Sort by track number
					if (!multipleSameTrackNumbers)
						[cacheAlbumViewController.listOfSongs sortUsingFunction:trackSort1 context:NULL];
				}
			}
			
			[self.navigationController pushViewController:cacheAlbumViewController animated:YES];
			[cacheAlbumViewController release];
		}
		else
		{
			[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
		}
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"queuedSongDone" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"cachedSongDeleted" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
	[updateTimer invalidate]; updateTimer = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

