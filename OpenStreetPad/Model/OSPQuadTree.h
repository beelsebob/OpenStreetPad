//
//  OSPQuadTree.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 20/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPCoordinateRect.h"

@interface OSPQuadTree : NSObject

- (id)initWithBounds:(OSPCoordinateRect)initBounds;

- (void)addObject:(id<OSPBounded>)o;

- (NSSet *)objectsInBounds:(OSPCoordinateRect)bounds;

@end
