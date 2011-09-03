//
//  OSPMapView.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//

#import "OSPMapView.h"

#import "OSPMapServer.h"

#import "OSPAPIObject.h"
#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPMap.h"

@interface OSPMapView () <OSPMapServerDelegate>

@property (readwrite, strong) OSPMapServer *server;

- (void)renderWay:(OSPWay *)way inContext:(CGContextRef)ctx;

@end

@implementation OSPMapView

@synthesize server;
@synthesize mapArea;

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame serverURL:[NSURL URLWithString:@"http://api.openstreetmap.org"] mapBounds:OSPMapAreaMake(OSPCoordinate2DMake(0.5, 0.5), 16.0)];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (nil != self)
    {
        [self setServer:[OSPMapServer serverWithURL:[NSURL URLWithString:@"http://api.openstreetmap.org"]]];
        [self setMapArea:OSPMapAreaMake(OSPCoordinate2DMake(0.4908, 0.303), 16.0)];
        [self setContentSize:CGSizeApplyAffineTransform([self bounds].size, CGAffineTransformMakeScale(2.0, 2.0))];
        [self setDelegate:self];
        [[self server] setDelegate:self];
        [[self server] loadObjectsInBounds:OSPRectForMapAreaInRect([self mapArea], [self bounds])];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame serverURL:(NSURL *)serverURL mapBounds:(OSPMapArea)initMapArea
{
    self = [super initWithFrame:frame];
    
    if (nil != self)
    {
        [self setServer:[OSPMapServer serverWithURL:serverURL]];
        [self setMapArea:initMapArea];
        [[self server] setDelegate:self];
        [[self server] loadObjectsInBounds:OSPRectForMapAreaInRect([self mapArea], [self bounds])];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    NSLog(@"%@", NSStringFromCGPoint([self contentOffset]));
    
    OSPCoordinateRect r = OSPRectForMapAreaInRect([self mapArea], [self bounds]);
    
    CGFloat scale = [self bounds].size.width / r.size.x;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(ctx, scale, scale);
    CGContextSetLineWidth(ctx, 2.0 / scale);
    CGContextTranslateCTM(ctx, -r.origin.x, -r.origin.y);
        
    NSSet *objects = [[self server] objectsInBounds:r];
    
    for (OSPAPIObject *object in objects)
    {
        if ([object isKindOfClass:[OSPWay class]])
        {
            [self renderWay:(OSPWay *)object inContext:ctx];
        }
    }
}

- (void)renderWay:(OSPWay *)way inContext:(CGContextRef)ctx
{
    NSArray *nodes = [way nodes];
    if ([nodes count] > 1)
    {
        OSPMap *m = [way map];
        NSNumber *firstNodeId = [nodes objectAtIndex:0];
        OSPNode *firstNode = [m nodeWithId:[firstNodeId integerValue]];
        OSPCoordinate2D l = [firstNode projectedLocation];
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, l.x, l.y);
        for (NSNumber *nodeId in [nodes subarrayWithRange:NSMakeRange(1, [nodes count] - 1)])
        {
            OSPNode *node = [m nodeWithId:[nodeId integerValue]];
            OSPCoordinate2D nl = [node projectedLocation];
            CGContextAddLineToPoint(ctx, nl.x, nl.y);
        }
        CGContextStrokePath(ctx);
    }
}

- (void)mapServerDidLoadObjects:(OSPMapServer *)mapServer
{
    [self setNeedsDisplay];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self setNeedsDisplay];
}

@end
