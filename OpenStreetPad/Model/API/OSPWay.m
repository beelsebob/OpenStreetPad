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
    __strong NSMutableArray *nodeObjects;
    BOOL nodeObjectsValid;
    BOOL boundsValid;
    OSPCoordinateRect cachedBounds;
    BOOL centroidValid;
    OSPCoordinate2D cachedCentroid;
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
        centroidValid = NO;
    }
}

- (NSArray *)nodeObjects
{
    @synchronized(self)
    {
        if (!nodeObjectsValid)
        {
            OSPMap *m = [self map];
            nodeObjects = [NSMutableArray arrayWithCapacity:[nodes count]];
            for (NSNumber *nodeId in nodes)
            {
                OSPNode *n = [m nodeWithId:[nodeId integerValue]];
                if (nil != n)
                {
                    [nodeObjects addObject:n];
                }
                else
                {
                    nodeObjects = nil;
                    break;
                }
            }
            if (nil != nodeObjects)
            {
                nodeObjectsValid = YES;
            }
        }
        
        return nodeObjects;
    }
}

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setNodes:[NSArray array]];
        nodeObjects = [NSArray array];
        nodeObjectsValid = YES;
    }
    
    return self;
}

- (void)addNodeWithId:(NSInteger)nodeId
{
    @synchronized(self)
    {
        [nodes addObject:[NSNumber numberWithInteger:nodeId]];
        OSPNode *n = [[self map] nodeWithId:nodeId];
        if (nil != n)
        {
            [nodeObjects addObject:n];
        }
        else
        {
            nodeObjectsValid = NO;
        }
        boundsValid = NO;
        centroidValid = NO;
    }
}

- (OSPCoordinateRect)bounds
{
    if ([[self nodes] count] > 0)
    {
        if (!boundsValid)
        {
            OSPNode *firstNode = [[self nodeObjects] objectAtIndex:0];
            
            cachedBounds = [firstNode bounds];
            for (OSPNode *node in [self nodeObjects])
            {
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

- (OSPCoordinate2D)projectedCentroid
{
    float cx = 0.0f;
    float cy = 0.0f;
    float fs = 0.0f;
    float ox = 0.0f;
    float oy = 0.0f;
    
    NSArray *nodeObjs = [self nodeObjects];
    NSUInteger numNodes = [nodeObjs count];
    if (numNodes >= 2)
    {
        if (!centroidValid)
        {
            OSPNode *node = [nodeObjs objectAtIndex:0];
            OSPCoordinate2D nip = [node projectedLocation];
            ox = nip.x;
            oy = nip.y;
            
            for (node in [[self nodeObjects] subarrayWithRange:NSMakeRange(1, numNodes - 1)])
            {
                OSPCoordinate2D ni1p = [node projectedLocation];
                
                float f = (nip.x - ox) * (ni1p.y - oy) - (ni1p.x - ox) * (nip.y - oy);
                cx += (nip.x + ni1p.x - 2.0f * ox) * f;
                cy += (nip.y + ni1p.y - 2.0f * oy) * f;
                fs += f;
                
                nip = ni1p;
            }
            
            cx = cx / (fs * 3.0f) + ox;
            cy = cy / (fs * 3.0f) + oy;
            
            cachedCentroid = OSPCoordinate2DMake(cx, cy);
        }
        
        return cachedCentroid;
        
    }
    
    return OSPCoordinate2DMake(0.0f, 0.0f);
}

- (OSPMemberType)memberType
{
    return OSPMemberTypeWay;
}

- (NSSet *)childObjects
{
    return [NSSet setWithArray:[self nodeObjects]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Way with highway tag: %@", [[self tags] objectForKey:@"highway"]];
}

@end
