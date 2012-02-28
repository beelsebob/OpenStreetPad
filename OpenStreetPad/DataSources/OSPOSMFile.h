//
//  OSPOSMFileStore.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 28/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPDataSource.h"

@interface OSPOSMFile : OSPDataSource

+ (id)osmFileWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;

@property (readwrite, strong) NSString *path;

@end
