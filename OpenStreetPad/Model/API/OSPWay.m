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

@interface OSPWay ()

- (void)createEdgeLengthsIfNeeded;
- (void)createEdgeLengths;

@end

@implementation OSPWay
{
    __strong NSMutableArray *nodes;
    __strong NSMutableArray *nodeObjects;
    double *edgeLengths;
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
        if (NULL != edgeLengths)
        {
            free(edgeLengths);
            edgeLengths = NULL;
        }
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
        if (NULL != edgeLengths)
        {
            free(edgeLengths);
            edgeLengths = NULL;
        }
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

- (void)createEdgeLengthsIfNeeded
{
    if (NULL == edgeLengths)
    {
        [self createEdgeLengths];
    }
}

- (void)createEdgeLengths
{
    NSArray *ns = [self nodeObjects];
    edgeLengths = malloc(([ns count] - 1) * sizeof(double));
    OSPNode *lastNode = [ns objectAtIndex:0];
    OSPCoordinate2D lastLoc = [lastNode projectedLocation];
    NSUInteger i = 0;
    for (OSPNode *currentNode in [ns subarrayWithRange:NSMakeRange(1, [ns count] - 1)])
    {
        OSPCoordinate2D currentLoc = [currentNode projectedLocation];
        double dx = currentLoc.x - lastLoc.x;
        double dy = currentLoc.y - lastLoc.y;
        edgeLengths[i] = sqrt(dx * dx + dy * dy);
        
        i++;
        lastLoc = currentLoc;
    }
}

- (double)length
{
    [self createEdgeLengthsIfNeeded];
    
    double l = 0.0;
    for (int i = 0; i < [[self nodes] count] - 1; i++)
    {
        l += edgeLengths[i];
    }
    
    return l;
}

- (double)textOffsetForTextWidth:(double)width
{
    [self createEdgeLengthsIfNeeded];
    
    double l = 0.0;
    double wayLength = [self length];
    if (wayLength > width)
    {
        double *sharpCornerPositions = malloc(sizeof(double) * ([[self nodes] count] + 2));
        sharpCornerPositions[0] = 0.0;
        NSUInteger numberOfSharpCorners = 1;
        
        OSPCoordinate2D oneLocBack;
        OSPCoordinate2D twoLocsBack;
        NSUInteger nodesConsumed = 0;
        for (OSPNode *node in [self nodeObjects])
        {
            OSPCoordinate2D nodeLoc = [node projectedLocation];
            if (nodesConsumed >= 2)
            {
                double dx1 = oneLocBack.x - twoLocsBack.x;
                double dy1 = oneLocBack.y - twoLocsBack.y;
                double dx2 = nodeLoc.x - oneLocBack.x;
                double dy2 = nodeLoc.y - oneLocBack.y;
                float lastAngle = dx1 == 0.0 ? (dy1 > 0.0 ? M_PI_2 : 3 * M_PI_2) : atanf(dy1 / dx1);
                float thisAngle = dx2 == 0.0 ? (dx2 > 0.0 ? M_PI_2 : 3 * M_PI_2) : atanf(dy2 / dx2);
                float angleDelta = thisAngle - lastAngle;
                if (fabs(angleDelta > M_PI_2 * 0.3333))
                {
                    sharpCornerPositions[numberOfSharpCorners] = l;
                    numberOfSharpCorners++;
                }
            }
            if (nodesConsumed >= 1)
            {
                l += edgeLengths[nodesConsumed - 1];
            }
            twoLocsBack = oneLocBack;
            oneLocBack = nodeLoc;
            nodesConsumed++;
        }
        sharpCornerPositions[numberOfSharpCorners] = wayLength;
        
        double bestPosition = -1.0;
        double currentPosition = 0.0;
        double idealPosition = (wayLength - width) * 0.5;
        for (NSUInteger gapNumber = 0; gapNumber < numberOfSharpCorners; gapNumber++)
        {
            double currentGapSize = sharpCornerPositions[gapNumber+1] - sharpCornerPositions[gapNumber];
            if (currentGapSize > width)
            {
                double closestToIdealPosition = currentPosition > idealPosition ? currentPosition : (currentPosition + currentGapSize - width < idealPosition ? currentPosition + currentGapSize - width : idealPosition);
                bestPosition = bestPosition < 0.0 ? closestToIdealPosition : (closestToIdealPosition - idealPosition < bestPosition - idealPosition ? closestToIdealPosition : bestPosition);
            }
            currentPosition += currentGapSize;
        }
        free(sharpCornerPositions);
        return bestPosition;
    }
    return -1.0;
}

- (OSPCoordinate2D)positionOnWayWithOffset:(double)xOffset heightAboveWay:(double)yOffset backwards:(BOOL)backwards
{
    [self createEdgeLengthsIfNeeded];
    
    NSArray *ns = [self nodeObjects];
    double lengthSoFar = 0.0;
    int numPoints = [ns count];
    double distanceAlongEdge = 0.0;
    OSPCoordinate2D nextPointLocation = OSPCoordinate2DMake(0.0, 0.0);
    OSPCoordinate2D prevPointLocation = OSPCoordinate2DMake(0.0, 0.0);
    int pointNumber;
    if (backwards)
    {
        pointNumber = numPoints - 2;
        while (lengthSoFar + edgeLengths[pointNumber] < xOffset && pointNumber >= 0)
        {
            lengthSoFar += edgeLengths[pointNumber];
            pointNumber--;
        }
        
        if (pointNumber >= 0)
        {
            distanceAlongEdge = xOffset - lengthSoFar;
            nextPointLocation = [[ns objectAtIndex:pointNumber    ] projectedLocation];
            prevPointLocation = [[ns objectAtIndex:pointNumber + 1] projectedLocation];
        }
    }
    else
    {
        pointNumber = 0;
        while (lengthSoFar + edgeLengths[pointNumber] < xOffset && pointNumber < numPoints)
        {
            lengthSoFar += edgeLengths[pointNumber];
            pointNumber++;
        }
        
        if (pointNumber < numPoints)
        {
            distanceAlongEdge = xOffset - lengthSoFar;
            nextPointLocation = [[ns objectAtIndex:pointNumber + 1] projectedLocation];
            prevPointLocation = [[ns objectAtIndex:pointNumber    ] projectedLocation];
        }
    }
    
    double dx = nextPointLocation.x - prevPointLocation.x;
    double dy = nextPointLocation.y - prevPointLocation.y;
    double prop = distanceAlongEdge / edgeLengths[pointNumber];
    double xCrawl = prop * dx;
    double yCrawl = prop * dy;
    
    return OSPCoordinate2DMake(prevPointLocation.x + xCrawl, prevPointLocation.y + yCrawl);
}

- (CGFloat)angleOnWayWithOffset:(CGFloat)xOffset backwards:(BOOL)backwards
{
    [self createEdgeLengthsIfNeeded];
    
    NSArray *ns = [self nodeObjects];
    CGFloat lengthSoFar = 0.0;
    int numPoints = [ns count];
    OSPCoordinate2D nextPointLocation = OSPCoordinate2DMake(0.0, 0.0);
    OSPCoordinate2D prevPointLocation = OSPCoordinate2DMake(0.0, 0.0);
    if (backwards)
    {
        int pointNumber = numPoints - 2;
        while (lengthSoFar + edgeLengths[pointNumber] < xOffset && pointNumber >= 0)
        {
            lengthSoFar += edgeLengths[pointNumber];
            pointNumber--;
        }
        
        if (pointNumber >= 0)
        {
            nextPointLocation = [[ns objectAtIndex:pointNumber    ] projectedLocation];
            prevPointLocation = [[ns objectAtIndex:pointNumber + 1] projectedLocation];
        }
    }
    else
    {
        int pointNumber = 0;
        while (lengthSoFar + edgeLengths[pointNumber] < xOffset && pointNumber < numPoints)
        {
            lengthSoFar += edgeLengths[pointNumber];
            pointNumber++;
        }
        
        if (pointNumber < numPoints)
        {
            nextPointLocation = [[ns objectAtIndex:pointNumber + 1] projectedLocation];
            prevPointLocation = [[ns objectAtIndex:pointNumber    ] projectedLocation];
        }
    }
    
    CGFloat dx = nextPointLocation.x - prevPointLocation.x;
    CGFloat dy = nextPointLocation.y - prevPointLocation.y;
    
    if (dx > 0.0)
    {
        return dy > 0.0 ? atanf(dy / dx) : -atanf(-dy / dx);
    }
    else if (dx < 0.0)
    {
        return dy > 0.0 ? M_PI - atanf(dy / -dx) : M_PI + atanf(-dy / -dx);
    }
    else
    {
        return dy < 0.0 ? 3 * M_PI_2 : M_PI_2;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Way with highway tag: %@", [[self tags] objectForKey:@"highway"]];
}

@end
