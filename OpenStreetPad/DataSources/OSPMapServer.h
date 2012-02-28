//
//  OSPMapServer.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 07/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPDataSource.h"

@interface OSPMapServer : OSPDataSource

+ (id)serverWithURL:(NSURL *)serverURL;
- (id)initWithURL:(NSURL *)serverURL;

@property (readonly , copy) NSURL *serverURL;

@end
