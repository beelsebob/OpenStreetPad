//
//  OSPValue.m
//  OpenStreetPad
//
//  Created by Tom Davie on 04/09/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPValue.h"

@interface OSPRectValue : OSPValue

- (id)initWithRect:(OSPCoordinateRect)rect;

@end

@interface OSPTileValue : OSPValue

- (id)initWithTile:(OSPTile)tile;

@end

@implementation OSPValue

+ (id)valueWithRect:(OSPCoordinateRect)rect
{
    return [[OSPRectValue alloc] initWithRect:rect];
}

+ (id)valueWithTile:(OSPTile)tile
{
    return [[OSPTileValue alloc] initWithTile:tile];
}

- (OSPCoordinateRect)rectValue
{
    return OSPCoordinateRectZero;
}

- (OSPTile)tileValue
{
    return (OSPTile){.x = NSNotFound, .y = NSNotFound, .zoom = 0};
}

@end

@interface OSPRectValue ()

@property (readwrite, assign) OSPCoordinateRect rect;

@end

@implementation OSPRectValue

@synthesize rect;

- (id)initWithRect:(OSPCoordinateRect)r
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRect:r];
    }
    
    return self;
}

- (OSPCoordinateRect)rectValue
{
    return [self rect];
}

@end

@interface OSPTileValue ()

@property (readwrite, assign) OSPTile tile;

@end

@implementation OSPTileValue

@synthesize tile;

- (id)initWithTile:(OSPTile)t
{
    self = [super init];
    
    if (nil != self)
    {
        [self setTile:t];
    }
    
    return self;
}

- (OSPTile)tileValue
{
    return [self tile];
}

@end