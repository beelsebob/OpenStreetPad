//
//  OSPNode.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//

#import "OSPNode.h"

@interface OSPNode ()

@property (nonatomic,readwrite,assign) OSPCoordinate2D projectedLocation;

@end

@implementation OSPNode

@synthesize location;
@synthesize projectedLocation;

- (void)setLocation:(CLLocationCoordinate2D)newLocation
{
    location = newLocation;
    [self setProjectedLocation:OSPCoordinate2DProjectLocation(newLocation)];
}

- (OSPCoordinateRect)bounds
{
    return OSPCoordinateRectMake(projectedLocation.x, projectedLocation.y, 0.0, 0.0);
}

- (OSPMemberType)memberType
{
    return OSPMemberTypeNode;
}

@end
