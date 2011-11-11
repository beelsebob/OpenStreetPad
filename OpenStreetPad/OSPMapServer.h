//
//  OSPMapServer.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 07/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPCoordinateRect.h"

@class OSPMapServer;

@protocol OSPMapServerDelegate <NSObject>

- (void)mapServer:(OSPMapServer *)mapServer didLoadObjectsInArea:(OSPCoordinateRect)area;

@end

@interface OSPMapServer : NSObject

+ (id)serverWithURL:(NSURL *)serverURL;
- (id)initWithURL:(NSURL *)serverURL;

@property (readonly , copy) NSURL *serverURL;
@property (readwrite, weak) id<OSPMapServerDelegate> delegate;

- (void)loadObjectsInBounds:(OSPCoordinateRect)bounds withOutset:(double)outsetSize;
- (NSSet *)objectsInBounds:(OSPCoordinateRect)bounds;

@end
