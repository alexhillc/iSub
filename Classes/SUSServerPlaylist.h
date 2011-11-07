//
//  SUSServerPlaylist.h
//  iSub
//
//  Created by Benjamin Baron on 11/6/11.
//  Copyright (c) 2011 Ben Baron. All rights reserved.
//

#import "TBXML.h"

@interface SUSServerPlaylist : NSObject <NSCopying>

@property (nonatomic, copy) NSString *playlistId;
@property (nonatomic, copy) NSString *playlistName;

- (id)initWithTBXMLElement:(TBXMLElement *)element;

@end
