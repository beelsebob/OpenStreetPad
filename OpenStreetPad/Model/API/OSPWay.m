//
//  OSPWay.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//

#import "OSPWay.h"

#import "OSPNode.h"
#import "OSPMap.h"

@implementation OSPWay
{
    __strong NSMutableArray *nodes;
    BOOL boundsValid;
    OSPCoordinateRect cachedBounds;
}

- (NSArray *)nodes
{
    @synchronized(self)
    {
        return nodes;
    }
}

- (void)setNodes:(NSArray *)newNodes
{
    @synchronized(self)
    {
        nodes = [newNodes mutableCopy];
        boundsValid = NO;
    }
}

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setNodes:[NSArray array]];
    }
    
    return self;
}

- (void)addNodeWithId:(NSInteger)nodeId
{
    [nodes addObject:[NSNumber numberWithInteger:nodeId]];
    boundsValid = NO;
}

- (OSPCoordinateRect)bounds
{
    if ([[self nodes] count] > 0)
    {
        if (!boundsValid)
        {
            OSPMap *m = [self map];
            NSNumber *firstNodeId = [[self nodes] objectAtIndex:0];
            OSPNode *firstNode = [m nodeWithId:[firstNodeId integerValue]];
            
            cachedBounds = [firstNode bounds];
            for (NSNumber *nodeId in [self nodes])
            {
                OSPNode *node = [m nodeWithId:[nodeId integerValue]];
                cachedBounds = OSPCoordinateRectUnion(cachedBounds, [node bounds]);
            }
            boundsValid = YES;
        }
        return cachedBounds;
    }
    else
    {
        return OSPCoordinateRectZero;
    }
}

- (OSPMemberType)memberType
{
    return OSPMemberTypeWay;
}

@end
