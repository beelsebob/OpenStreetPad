//
//  OSPValue.h
//  OpenStreetPad
//
//  Created by Tom Davie on 04/09/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPCoordinateRect.h"

@interface OSPValue : NSObject

+ (id)valueWithRect:(OSPCoordinateRect)rect;
+ (id)valueWithTile:(OSPTile)tile;

- (OSPCoordinateRect)rectValue;
- (OSPTile)tileValue;

@end

