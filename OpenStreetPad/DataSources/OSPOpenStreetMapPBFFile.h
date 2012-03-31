//
//  OSPOpenStreetMapPBFFile.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 04/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPDataSource.h"

@interface OSPOpenStreetMapPBFFile : OSPDataSource

+ (id)pbfFileWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;

@property (readwrite, strong) NSString *path;

@end
