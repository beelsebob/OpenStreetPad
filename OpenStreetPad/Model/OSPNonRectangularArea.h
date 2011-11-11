//
//  OSPNonRectangularArea.h
//  OpenStreetPad
//
//  Created by Tom Davie on 04/09/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPCoordinateRect.h"

@interface OSPNonRectangularArea : NSObject

+ (id)emptyArea;
+ (id)areaWithRects:(NSArray *)rects;

- (id)initWithRects:(NSArray *)rects;

- (OSPNonRectangularArea *)areaBySubtractingArea:(OSPNonRectangularArea *)other;

- (void)addRect:(OSPCoordinateRect)rect;

- (NSArray *)allRects;

@end
