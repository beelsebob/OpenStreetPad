//
//  OSPNonRectangularArea.m
//  OpenStreetPad
//
//  Created by Tom Davie on 04/09/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPNonRectangularArea.h"

#import "OSPValue.h"

@interface OSPNonRectangularArea ()

@property (readwrite,strong,nonatomic) NSMutableArray *rects;

@end

@implementation OSPNonRectangularArea

@synthesize rects;

+ (id)emptyArea
{
    return [[self alloc] init];
}

- (id)init
{
    return [self initWithRects:@[]];
}

+ (id)areaWithRects:(NSArray *)rects
{
    return [[self alloc] initWithRects:rects];
}

- (id)initWithRects:(NSArray *)initRects;
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRects:[initRects mutableCopy]];
    }
    
    return self;
}

- (NSArray *)allRects
{
    return [self rects];
}

- (void)addRect:(OSPCoordinateRect)rect
{
    [[self rects] addObject:[OSPValue valueWithRect:rect]];
}

- (OSPNonRectangularArea *)areaBySubtractingArea:(OSPNonRectangularArea *)other
{
    NSArray *currentArea = [self rects];
    
    for (OSPValue *subtractionRectValue in [other rects])
    {
        OSPCoordinateRect subtractionRect = [subtractionRectValue rectValue];
        NSMutableArray *newCurrentArea = [NSMutableArray array];
        for (OSPValue *r in currentArea)
        {
            NSArray *subtractedRects = OSPCoordinateRectSubtract([r rectValue], subtractionRect);
            [newCurrentArea addObjectsFromArray:subtractedRects];
        }
        currentArea = newCurrentArea;
    }
    
    return [OSPNonRectangularArea areaWithRects:currentArea];
}

@end
