//
//  ShuffleFolderPickerViewController.h
//  iSub
//
//  Created by Ben Baron on 4/6/11.
//  Copyright 2011 Ben Baron. All rights reserved.
//

#import "FolderPickerDialog.h"
#import "NewHomeViewController.h"

@class iSubAppDelegate;

@interface ShuffleFolderPickerViewController : UITableViewController 
{
    iSubAppDelegate *appDelegate;
	
	NSMutableArray *sortedFolders;
	
	FolderPickerDialog *myDialog;
}

@property (nonatomic, retain) NSMutableArray *sortedFolders;
@property (nonatomic, assign) FolderPickerDialog *myDialog;

@end