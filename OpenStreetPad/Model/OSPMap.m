//
//  OSPMap.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPMap.h"

#import "OSPAPIObjectReference.h"

#define OSPMapExpandLimit 100

typedef enum
{
    OSPQuadTreeQuadrantTopLeft = 0,
    OSPQuadTreeQuadrantTopRight   ,
    OSPQuadTreeQuadrantBottomLeft ,
    OSPQuadTreeQuadrantBottomRight
} OSPQuadTreeQuadrant;

@interface OSPMap ()

@property (readwrite, assign) OSPCoordinateRect bounds;
@property (readwrite, assign) BOOL isSuperMap;
@property (readwrite, assign) BOOL hasChildMaps;

@property (readwrite, strong) CFMutableSetRef __attribute__((NSObject)) completeContents;
@property (readwrite, strong) CFMutableSetRef __attribute__((NSObject)) contents;

@property (readwrite, strong) NSLock *readLock;

- (id)initWithBounds:(OSPCoordinateRect)initBounds;

- (void)placeObjectInChild:(OSPAPIObject *)apiObject;
- (void)expand;

- (void)addObjectsInBounds:(OSPCoordinateRect)bounds toSet:(CFMutableSetRef)set;

- (OSPAPIObject *)apiObjectMatchingReference:(OSPAPIObjectReference *)ref;

@end

Boolean APIObjectEqual (const void *value1, const void *value2);

Boolean APIObjectEqual (const void *value1, const void *value2)
{
    return [(__bridge OSPAPIObject *)value1 isEqualToAPIObject:(__bridge OSPAPIObject *)value2];
}

@implementation OSPMap
{
    __strong OSPMap *children[4];
    OSPCoordinateRect childRects[4];
}

@synthesize bounds;
@synthesize isSuperMap;
@synthesize hasChildMaps;

@synthesize completeContents;
@synthesize contents;

@synthesize readLock;

- (id)init
{
    self = [self initWithBounds:OSPCoordinateRectMake(0.0, 0.0, 1.0, 1.0)];
    
    if (nil != self)
    {
        [self setIsSuperMap:YES];
        
        CFSetCallBacks callbacks = kCFTypeSetCallBacks;
        callbacks.equal = APIObjectEqual;
        CFMutableSetRef s = CFSetCreateMutable(NULL, 0, &callbacks);
        [self setCompleteContents:s];
        CFRelease(s);
    }
    
    return self;
}

- (id)initWithBounds:(OSPCoordinateRect)initBounds;
{
    self = [super init];
    
    if (nil != self)
    {
        [self setIsSuperMap:NO];
        [self setCompleteContents:nil];
        CFSetCallBacks callbacks = kCFTypeSetCallBacks;
        callbacks.equal = APIObjectEqual;
        CFMutableSetRef s = CFSetCreateMutable(NULL, OSPMapExpandLimit, &callbacks);
        [self setContents:s];
        CFRelease(s);
        
        children[0] = nil;
        children[1] = nil;
        children[2] = nil;
        children[3] = nil;
        
        [self setHasChildMaps:NO];
        [self setBounds:initBounds];
    }
    
    return self;
}

- (void)addObject:(OSPAPIObject *)apiObject
{
    if ([self isSuperMap])
    {
        CFSetAddValue([self completeContents], (__bridge const void *)apiObject);
    }
    
    if (![self hasChildMaps] && [(__bridge NSSet *)[self contents] count] == OSPMapExpandLimit)
    {
        [self expand];
    }
    
    if ([self hasChildMaps])
    {
        [self placeObjectInChild:apiObject];
    }
    else
    {
        [[self readLock] lock];
        CFSetAddValue([self contents], (__bridge const void *)apiObject);
        [[self readLock] unlock];
    }
}

- (void)placeObjectInChild:(OSPAPIObject *)apiObject
{
    OSPCoordinateRect objectBounds = [apiObject bounds];
    if (OSPCoordinateRectContainsRect(childRects[OSPQuadTreeQuadrantTopLeft], objectBounds))
    {
        [children[OSPQuadTreeQuadrantTopLeft] addObject:apiObject];
    }
    else if (OSPCoordinateRectContainsRect(childRects[OSPQuadTreeQuadrantTopRight], objectBounds))
    {
        [children[OSPQuadTreeQuadrantTopRight] addObject:apiObject];
    }
    else if (OSPCoordinateRectContainsRect(childRects[OSPQuadTreeQuadrantBottomLeft], objectBounds))
    {
        [children[OSPQuadTreeQuadrantBottomLeft] addObject:apiObject];
    }
    else if (OSPCoordinateRectContainsRect(childRects[OSPQuadTreeQuadrantBottomRight], objectBounds))
    {
        [children[OSPQuadTreeQuadrantBottomRight] addObject:apiObject];
    }
    else
    {
        [[self readLock] lock];
        CFSetAddValue([self contents], (__bridge const void *) apiObject);
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
    
    children[OSPQuadTreeQuadrantTopLeft    ] = [[OSPMap alloc] initWithBounds:childRects[OSPQuadTreeQuadrantTopLeft    ]];
    children[OSPQuadTreeQuadrantTopRight   ] = [[OSPMap alloc] initWithBounds:childRects[OSPQuadTreeQuadrantTopRight   ]];
    children[OSPQuadTreeQuadrantBottomLeft ] = [[OSPMap alloc] initWithBounds:childRects[OSPQuadTreeQuadrantBottomLeft ]];
    children[OSPQuadTreeQuadrantBottomRight] = [[OSPMap alloc] initWithBounds:childRects[OSPQuadTreeQuadrantBottomRight]];
    
    NSSet *oldContents = [(__bridge NSSet *)[self contents] copy];
    CFSetCallBacks callbacks = kCFTypeSetCallBacks;
    callbacks.equal = APIObjectEqual;
    CFMutableSetRef s = CFSetCreateMutable(NULL, OSPMapExpandLimit, &callbacks);
    [self setContents:s];
    CFRelease(s);
    
    for (OSPAPIObject *object in oldContents)
    {
        [self placeObjectInChild:object];
    }
    
    [self setHasChildMaps:YES];
}

- (NSSet *)objectsInBounds:(OSPCoordinateRect)searchBounds
{
    if (OSPCoordinateRectIntersectsRect([self bounds], searchBounds))
    {
        CFSetCallBacks callbacks = kCFTypeSetCallBacks;
        callbacks.equal = APIObjectEqual;
        CFMutableSetRef objects = CFSetCreateMutable(NULL, 0, &callbacks);
        
        [[self readLock] lock];
        for (OSPAPIObject *object in (__bridge NSSet *)[self contents])
        {
            if (OSPCoordinateRectIntersectsRect([object bounds], searchBounds))
            {
                CFSetAddValue(objects, (__bridge const void *)object);
            }
        }
        [[self readLock] unlock];

        if ([self hasChildMaps])
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
        for (OSPAPIObject *object in (__bridge NSSet *)[self contents])
        {
            if (OSPCoordinateRectIntersectsRect([object bounds], searchBounds))
            {
                CFSetAddValue(set, (__bridge const void *)object);
            }
        }
        [[self readLock] unlock];
        
        if ([self hasChildMaps])
        {
            for (int i = 0; i < 4; i++)
            {
                [children[i] addObjectsInBounds:searchBounds toSet:set];
            }
        }
    }
}

- (OSPNode *)nodeWithId:(NSInteger)nodeId
{
    return (OSPNode *)[self apiObjectOfType:OSPMemberTypeNode withId:nodeId];
}

- (OSPWay *)wayWithId:(NSInteger)wayId
{
    return (OSPWay *)[self apiObjectOfType:OSPMemberTypeWay withId:wayId];
}

- (OSPRelation *)relationWithId:(NSInteger)relationId
{
    return (OSPRelation *)[self apiObjectOfType:OSPMemberTypeRelation withId:relationId];
}

- (OSPAPIObject *)apiObjectOfType:(OSPMemberType)type withId:(NSInteger)objectId
{
    return [self apiObjectMatchingReference:[OSPAPIObjectReference apiObjectReferenceWithType:type identity:objectId]];
}

- (OSPAPIObject *)apiObjectMatchingReference:(OSPAPIObjectReference *)ref
{
    if ([self isSuperMap])
    {
        return (__bridge OSPAPIObject *)CFSetGetValue([self completeContents], (__bridge const void *)ref);
    }
    else
    {
        OSPAPIObject *apiObject = (__bridge OSPAPIObject *)CFSetGetValue([self completeContents], (__bridge const void *)ref);
        if ([self hasChildMaps])
        {
            for (int i = 0; i < 4 && nil == apiObject; i++)
            {
                apiObject = [children[i] apiObjectMatchingReference:ref];
            }
        }
        return apiObject;
    }
}

@end
