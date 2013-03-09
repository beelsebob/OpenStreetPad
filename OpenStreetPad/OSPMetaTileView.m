//
//  OSPMetaTileView.m
//  OpenStreetPad
//
//  Created by Tom Davie on 04/09/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMetaTileView.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

#import "OSPAPIObject.h"
#import "OSPWay.h"
#import "OSPNode.h"
#import "OSPMap.h"

#import "OSPMapCSSSpecifierList.h"
#import "OSPMapCSSSpecifier.h"
#import "OSPMapCSSSizeSpecifier.h"
#import "OSPMapCSSColourSpecifier.h"
#import "OSPMapCSSNamedSpecifier.h"
#import "OSPMapCSSSize.h"
#import "OSPMapCSSURLSpecifier.h"

#import "OSPMapCSSStyledObject.h"

#import "UIColor+CSS.h"

void patternCallback(void *info, CGContextRef ctx);

@interface OSPMetaTileView ()

- (NSDictionary *)sortedObjects:(NSArray *)objects;

- (UIColor *)colourWithColourSpecifierList:(OSPMapCSSSpecifierList *)colour opacitySpecifierList:(OSPMapCSSSpecifierList *)opacity;
- (UIImage *)imageWithSpecifierList:(OSPMapCSSSpecifierList *)spec;

- (CGPathRef)createPathForWay:(OSPWay *)way;
- (CTFontRef)createFontWithStyle:(NSDictionary *)style scaledVariant:(CTFontRef *)scaledFont atScale:(CGFloat)scale;
- (NSString *)applyTextTransform:(NSDictionary *)style toString:(NSString *)str;

- (void)renderLayers:(NSDictionary *)layers inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;

- (void)renderWayFills:(NSArray *)ways inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderWayCasings:(NSArray *)ways inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderLayerObjects:(NSArray *)layer inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderLayerLabels:(NSArray *)layer inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;

- (void)renderWayFill:(OSPMapCSSStyledObject *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderWay:(OSPMapCSSStyledObject *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderCasing:(OSPMapCSSStyledObject *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderNode:(OSPMapCSSStyledObject *)node inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderObjectAtCentroid:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderObject:(OSPMapCSSStyledObject *)obj atPoint:(OSPCoordinate2D)loc inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;

- (void)renderWayLabel:(OSPMapCSSStyledObject *)styledWay inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderNodeLabel:(OSPMapCSSStyledObject *)styledWay inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;

- (void)drawText:(NSString *)text atPoint:(CGPoint)textPosition inContext:(CGContextRef)ctx withStyle:(NSDictionary *)style scaleMultiplier:(CGFloat)scale;
- (void)drawText:(NSString *)text onWay:(OSPWay *)textWay inContext:(CGContextRef)ctx withStyle:(NSDictionary *)style scaleMultiplier:(CGFloat)scale;

@end

CGLineCap CGLineCapFromNSString(NSString *s);
CGLineJoin CGLineJoinFromNSString(NSString *s);

CGLineCap CGLineCapFromNSString(NSString *s)
{
    if ([s isEqualToString:@"round"])
    {
        return kCGLineCapRound;
    }
    else if ([s isEqualToString:@"square"])
    {
        return kCGLineCapSquare;
    }
    else
    {
        return kCGLineCapButt;
    }
}

CGLineJoin CGLineJoinFromNSString(NSString *s)
{
    if ([s isEqualToString:@"bevel"])
    {
        return kCGLineJoinBevel;
    }
    else if ([s isEqualToString:@"miter"])
    {
        return kCGLineJoinMiter;
    }
    else
    {
        return kCGLineJoinRound;
    }
}

@implementation OSPMetaTileView

@synthesize dataSource;
@synthesize mapArea;

@synthesize stylesheet;

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    CGRect b = [layer bounds];
    OSPCoordinateRect r = OSPRectForMapAreaInRect([self mapArea], b);
    CGRect clipBounds = CGContextGetClipBoundingBox(ctx);
    CGFloat width = r.size.x * clipBounds.size.width / b.size.width;
    CGFloat height = r.size.y * clipBounds.size.height / b.size.height;
    OSPCoordinateRect dataRect = OSPCoordinateRectMake(r.origin.x + r.size.x * (clipBounds.origin.x - b.origin.x) / b.size.width - width * 0.125,
                                                       r.origin.y + r.size.y * (clipBounds.origin.y - b.origin.y) / b.size.height - height * 0.125,
                                                       width * 1.25,
                                                       height * 1.25);
    
    CGFloat scale = b.size.width / r.size.x;
    CGFloat oneOverScale = 1.0f / scale;
    
    NSDictionary *canvasStyle = [[self stylesheet] styleForCanvasAtZoom:[self mapArea].zoomLevel];
    UIColor *c = [self colourWithColourSpecifierList:[canvasStyle objectForKey:@"fill-color"] opacitySpecifierList:[canvasStyle objectForKey:@"fill-opacity"]];
    UIImage *fillImage = [self imageWithSpecifierList:[canvasStyle objectForKey:@"fill-image"]];
    if (nil != fillImage)
    {
        CGSize s = [fillImage size];
        CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);
        CGContextSetFillColorSpace(ctx, patternSpace);
        CGColorSpaceRelease(patternSpace);
        static const CGPatternCallbacks callbacks = { 0, &patternCallback, NULL };
        CGPatternRef pat = CGPatternCreate((__bridge void *)@{
                                           @"I" : fillImage,
                                           @"s" : [NSValue valueWithCGSize:s]},
                                           CGRectMake(0.0f, 0.0f, s.width, s.height),
                                           CGAffineTransformMakeScale(1.0, -1.0),
                                           s.width,
                                           s.height,
                                           kCGPatternTilingNoDistortion,
                                           true,
                                           &callbacks);
        CGFloat alpha = 1;
        CGContextSetFillPattern(ctx, pat, &alpha);
        CGPatternRelease(pat);
    }
    if (nil != c)
    {
        CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB();
        CGContextSetFillColorSpace(ctx, rgbSpace);
        CGColorSpaceRelease(rgbSpace);
        CGContextSetFillColorWithColor(ctx, [c CGColor]);
    }
    else
    {
        CGContextSetFillColorWithColor(ctx, [[UIColor colorWithRed:0.95f green:0.95f blue:0.85f alpha:1.0f] CGColor]);
    }
    CGContextFillRect(ctx, clipBounds);
    
    CGContextScaleCTM(ctx, scale, scale);
    CGContextSetLineWidth(ctx, 2.0 * oneOverScale);
    CGContextTranslateCTM(ctx, -r.origin.x, -r.origin.y);
    CGContextSetTextMatrix(ctx, CGAffineTransformMakeScale(1.0f, -1.0f));
    
    NSSet *objects = [[self dataSource] objectsInBounds:dataRect];
//    NSSet *seaAreas = [self seaAreasFromObjects:objects rect:dataRect];
    NSArray *styledObjects = [[self stylesheet] styledObjects:objects/*[objects setByAddingObjectsFromSet:seaAreas]*/ atZoom:[self mapArea].zoomLevel];
    [self renderLayers:[self sortedObjects:styledObjects] inContext:ctx withScaleMultiplier:oneOverScale];
}

/*- (NSSet *)seaAreasFromObjects:(NSSet *)objects rect:(OSPCoordinateRect)r
{
    NSMutableArray *segments = [NSMutableArray array];
    for (OSPAPIObject *obj in objects)
    {
        if ([obj memberType] == OSPMemberTypeWay && [[[obj tags] objectForKey:@"natural"] isEqualToString:@"coastline"] && [[(OSPWay *)obj nodes] count] > 0)
        {
            [segments addObject:obj];
        }
    }
    
    NSMutableArray *realSegments = [NSMutableArray array];
    while ([segments count] > 0)
    {
        OSPWay *obj = [segments lastObject];
        OSPWay *constructedWay = [obj wayByCopyingTagsAndNodes];
        [segments removeLastObject];
        
        BOOL didFindMoreWay = NO;
        do
        {
            NSUInteger candidateIndex = 0;
            for (OSPWay *candidate in segments)
            {
                if ([[[candidate nodes] lastObject] isEqualToNumber:[[obj nodes] objectAtIndex:0]])
                {
                    [constructedWay addNodesFromArray:[[candidate nodes] subarrayWithRange:NSMakeRange(1, [[candidate nodes] count] - 1)]];
                    didFindMoreWay = YES;
                    break;
                }
                if ([[[candidate nodes] objectAtIndex:0] isEqualToNumber:[[obj nodes] lastObject]])
                {
                    [constructedWay prependNodesFromArray:[[candidate nodes] subarrayWithRange:NSMakeRange(0, [[candidate nodes] count] - 1)]];
                    didFindMoreWay = YES;
                    break;
                }
                candidateIndex++;
            }
            if (didFindMoreWay)
            {
                [segments removeObjectAtIndex:candidateIndex];
            }
            didFindMoreWay = NO;
        }
        while (didFindMoreWay);
        
        [realSegments addObject:constructedWay];
    }
}*/

- (UIColor *)colourWithColourSpecifierList:(OSPMapCSSSpecifierList *)colour opacitySpecifierList:(OSPMapCSSSpecifierList *)opacity
{
    UIColor *c = [[[colour specifiers] objectAtIndex:0] colourValue];
    OSPMapCSSSize *op = [[[opacity specifiers] objectAtIndex:0] sizeValue];
    
    if (nil != c && nil != opacity)
    {
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        [c getRed:&red green:&green blue:&blue alpha:&alpha];
        alpha = [op value];
        c = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }
    
    return c;
}

- (NSDictionary *)sortedObjects:(NSArray *)objects
{
    NSMutableDictionary *layers = [NSMutableDictionary dictionaryWithCapacity:5];
    for (OSPMapCSSStyledObject *object in objects)
    {
        NSNumber *layerNumber = [NSNumber numberWithInt:[[[[object object] tags] objectForKey:@"layer"] intValue]];
        NSMutableArray *layer = [layers objectForKey:layerNumber];
        if (nil == layer)
        {
            layer = [NSMutableArray array];
            [layers setObject:layer forKey:layerNumber];
        }
        [layer addObject:object];
    }
    for (NSNumber *layerNumber in [layers copy])
    {
        NSArray *layerObjects = [layers objectForKey:layerNumber];
        [layers setObject:[layerObjects sortedArrayUsingComparator:^ NSComparisonResult (OSPMapCSSStyledObject *o1, OSPMapCSSStyledObject *o2)
                           {
                               float z1 = [[[[[[o1 style] objectForKey:@"z-index"] specifiers] objectAtIndex:0] sizeValue] value];
                               float z2 = [[[[[[o2 style] objectForKey:@"z-index"] specifiers] objectAtIndex:0] sizeValue] value];
                               
                               return z1 > z2 ? NSOrderedDescending : z1 < z2 ? NSOrderedAscending : NSOrderedSame;
                           }]
                   forKey:layerNumber];
    }
    
    return layers;
}

- (void)renderLayers:(NSDictionary *)layers inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    for (NSNumber *layerNumber in [[layers allKeys] sortedArrayUsingSelector:@selector(compare:)])
    {
        NSArray *layer = [layers objectForKey:layerNumber];
        
        NSMutableArray *ways         = [NSMutableArray arrayWithCapacity:[layer count]];
        NSMutableArray *nodesAndWays = [NSMutableArray arrayWithCapacity:[layer count]];
        for (OSPMapCSSStyledObject *styledObject in layer)
        {
            switch ([[styledObject object] memberType])
            {
                case OSPMemberTypeWay:
                    [ways addObject:styledObject];
                case OSPMemberTypeNode:
                    [nodesAndWays addObject:styledObject];
                    break;
                default:
                    break;
            }
        }
        
        [self renderWayFills:  ways inContext:ctx withScaleMultiplier:scale];
        [self renderWayCasings:ways inContext:ctx withScaleMultiplier:scale];
        [self renderLayerObjects:nodesAndWays inContext:ctx withScaleMultiplier:scale];
        [self renderLayerLabels: nodesAndWays inContext:ctx withScaleMultiplier:scale];
    }
}

- (void)renderWayFills:(NSArray *)ways inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    for (OSPMapCSSStyledObject *styledObject in ways)
    {
        [self renderWayFill:styledObject inContext:ctx withScaleMultiplier:scale];
    }
}

- (void)renderWayCasings:(NSArray *)ways inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    for (OSPMapCSSStyledObject *styledObject in ways)
    {
        [self renderCasing:styledObject inContext:ctx withScaleMultiplier:scale];
    }
}

- (void)renderLayerObjects:(NSArray *)layer inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    for (OSPMapCSSStyledObject *styledObject in layer)
    {
        switch ([[styledObject object] memberType])
        {
            case OSPMemberTypeWay:
                [self renderWay:styledObject inContext:ctx withScaleMultiplier:scale];
                break;
            case OSPMemberTypeNode:
                [self renderNode:styledObject inContext:ctx withScaleMultiplier:scale];
                break;
            default:
                break;
        }
    }
}

- (void)renderLayerLabels:(NSArray *)layer inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    for (OSPMapCSSStyledObject *styledObject in layer)
    {
        switch ([[styledObject object] memberType])
        {
            case OSPMemberTypeWay:
                [self renderWayLabel:styledObject inContext:ctx withScaleMultiplier:scale];
                break;
            case OSPMemberTypeNode:
                [self renderNodeLabel:styledObject inContext:ctx withScaleMultiplier:scale];
                break;
            default:
                break;
        }
    }
}

- (void)renderWayFill:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    OSPWay *way = (OSPWay *)[object object];
    NSArray *nodes = [way nodeObjects];
    
    UIColor *fillColour = [self colourWithColourSpecifierList:[style objectForKey:@"fill-color"] opacitySpecifierList:[style objectForKey:@"fill-opacity"]];
    UIImage *fillImage = [self imageWithSpecifierList:[style objectForKey:@"fill-image"]];
    
    BOOL fillValid = fillColour != nil || fillImage != nil;
    
    if (fillValid && [nodes count] > 1)
    {
        CGPathRef path = [self createPathForWay:way];
        CGContextAddPath(ctx, path);
        
        if (fillColour != nil)
        {
            CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB();
            CGContextSetFillColorSpace(ctx, rgbSpace);
            CGColorSpaceRelease(rgbSpace);
            CGContextSetFillColorWithColor(ctx, [fillColour CGColor]);
        }
        else
        {
            CGSize s = [fillImage size];
            CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);
            CGContextSetFillColorSpace(ctx, patternSpace);
            CGColorSpaceRelease(patternSpace);
            static const CGPatternCallbacks callbacks = { 0, &patternCallback, NULL };
            CGPatternRef pat = CGPatternCreate((__bridge void *)@{
                                               @"I" : fillImage,
                                               @"s" : [NSValue valueWithCGSize:s]},
                                               CGRectMake(0.0f, 0.0f, s.width, s.height),
                                               CGAffineTransformMakeScale(1.0, -1.0),
                                               s.width,
                                               s.height,
                                               kCGPatternTilingNoDistortion,
                                               true,
                                               &callbacks);
            CGFloat alpha = 1;
            CGContextSetFillPattern(ctx, pat, &alpha);
            CGPatternRelease(pat);
        }
        CGContextFillPath(ctx);
        
        CFRelease(path);
    }
}

- (CGPathRef)createPathForWay:(OSPWay *)way
{
    NSArray *nodes = [way nodeObjects];
    
    OSPNode *firstNode = [nodes objectAtIndex:0];
    OSPCoordinate2D l = [firstNode projectedLocation];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, l.x, l.y);
    for (OSPNode *node in [nodes subarrayWithRange:NSMakeRange(1, [nodes count] - 1)])
    {
        OSPCoordinate2D nl = [node projectedLocation];
        CGPathAddLineToPoint(path, NULL, nl.x, nl.y);
    }
    
    return path;
}

- (void)renderCasing:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    OSPWay *way = (OSPWay *)[object object];
    
    NSArray *nodes = [way nodes];
    OSPMapCSSSize *width = [[[[style objectForKey:@"width"] specifiers] objectAtIndex:0] sizeValue];
    OSPMapCSSSize *casingWidth = [[[[style objectForKey:@"casing-width"] specifiers] objectAtIndex:0] sizeValue];
    
    if ([nodes count] > 1 && nil != width && nil != casingWidth)
    {
        CGPathRef path = [self createPathForWay:way];
        CGContextAddPath(ctx, path);
                
        CGContextSetLineWidth(ctx, ([width value] + [casingWidth value]) * scale);
        UIColor *colour = [self colourWithColourSpecifierList:[style objectForKey:@"casing-color"] opacitySpecifierList:[style objectForKey:@"casing-opacity"]];
        CGContextSetStrokeColorWithColor(ctx, colour == nil ? [[UIColor blackColor] CGColor] : [colour CGColor]);
        NSString *lineCapName = [[[[style objectForKey:@"casing-linecap"] specifiers] objectAtIndex:0] stringValue];
        CGContextSetLineCap(ctx, nil != lineCapName ? CGLineCapFromNSString(lineCapName) : kCGLineCapRound);
        NSString *lineJoinName = [[[[style objectForKey:@"casing-linejoin"] specifiers] objectAtIndex:0] stringValue] ?: [[[[style objectForKey:@"linejoin"] specifiers] objectAtIndex:0] stringValue];
        CGContextSetLineJoin(ctx, nil != lineJoinName ? CGLineJoinFromNSString(lineJoinName) : kCGLineJoinRound);
        
        OSPMapCSSSpecifierList *dashSpec = [style objectForKey:@"casing-dashes"] ?: [style objectForKey:@"dashes"];
        NSArray *dashSpecSpecifiers = [dashSpec specifiers];
        if (nil != dashSpec && [dashSpecSpecifiers count] > 0)
        {
            if ([[dashSpecSpecifiers objectAtIndex:0] isKindOfClass:[OSPMapCSSNamedSpecifier class]])
            {
                CGContextSetLineDash(ctx, 0.0f, NULL, 0);
            }
            else
            {
                CGFloat *dashes = malloc([dashSpecSpecifiers count] * sizeof(CGFloat));
                int i = 0;
                for (OSPMapCSSSizeSpecifier *spec in dashSpecSpecifiers)
                {
                    OSPMapCSSSize *size = [spec sizeValue];
                    if (nil != size)
                    {
                        dashes[i] = [size value] * scale;
                        i++;
                    }
                }
                CGContextSetLineDash(ctx, 0.0f, dashes, i);
                free(dashes);
            }
        }
        else
        {
            CGContextSetLineDash(ctx, 0.0f, NULL, 0);
        }
        
        CGContextStrokePath(ctx);
        CFRelease(path);
    }
}

- (void)renderWay:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    OSPWay *way = (OSPWay *)[object object];
    
    NSArray *nodes = [way nodeObjects];
    OSPMapCSSSize *width = [[[[style objectForKey:@"width"] specifiers] objectAtIndex:0] sizeValue];
    UIImage *strokeImage = [self imageWithSpecifierList:[style objectForKey:@"image"]];
    
    BOOL strokeValid = nil != width;
    
    if ([nodes count] > 1 && strokeValid)
    {
        CGPathRef path = [self createPathForWay:way];
        CGContextAddPath(ctx, path);
        
        CGContextSetLineWidth(ctx, [width value] * scale);
        NSString *lineCapName = [[[[style objectForKey:@"linecap"] specifiers] objectAtIndex:0] stringValue];
        CGContextSetLineCap(ctx, nil != lineCapName ? CGLineCapFromNSString(lineCapName) : kCGLineCapRound);
        NSString *lineJoinName = [[[[style objectForKey:@"linejoin"] specifiers] objectAtIndex:0] stringValue];
        CGContextSetLineJoin(ctx, nil != lineJoinName ? CGLineJoinFromNSString(lineJoinName) : kCGLineJoinRound);
        
        OSPMapCSSSpecifierList *dashSpec = [style objectForKey:@"dashes"];
        NSArray *dashSpecSpecifiers = [dashSpec specifiers];
        if (nil != dashSpec && [dashSpecSpecifiers count] > 0)
        {
            if ([[dashSpecSpecifiers objectAtIndex:0] isKindOfClass:[OSPMapCSSNamedSpecifier class]])
            {
                CGContextSetLineDash(ctx, 0.0f, NULL, 0);
            }
            else
            {
                CGFloat *dashes = malloc([dashSpecSpecifiers count] * sizeof(CGFloat));
                int i = 0;
                for (OSPMapCSSSizeSpecifier *spec in dashSpecSpecifiers)
                {
                    OSPMapCSSSize *size = [spec sizeValue];
                    if (nil != size)
                    {
                        dashes[i] = [size value] * scale;
                        i++;
                    }
                }
                CGContextSetLineDash(ctx, 0.0f, dashes, i);
                free(dashes);
            }
        }
        else
        {
            CGContextSetLineDash(ctx, 0.0f, NULL, 0);
        }
        
        if (nil == strokeImage)
        {
            CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB();
            CGContextSetFillColorSpace(ctx, rgbSpace);
            CGColorSpaceRelease(rgbSpace);
            UIColor *colour = [self colourWithColourSpecifierList:[style objectForKey:@"color"] opacitySpecifierList:[style objectForKey:@"opacity"]];
            CGContextSetStrokeColorWithColor(ctx, colour == nil ? [[UIColor blackColor] CGColor] : [colour CGColor]);
        }
        else
        {
            CGSize s = [strokeImage size];
            CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);
            CGContextSetStrokeColorSpace(ctx, patternSpace);
            CGColorSpaceRelease(patternSpace);
            static const CGPatternCallbacks callbacks = { 0, &patternCallback, NULL };
            CGPatternRef pat = CGPatternCreate((__bridge void *)@{
                                               @"I" : strokeImage,
                                               @"s" : [NSValue valueWithCGSize:s]},
                                               CGRectMake(0.0f, 0.0f, s.width, s.height),
                                               CGAffineTransformMakeScale(1.0, -1.0),
                                               s.width,
                                               s.height,
                                               kCGPatternTilingNoDistortion,
                                               true,
                                               &callbacks);
            CGFloat alpha = 1;
            CGContextSetStrokePattern(ctx, pat, &alpha);
            CGPatternRelease(pat);
        }
        
        CGContextStrokePath(ctx);
        CGPathRelease(path);
    }
}

- (void)renderNode:(OSPMapCSSStyledObject *)node inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    [self renderObject:node atPoint:[(OSPNode *)[node object] projectedLocation] inContext:ctx withScaleMultiplier:scale];
}

- (void)renderObjectAtCentroid:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    if (nil != [self imageWithSpecifierList:[style objectForKey:@"icon-image"]])
    {
        OSPWay *way = (OSPWay *)[object object];
        OSPCoordinate2D c = [way projectedCentroid];
        [self renderObject:object atPoint:c inContext:ctx withScaleMultiplier:scale];
    }
}

- (void)renderObject:(OSPMapCSSStyledObject *)object atPoint:(OSPCoordinate2D)loc inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    
    UIImage *image = [self imageWithSpecifierList:[style objectForKey:@"icon-image"]];
    if (nil != image)
    {
        OSPMapCSSSize *opacity = [[[[style objectForKey:@"icon-opacity"] specifiers] objectAtIndex:0] sizeValue];
        CGContextSaveGState(ctx);
        CGContextSetAlpha(ctx, nil == opacity ? 1.0f : [opacity value]);
        OSPMapCSSSize *widthSize = [[[[style objectForKey:@"icon-width"] specifiers] objectAtIndex:0] sizeValue];
        OSPMapCSSSize *heightSize = [[[[style objectForKey:@"icon-height"] specifiers] objectAtIndex:0] sizeValue];
        
        CGFloat width = [image size].width;
        CGFloat height = [image size].height;
        
        if (nil != widthSize)
        {
            width = [widthSize unit] == OSPMapCSSUnitPercent ? width * [widthSize value] * 0.01f : [widthSize value];
        }
        if (nil != heightSize)
        {
            height = [heightSize unit] == OSPMapCSSUnitPercent ? height * [heightSize value] * 0.01f : [heightSize value];
        }
        width *= scale;
        height *= scale;
        
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextDrawImage(ctx, CGRectMake(loc.x - width * 0.5f, -loc.y - height * 0.5f, width, height), [image CGImage]);
        CGContextRestoreGState(ctx);
    }
}

- (void)renderWayLabel:(OSPMapCSSStyledObject *)styledWay inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    [self renderObjectAtCentroid:styledWay inContext:ctx withScaleMultiplier:scale];
    
    NSDictionary *style = [styledWay style];
    OSPWay *way = (OSPWay *)[styledWay object];
    
    NSString *untransformedTitle = [[[[style objectForKey:@"text"] specifiers] objectAtIndex:0] stringValue];
    NSString *title = [self applyTextTransform:style toString:untransformedTitle];
    
    if (nil != title)
    {
        NSString *position = [[[[style objectForKey:@"text-position"] specifiers] objectAtIndex:0] stringValue];
        position = position ?: @"center";
        
        if ([position isEqualToString:@"line"])
        {
            [self drawText:title onWay:way inContext:ctx withStyle:style scaleMultiplier:scale];
        }
        else if ([position isEqualToString:@"center"])
        {
            OSPCoordinate2D c = [way projectedCentroid];
            CGPoint textPosition = CGPointMake(c.x, c.y);
            
            [self drawText:title atPoint:textPosition inContext:ctx withStyle:style scaleMultiplier:scale];
        }
    }
}

- (void)renderNodeLabel:(OSPMapCSSStyledObject *)styledNode inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [styledNode style];
    OSPNode *node = (OSPNode *)[styledNode object];
    
    NSString *untransformedTitle = [[[[style objectForKey:@"text"] specifiers] objectAtIndex:0] stringValue];
    NSString *title = [self applyTextTransform:style toString:untransformedTitle];
    
    if (nil != title)
    {
        OSPCoordinate2D c = [node projectedLocation];
        CGPoint textPosition = CGPointMake(c.x, c.y);
        
        [self drawText:title atPoint:textPosition inContext:ctx withStyle:style scaleMultiplier:scale];
    }
}

- (NSString *)applyTextTransform:(NSDictionary *)style toString:(NSString *)str
{
    NSString *textTransform = [[[[style objectForKey:@"text-transform"] specifiers] objectAtIndex:0] stringValue];
    if ([textTransform isEqualToString:@"uppercase"])
    {
        return [str uppercaseString];
    }
    else if ([textTransform isEqualToString:@"lowercase"])
    {
        return [str lowercaseString];
    }
    else if ([textTransform isEqualToString:@"capitalize"])
    {
        return [str capitalizedString];
    }
    return str;
}

- (void)drawText:(NSString *)text atPoint:(CGPoint)textPosition inContext:(CGContextRef)ctx withStyle:(NSDictionary *)style scaleMultiplier:(CGFloat)scale
{
    CTFontRef scaledFont = nil;
    CTFontRef font = [self createFontWithStyle:style scaledVariant:&scaledFont atScale:scale];
    
    OSPMapCSSSize *haloSize = [[[[style objectForKey:@"text-halo-radius"] specifiers] objectAtIndex:0] sizeValue];
    CGFloat haloRadius = nil == haloSize ? 0.0f : [haloSize value];
    BOOL hasHalo = haloRadius != 0.0f;
    
    CGFloat lineHeight = CTFontGetAscent(scaledFont) + CTFontGetDescent(scaledFont) + CTFontGetLeading(scaledFont) + haloRadius * scale;
    
    UIColor *haloColour = [self colourWithColourSpecifierList:[style objectForKey:@"text-halo-color"] opacitySpecifierList:[style objectForKey:@"text-halo-opacity"]];
    UIColor *colour = [self colourWithColourSpecifierList:[style objectForKey:@"text-color"] opacitySpecifierList:[style objectForKey:@"text-opacity"]];
    
    OSPMapCSSSize *vOffsetSize = [[[[style objectForKey:@"text-offset"] specifiers] objectAtIndex:0] sizeValue];
    CGFloat offset = nil == vOffsetSize ? 0.0f : [vOffsetSize value];
    CGFloat scaledOffset = offset * scale;
    
    OSPMapCSSSize *widthSize = [[[[style objectForKey:@"max-width"] specifiers] objectAtIndex:0] sizeValue];
    CGFloat width = nil == widthSize ? 256.0f : [widthSize value];
    
    CGFloat scaledWidth = width * scale;
    
    textPosition.y += scaledOffset;
    
    const CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    const CTParagraphStyleSetting paragraphStyleSettings[] = {{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(lineBreakMode), .value = &lineBreakMode}};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyleSettings, sizeof(paragraphStyleSettings) / sizeof(paragraphStyleSettings[0]));
    NSDictionary *attributes = @{(__bridge NSString *)kCTFontAttributeName           : (__bridge id)font,
                                 (__bridge NSString *)kCTParagraphStyleAttributeName : (__bridge id)paragraphStyle};
    NSMutableDictionary *scaledAttributes = [@{(__bridge NSString *)kCTFontAttributeName                       : (__bridge id)scaledFont,
                                               (__bridge NSString *)kCTForegroundColorFromContextAttributeName : (__bridge NSNumber *)kCFBooleanTrue,
                                               (__bridge NSString *)kCTParagraphStyleAttributeName             : (__bridge id)paragraphStyle} mutableCopy];
    CFRelease(paragraphStyle);
    
    CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)text, (__bridge CFDictionaryRef)attributes);
    CFAttributedStringRef scaledAttrString = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)text, (__bridge CFDictionaryRef)scaledAttributes);
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(attrString);
    CTTypesetterRef scaledTypesetter = CTTypesetterCreateWithAttributedString(scaledAttrString);
    CFRelease(attrString);
    CFRelease(scaledAttrString);
    
    NSString *textDecoration = [[[[style objectForKey:@"text-decoration"] specifiers] objectAtIndex:0] stringValue];
    BOOL shouldUnderline = [textDecoration isEqualToString:@"underline"];
    CGFloat halfDescent = CTFontGetDescent(scaledFont) * 0.5f;
    
    CFIndex start = 0;
    CFIndex length = [text length];
    
    CGContextSetTextDrawingMode(ctx, kCGTextFill);
    CGContextSetLineWidth(ctx, haloRadius * 2.0f * scale);
    CGContextSetFillColorWithColor(ctx, [colour CGColor]);
    CGContextSetStrokeColorWithColor(ctx, [haloColour CGColor]);
    do
    {
        CFIndex count = CTTypesetterSuggestLineBreak(typesetter, start, width);
        
        CTLineRef line = CTTypesetterCreateLine(scaledTypesetter, CFRangeMake(start, count));
        CGFloat penOffset = CTLineGetPenOffsetForFlush(line, 0.5f, scaledWidth);
        CGContextSetTextPosition(ctx, textPosition.x - scaledWidth * 0.5f + penOffset, textPosition.y);
        
        if (hasHalo)
        {
            CGContextSetTextDrawingMode(ctx, kCGTextStroke);
            CTLineDraw(line, ctx);
            CGContextSetTextDrawingMode(ctx, kCGTextFill);
            CGContextSetTextPosition(ctx, textPosition.x - scaledWidth * 0.5f + penOffset, textPosition.y);
        }
        
        if (shouldUnderline)
        {
            CGRect underlineRect = CGRectMake(textPosition.x - scaledWidth * 0.5f + penOffset, textPosition.y + halfDescent, scaledWidth - 2.0f * penOffset, scale);
            CGContextStrokeRect(ctx, underlineRect);
            CGContextFillRect(ctx, underlineRect);
        }
        
        CTLineDraw(line, ctx);
        
        CFRelease(line);
        
        textPosition.y += lineHeight;
        
        start += count;
    }
    while (start < length);
    CFRelease(typesetter);
    CFRelease(scaledTypesetter);
    
    CFRelease(font);
    CFRelease(scaledFont);
}

- (void)drawText:(NSString *)text onWay:(OSPWay *)textWay inContext:(CGContextRef)ctx withStyle:(NSDictionary *)style scaleMultiplier:(CGFloat)scale
{
    CTFontRef scaledFont = nil;
    CTFontRef font = [self createFontWithStyle:style scaledVariant:&scaledFont atScale:scale];
        
    OSPMapCSSSize *haloSize = [[[[style objectForKey:@"text-halo-radius"] specifiers] objectAtIndex:0] sizeValue];
    CGFloat haloRadius = nil == haloSize ? 0.0f : [haloSize value];
    BOOL hasHalo = haloRadius != 0.0f;
    
    UIColor *haloColour = [self colourWithColourSpecifierList:[style objectForKey:@"text-halo-color"] opacitySpecifierList:[style objectForKey:@"text-halo-opacity"]];
    UIColor *colour = [self colourWithColourSpecifierList:[style objectForKey:@"text-color"] opacitySpecifierList:[style objectForKey:@"text-opacity"]];
    
    OSPMapCSSSize *vOffsetSize = [[[[style objectForKey:@"text-offset"] specifiers] objectAtIndex:0] sizeValue];
    CGFloat offset = nil == vOffsetSize ? 0.0f : [vOffsetSize value];
    CGFloat scaledOffset = offset * scale;
    
    NSMutableDictionary *scaledAttributes = [@{(__bridge NSString *)kCTFontAttributeName                       : (__bridge id)scaledFont,
                                               (__bridge NSString *)kCTForegroundColorFromContextAttributeName : (__bridge NSNumber *)kCFBooleanTrue} mutableCopy];
    
    CFAttributedStringRef scaledAttrString = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)text, (__bridge CFDictionaryRef)scaledAttributes);
    CTTypesetterRef scaledTypesetter = CTTypesetterCreateWithAttributedString(scaledAttrString);
    CTLineRef line = CTTypesetterCreateLine(scaledTypesetter, CFRangeMake(0, CFAttributedStringGetLength(scaledAttrString)));
    CFRelease(scaledAttrString);
    
    double lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
    
    CGContextSetLineWidth(ctx, haloRadius * 2.0f * scale);
    CGContextSetFillColorWithColor(ctx, [colour CGColor]);
    CGContextSetStrokeColorWithColor(ctx, [haloColour CGColor]);
    
    CGFontRef gFont = CTFontCopyGraphicsFont(scaledFont, NULL);
    CGContextSetFont(ctx, gFont);
    CGContextSetFontSize(ctx, CTFontGetSize(scaledFont));
    CFRelease(gFont);
    
    CGAffineTransform tm = CGContextGetTextMatrix(ctx);
    
    double wayOffset = [textWay textOffsetForTextWidth:lineWidth];
    if (wayOffset > 0)
    {
        BOOL backwards = [textWay positionOnWayWithOffset:wayOffset heightAboveWay:0.0 backwards:NO].x > [textWay positionOnWayWithOffset:wayOffset + lineWidth heightAboveWay:0.0 backwards:NO].x;
        if (backwards)
        {
            wayOffset = [textWay length] - lineWidth - wayOffset;
        }
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        int numRuns = CFArrayGetCount(runs);
        for (int runNumber = 0; runNumber < numRuns; runNumber++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, runNumber);
            CFDictionaryRef attrs = CTRunGetAttributes(run);
            CTFontRef f = CFDictionaryGetValue(attrs, kCTFontAttributeName);
            if (NULL != f)
            {
                CGFontRef gf = CTFontCopyGraphicsFont(f, NULL);
                CGContextSetFont(ctx, gf);
            }
            CFIndex numGlyphs = CTRunGetGlyphCount(run);
            const CGGlyph *glyphs = CTRunGetGlyphsPtr(run);
            const CGPoint *glyphOffsets = CTRunGetPositionsPtr(run);
            OSPCoordinate2D *glyphPositions = malloc((numGlyphs + 1) * sizeof(OSPCoordinate2D));
            CGFloat *glyphAngles = malloc(numGlyphs * sizeof(CGFloat));
            
            CGPoint currentGlyphOffset;
            for (CFIndex glyphNumber = 0; glyphNumber < numGlyphs; glyphNumber++)
            {
                currentGlyphOffset = glyphOffsets[glyphNumber];
                glyphPositions[glyphNumber] = [textWay positionOnWayWithOffset:wayOffset + currentGlyphOffset.x heightAboveWay:currentGlyphOffset.y - scaledOffset backwards:backwards];
            }
            glyphPositions[numGlyphs] = [textWay positionOnWayWithOffset:wayOffset + lineWidth heightAboveWay:-scaledOffset backwards:backwards];
            OSPCoordinate2D currentGlyphPosition = glyphPositions[0];
            for (CFIndex glyphNumber = 0; glyphNumber < numGlyphs; glyphNumber++)
            {
                OSPCoordinate2D nextGlyphPosition = glyphPositions[glyphNumber+1];
                
                double dx = nextGlyphPosition.x - currentGlyphPosition.x;
                double dy = nextGlyphPosition.y - currentGlyphPosition.y;
                glyphAngles[glyphNumber] = dx > 0.0 ? (dy > 0.0 ? atan(dy / dx) : -atan(-dy / dx))
                : dx < 0.0 ? (dy > 0.0 ? M_PI - atan(dy / -dx) : M_PI + atan(-dy / -dx))
                :            (dy < 0.0 ? 3 * M_PI_2 : M_PI_2);
                
                
                currentGlyphPosition = nextGlyphPosition;
            }
            
            if (hasHalo)
            {
                CGContextSetTextDrawingMode(ctx, kCGTextStroke);
                for (CFIndex glyphNumber = 0; glyphNumber < numGlyphs; glyphNumber++)
                {
                    CGGlyph glyph = glyphs[glyphNumber];
                    OSPCoordinate2D p = glyphPositions[glyphNumber];
                    
                    CGContextSetTextMatrix(ctx, CGAffineTransformConcat(CGAffineTransformMakeRotation(-glyphAngles[glyphNumber]), CGAffineTransformMakeScale(1.0, -1.0)));
                    CGContextSetTextPosition(ctx, p.x, p.y);
                    CGContextShowGlyphs(ctx, &glyph, 1);
                }
            }
            CGContextSetTextDrawingMode(ctx, kCGTextFill);
            for (CFIndex glyphNumber = 0; glyphNumber < numGlyphs; glyphNumber++)
            {
                CGGlyph glyph = glyphs[glyphNumber];
                OSPCoordinate2D p = glyphPositions[glyphNumber];
                
                CGContextSetTextMatrix(ctx, CGAffineTransformConcat(CGAffineTransformMakeRotation(-glyphAngles[glyphNumber]), CGAffineTransformMakeScale(1.0, -1.0)));
                CGContextSetTextPosition(ctx, p.x, p.y);
                CGContextShowGlyphs(ctx, &glyph, 1);
            }
            
            free(glyphPositions);
            free(glyphAngles);
        }
    }
    
    CGContextSetTextMatrix(ctx, tm);
    
    CFRelease(line);
    CFRelease(scaledTypesetter);
    CFRelease(scaledFont);
    CFRelease(font);
}

- (CTFontRef)createFontWithStyle:(NSDictionary *)style scaledVariant:(CTFontRef *)scaledFont atScale:(CGFloat)scale
{
    NSString *fontFamily = [[[[style objectForKey:@"font-family"] specifiers] objectAtIndex:0] stringValue];
    fontFamily = fontFamily ?: @"Helvetica";
    OSPMapCSSSize *fontSizeSpec = [[[[style objectForKey:@"font-size"] specifiers] objectAtIndex:0] sizeValue];
    CGFloat fontSize = nil == fontSizeSpec ? 12.0f : [fontSizeSpec value];
    
    CTFontSymbolicTraits traits = 0x0;
    NSString *fontWeight = [[[[style objectForKey:@"font-weight"] specifiers] objectAtIndex:0] stringValue];
    NSString *fontStyle = [[[[style objectForKey:@"font-style"] specifiers] objectAtIndex:0] stringValue];
    traits |= [fontWeight isEqualToString:@"bold"] ? kCTFontBoldTrait : 0x0;
    traits |= [fontStyle isEqualToString:@"italic"] ? kCTFontItalicTrait : 0x0;
    CTFontSymbolicTraits newTraits = traits;
    
    CTFontRef baseFont = CTFontCreateWithName((__bridge CFStringRef)fontFamily, fontSize, NULL);
    CTFontRef font = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize, NULL, newTraits, newTraits);
    if (NULL == font)
    {
        newTraits &= (0xffffffff ^ kCTFontItalicTrait);
        font = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize, NULL, newTraits, newTraits);
    }
    if (NULL == font)
    {
        newTraits = traits & (0xffffffff ^ kCTFontBoldTrait);
        font = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize, NULL, newTraits, newTraits);
    }
    if (NULL == font)
    {
        newTraits = 0x0;
        font = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize, NULL, newTraits, newTraits);
    }
    *scaledFont = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize * scale, NULL, newTraits, newTraits);
    CFRelease(baseFont);
    
    return font;
}

- (UIImage *)imageWithSpecifierList:(OSPMapCSSSpecifierList *)spec
{
    if (nil != spec)
    {
        OSPMapCSSUrl *u = [[[spec specifiers] objectAtIndex:0] urlValue];
        NSURL *url = [u content];
        NSString *urlString = [url relativeString];
        NSString *ext = [url pathExtension];
        NSString *resName = [[url lastPathComponent] stringByDeletingPathExtension];
        NSString *dir = [urlString stringByDeletingLastPathComponent];
        NSString *path = [[NSBundle mainBundle] pathForResource:resName ofType:ext inDirectory:dir];
        return [UIImage imageWithContentsOfFile:path];
    }
    return nil;
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

void patternCallback(void *info, CGContextRef ctx)
{
    NSDictionary *i = (__bridge NSDictionary *)info;
    UIImage *image = [i objectForKey:@"I"];
    CGSize s = [[i objectForKey:@"s"] CGSizeValue];
    CGImageRef imageRef = [image CGImage];
    CGContextDrawImage(ctx, CGRectMake(0.0f, 0.0f, s.width, s.height), imageRef);
}

