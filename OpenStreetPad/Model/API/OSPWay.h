//
//  OSPWay.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPAPIObject.h"

@interface OSPWay : OSPAPIObject

@property (readwrite,strong,nonatomic) NSArray *nodes;
@property (readonly) NSArray *nodeObjects;

- (void)addNodeWithId:(NSInteger)nodeId;

- (OSPCoordinate2D)projectedCentroid;

- (double)length;
- (double)textOffsetForTextWidth:(double)width;
- (OSPCoordinate2D)positionOnWayWithOffset:(double)xOffset heightAboveWay:(double)yOffset backwards:(BOOL)backwards;

@end
