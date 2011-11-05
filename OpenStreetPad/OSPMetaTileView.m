//
//  OSPMetaTileView.m
//  OpenStreetPad
//
//  Created by Tom Davie on 04/09/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMetaTileView.h"

#import <QuartzCore/QuartzCore.h>

#import "OSPAPIObject.h"
#import "OSPWay.h"
#import "OSPNode.h"
#import "OSPMap.h"

@interface OSPMetaTileView ()

- (void)renderWay:(OSPWay *)way inContext:(CGContextRef)ctx;

@end

@implementation OSPMetaTileView

@synthesize server;
@synthesize mapArea;

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    CGRect b = [layer bounds];
    OSPCoordinateRect r = OSPRectForMapAreaInRect([self mapArea], b);
    CGRect clipBounds = CGContextGetClipBoundingBox(ctx);
    OSPCoordinateRect dataRect = OSPCoordinateRectMake(r.origin.x + r.size.x * (clipBounds.origin.x - b.origin.x) / b.size.width,
                                                       r.origin.y + r.size.y * (clipBounds.origin.y - b.origin.y) / b.size.height,
                                                       r.size.x * clipBounds.size.width / b.size.width,
                                                       r.size.y * clipBounds.size.height / b.size.height);
    
    CGFloat scale = b.size.width / r.size.x;
    
    CGContextSetFillColorWithColor(ctx, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(ctx, clipBounds);
    
    CGContextScaleCTM(ctx, scale, scale);
    CGContextSetLineWidth(ctx, 2.0 / scale);
    CGContextTranslateCTM(ctx, -r.origin.x, -r.origin.y);
    
    NSSet *objects = [[self server] objectsInBounds:dataRect];
    
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

- (void)setNeedsDisplayInMapArea:(OSPCoordinateRect)area
{
    CGRect b = [self bounds];
    OSPCoordinateRect r = OSPRectForMapAreaInRect([self mapArea], b);
    CGFloat scale = b.size.width / r.size.x;
    
    CGAffineTransform t = CGAffineTransformMakeScale(scale, scale);
    t = CGAffineTransformTranslate(t, -r.origin.x, -r.origin.y);
    
    [self setNeedsDisplayInRect:CGRectApplyAffineTransform(CGRectMake(area.origin.x, area.origin.y, area.size.x, area.size.y), t)];
}

@end
