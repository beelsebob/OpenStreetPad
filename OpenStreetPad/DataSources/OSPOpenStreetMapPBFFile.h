//
//  OSPOpenStreetMapPBFFile.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 21/04/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPDataSource.h"

@interface OSPOpenStreetMapPBFFile : OSPDataSource

+ (id)osmFileWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;

@property (readwrite, strong) NSString *path;

@end
