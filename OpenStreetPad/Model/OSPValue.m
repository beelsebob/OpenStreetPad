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

@implementation OSPValue

+ (id)valueWithRect:(OSPCoordinateRect)rect
{
    return [[OSPRectValue alloc] initWithRect:rect];
}

- (OSPCoordinateRect)rectValue
{
    return OSPCoordinateRectZero;
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