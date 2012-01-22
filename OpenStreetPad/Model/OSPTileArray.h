//
//  OSPTileArray.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 21/01/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPCoordinateRect.h"

@interface OSPTileArray : NSObject

- (void)addTile:(OSPTile)t;
- (NSArray *)notIncludedSubtilesOfTile:(OSPTile)t;

@end
