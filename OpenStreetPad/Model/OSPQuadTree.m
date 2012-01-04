//
//  OSPQuadTree.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 20/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPQuadTree.h"

#define OSPMapExpandLimit 100

typedef enum
{
    OSPQuadTreeQuadrantTopLeft = 0,
    OSPQuadTreeQuadrantTopRight   ,
    OSPQuadTreeQuadrantBottomLeft ,
    OSPQuadTreeQuadrantBottomRight
} OSPQuadTreeQuadrant;

@interface OSPQuadTree ()

@property (readwrite, assign) OSPCoordinateRect bounds;
@property (readwrite, assign, getter=isLeaf) BOOL leaf;
@property (readwrite, strong) CFMutableSetRef __attribute__((NSObject)) contents;
@property (readwrite, strong) NSRecursiveLock *readLock;

- (void)placeObjectInChild:(id<OSPBounded>)object;
- (void)expand;

- (void)addObjectsInBounds:(OSPCoordinateRect)bounds toSet:(CFMutableSetRef)set;

@end

@implementation OSPQuadTree
{
    __strong OSPQuadTree *children[4];
    OSPCoordinateRect childRects[4];
}

@synthesize bounds;
@synthesize leaf;
@synthesize contents;
@synthesize readLock;

- (id)initWithBounds:(OSPCoordinateRect)initBounds
{
    self = [super init];
    
    if (nil != self)
    {
        CFSetCallBacks callbacks = kCFTypeSetCallBacks;
        CFMutableSetRef s = CFSetCreateMutable(NULL, 0, &callbacks);
        [self setContents:s];
        CFRelease(s);
        
        [self setReadLock:[[NSRecursiveLock alloc] init]];
        
        [self setBounds:initBounds];
        
        children[0] = nil;
        children[1] = nil;
        children[2] = nil;
        children[3] = nil;
        [self setLeaf:YES];
    }
    
    return self;
}

- (void)addObject:(id<OSPBounded>)o
{
    BOOL l = [self isLeaf];
    if (l && [(__bridge NSSet *)[self contents] count] == OSPMapExpandLimit)
    {
        [self expand];
    }
    
    if (!l)
    {
        [self placeObjectInChild:o];
    }
    else
    {
        [[self readLock] lock];
        CFSetAddValue([self contents], (__bridge const void *)o);
        [[self readLock] unlock];
    }
}

- (void)placeObjectInChild:(id<OSPBounded>)o
{
    OSPCoordinateRect objectBounds = [o bounds];
    if (OSPCoordinateRectContainsRect(childRects[OSPQuadTreeQuadrantTopLeft], objectBounds))
    {
        [children[OSPQuadTreeQuadrantTopLeft] addObject:o];
    }
    else if (OSPCoordinateRectContainsRect(childRects[OSPQuadTreeQuadrantTopRight], objectBounds))
    {
        [children[OSPQuadTreeQuadrantTopRight] addObject:o];
    }
    else if (OSPCoordinateRectContainsRect(childRects[OSPQuadTreeQuadrantBottomLeft], objectBounds))
    {
        [children[OSPQuadTreeQuadrantBottomLeft] addObject:o];
    }
    else if (OSPCoordinateRectContainsRect(childRects[OSPQuadTreeQuadrantBottomRight], objectBounds))
    {
        [children[OSPQuadTreeQuadrantBottomRight] addObject:o];
    }
    else
    {
        [[self readLock] lock];
        CFSetAddValue([self contents], (__bridge const void *)o);
        [[self readLock] unlock];
    }
}

- (void)expand
{
    OSPCoordinateRect ownBounds = [self bounds];
    double minX = OSPCoordinateRectGetMinLongitude(ownBounds);
    double minY = OSPCoordinateRectGetMinLatitude(ownBounds);
    double halfWidth = OSPCoordinateRectGetWidth(ownBounds) * 0.5;
    double halfHeight = OSPCoordinateRectGetHeight(ownBounds) * 0.5;
    double midX = minX + halfWidth;
    double midY = minY + halfHeight;
    
    childRects[OSPQuadTreeQuadrantTopLeft    ] = OSPCoordinateRectMake(minX, minY, halfWidth, halfHeight);
    childRects[OSPQuadTreeQuadrantTopRight   ] = OSPCoordinateRectMake(midX, minY, halfWidth, halfHeight);
    childRects[OSPQuadTreeQuadrantBottomLeft ] = OSPCoordinateRectMake(minX, midY, halfWidth, halfHeight);
    childRects[OSPQuadTreeQuadrantBottomRight] = OSPCoordinateRectMake(midX, midY, halfWidth, halfHeight);
    
    children[OSPQuadTreeQuadrantTopLeft    ] = [[OSPQuadTree alloc] initWithBounds:childRects[OSPQuadTreeQuadrantTopLeft    ]];
    children[OSPQuadTreeQuadrantTopRight   ] = [[OSPQuadTree alloc] initWithBounds:childRects[OSPQuadTreeQuadrantTopRight   ]];
    children[OSPQuadTreeQuadrantBottomLeft ] = [[OSPQuadTree alloc] initWithBounds:childRects[OSPQuadTreeQuadrantBottomLeft ]];
    children[OSPQuadTreeQuadrantBottomRight] = [[OSPQuadTree alloc] initWithBounds:childRects[OSPQuadTreeQuadrantBottomRight]];
    
    NSSet *oldContents = [(__bridge NSSet *)[self contents] copy];
    CFSetCallBacks callbacks = kCFTypeSetCallBacks;
    CFMutableSetRef s = CFSetCreateMutable(NULL, OSPMapExpandLimit, &callbacks);
    [self setContents:s];
    CFRelease(s);
    
    for (id<OSPBounded> object in oldContents)
    {
        [self placeObjectInChild:object];
    }
    
    [self setLeaf:NO];
}

- (NSSet *)objectsInBounds:(OSPCoordinateRect)searchBounds
{
    if (OSPCoordinateRectIntersectsRect([self bounds], searchBounds))
    {
        CFSetCallBacks callbacks = kCFTypeSetCallBacks;
        CFMutableSetRef objects = CFSetCreateMutable(NULL, 0, &callbacks);
        
        [[self readLock] lock];
        for (id<OSPBounded> object in (__bridge NSSet *)[self contents])
        {
            if (OSPCoordinateRectIntersectsRect([object bounds], searchBounds))
            {
                CFSetAddValue(objects, (__bridge const void *)object);
            }
        }
        [[self readLock] unlock];
        
        if (![self isLeaf])
        {
            for (int i = 0; i < 4; i++)
            {
                [children[i] addObjectsInBounds:searchBounds toSet:objects];
            }
        }
        
        NSSet *os = (__bridge_transfer NSSet *)objects;
        
        return os;
    }
    else
    {
        return [NSSet set];
    }
}

- (void)addObjectsInBounds:(OSPCoordinateRect)searchBounds toSet:(CFMutableSetRef)set
{
    if (OSPCoordinateRectIntersectsRect([self bounds], searchBounds))
    {
        [[self readLock] lock];
        for (id<OSPBounded> object in (__bridge NSSet *)[self contents])
        {
            if (OSPCoordinateRectIntersectsRect([object bounds], searchBounds))
            {
                CFSetAddValue(set, (__bridge const void *)object);
            }
        }
        [[self readLock] unlock];
        
        if (![self isLeaf])
        {
            for (int i = 0; i < 4; i++)
            {
                [children[i] addObjectsInBounds:searchBounds toSet:set];
            }
        }
    }
}

@end
