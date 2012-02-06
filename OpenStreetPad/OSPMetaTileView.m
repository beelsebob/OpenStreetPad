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

#import "OSPMapCSSSpecifier.h"
#import "OSPMapCSSSizeListSpecifier.h"
#import "OSPMapCSSColourSpecifier.h"
#import "OSPMapCSSNamedSpecifier.h"
#import "OSPMapCSSSize.h"
#import "OSPMapCSSURLSpecifier.h"

#import "OSPMapCSSStyledObject.h"

#import "UIColor+CSS.h"

void patternCallback(void *info, CGContextRef ctx);

@interface OSPMetaTileView ()

- (NSDictionary *)sortedObjects:(NSArray *)objects;

- (UIColor *)colourWithColourSpecifier:(OSPMapCSSSpecifier *)colour opacitySpecifier:(OSPMapCSSSpecifier *)opacity;
- (UIImage *)imageWithSpecifier:(OSPMapCSSSpecifier *)spec;

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

@synthesize server;
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
    
    NSDictionary *canvasStyle = [[self stylesheet] styleForCanvas];
    UIColor *c = [self colourWithColourSpecifier:[canvasStyle objectForKey:@"fill-color"] opacitySpecifier:[canvasStyle objectForKey:@"fill-opacity"]];
    UIImage *fillImage = [self imageWithSpecifier:[canvasStyle objectForKey:@"fill-image"]];
    if (nil != fillImage)
    {
        CGSize s = [fillImage size];
        CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);
        CGContextSetFillColorSpace(ctx, patternSpace);
        CGColorSpaceRelease(patternSpace);
        static const CGPatternCallbacks callbacks = { 0, &patternCallback, NULL };
        CGPatternRef pat = CGPatternCreate((__bridge void *)[NSDictionary dictionaryWithObjectsAndKeys:fillImage, @"I", [NSValue valueWithCGSize:s], @"s", nil], CGRectMake(0.0f, 0.0f, s.width, s.height), CGAffineTransformMakeScale(1.0, -1.0), s.width, s.height, kCGPatternTilingNoDistortion, true, &callbacks);
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
    
    NSSet *objects = [[self server] objectsInBounds:dataRect];
    
    NSArray *styledObjects = [[self stylesheet] styledObjects:objects];
    [self renderLayers:[self sortedObjects:styledObjects] inContext:ctx withScaleMultiplier:oneOverScale];
}

- (UIColor *)colourWithColourSpecifier:(OSPMapCSSSpecifier *)colour opacitySpecifier:(OSPMapCSSSpecifier *)opacity
{
    UIColor *c = nil;
    if ([colour isKindOfClass:[OSPMapCSSColourSpecifier class]])
    {
        c = [[colour values] objectAtIndex:0];
    }
    else if ([colour isKindOfClass:[OSPMapCSSNamedSpecifier class]])
    {
        NSString *colourName = [[colour values] objectAtIndex:0];
        c = [UIColor colourWithCSSName:colourName];
    }
    
    if (nil != c && [opacity isKindOfClass:[OSPMapCSSSizeListSpecifier class]])
    {
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        [c getRed:&red green:&green blue:&blue alpha:&alpha];
        alpha = [(OSPMapCSSSize *)[[opacity values] objectAtIndex:0] value];
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
                               OSPMapCSSSpecifier *z1s = [[o1 style] objectForKey:@"z-index"];
                               OSPMapCSSSpecifier *z2s = [[o2 style] objectForKey:@"z-index"];
                               id value1 = [[z1s values] objectAtIndex:0];
                               id value2 = [[z2s values] objectAtIndex:0];
                               float z1 = [value1 isKindOfClass:[OSPMapCSSSize class]] ? [(OSPMapCSSSize *)value1 value] : 0.0f;
                               float z2 = [value2 isKindOfClass:[OSPMapCSSSize class]] ? [(OSPMapCSSSize *)value2 value] : 0.0f;
                               
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
    
    UIColor *fillColour = [self colourWithColourSpecifier:[style objectForKey:@"fill-color"] opacitySpecifier:[style objectForKey:@"fill-opacity"]];
    UIImage *fillImage = [self imageWithSpecifier:[style objectForKey:@"fill-image"]];
    
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
            CGPatternRef pat = CGPatternCreate((__bridge void *)[NSDictionary dictionaryWithObjectsAndKeys:fillImage, @"I", [NSValue valueWithCGSize:s], @"s", nil], CGRectMake(0.0f, 0.0f, s.width, s.height), CGAffineTransformMakeScale(1.0, -1.0), s.width, s.height, kCGPatternTilingNoDistortion, true, &callbacks);
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
    OSPMapCSSSpecifier *widthSpec = [style objectForKey:@"width"];
    OSPMapCSSSpecifier *casingWidthSpec = [style objectForKey:@"casing-width"];
    
    if ([nodes count] > 1 && [widthSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]] && [casingWidthSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]])
    {
        CGPathRef path = [self createPathForWay:way];
        CGContextAddPath(ctx, path);
                
        CGContextSetLineWidth(ctx, ([(OSPMapCSSSize *)[[widthSpec values] objectAtIndex:0] value] + [(OSPMapCSSSize *)[[casingWidthSpec values] objectAtIndex:0] value]) * scale);
        UIColor *colour = [self colourWithColourSpecifier:[style objectForKey:@"casing-color"] opacitySpecifier:[style objectForKey:@"casing-opacity"]];
        CGContextSetStrokeColorWithColor(ctx, colour == nil ? [[UIColor blackColor] CGColor] : [colour CGColor]);
        OSPMapCSSSpecifier *lineCapSpec = [style objectForKey:@"casing-linecap"];
        CGContextSetLineCap(ctx, [lineCapSpec isKindOfClass:[OSPMapCSSNamedSpecifier class]] ? CGLineCapFromNSString([(OSPMapCSSNamedSpecifier *)lineCapSpec name]) : kCGLineCapRound);
        OSPMapCSSSpecifier *lineJoinSpec = [style objectForKey:@"casing-linejoin"];
        CGContextSetLineJoin(ctx, [lineJoinSpec isKindOfClass:[OSPMapCSSNamedSpecifier class]] ? CGLineJoinFromNSString([(OSPMapCSSNamedSpecifier *)lineJoinSpec name]) : kCGLineJoinRound);
        
        OSPMapCSSSpecifier *dashSpec = [style objectForKey:@"casing-dashes"];
        if ([dashSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]])
        {
            OSPMapCSSSizeListSpecifier *dashSizeSpec = (OSPMapCSSSizeListSpecifier *)dashSpec;
            CGFloat *dashes = malloc([[dashSizeSpec sizes] count]);
            int i = 0;
            for (OSPMapCSSSize *size in [dashSizeSpec sizes])
            {
                dashes[i] = [size value] * scale;
                i++;
            }
            CGContextSetLineDash(ctx, 0.0f, dashes, [[dashSizeSpec sizes] count]);
            free(dashes);
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
    OSPMapCSSSpecifier *widthSpec = [style objectForKey:@"width"];
    UIImage *strokeImage = [self imageWithSpecifier:[style objectForKey:@"image"]];
    
    BOOL strokeValid = [widthSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]];
    
    if ([nodes count] > 1)
    {
        if (strokeValid)
        {
            CGPathRef path = [self createPathForWay:way];
            CGContextAddPath(ctx, path);
            
            CGContextSetLineWidth(ctx, [(OSPMapCSSSize *)[[(OSPMapCSSSizeListSpecifier *)widthSpec sizes] objectAtIndex:0] value] * scale);
            if (nil == strokeImage)
            {
                CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB();
                CGContextSetFillColorSpace(ctx, rgbSpace);
                CGColorSpaceRelease(rgbSpace);
                UIColor *colour = [self colourWithColourSpecifier:[style objectForKey:@"color"] opacitySpecifier:[style objectForKey:@"opacity"]];
                CGContextSetStrokeColorWithColor(ctx, colour == nil ? [[UIColor blackColor] CGColor] : [colour CGColor]);
                OSPMapCSSSpecifier *lineCapSpec = [style objectForKey:@"linecap"];
                CGContextSetLineCap(ctx, [lineCapSpec isKindOfClass:[OSPMapCSSNamedSpecifier class]] ? CGLineCapFromNSString([(OSPMapCSSNamedSpecifier *)lineCapSpec name]) : kCGLineCapRound);
                OSPMapCSSSpecifier *lineJoinSpec = [style objectForKey:@"linejoin"];
                CGContextSetLineJoin(ctx, [lineJoinSpec isKindOfClass:[OSPMapCSSNamedSpecifier class]] ? CGLineJoinFromNSString([(OSPMapCSSNamedSpecifier *)lineJoinSpec name]) : kCGLineJoinRound);
                
                OSPMapCSSSpecifier *dashSpec = [style objectForKey:@"dashes"];
                if ([dashSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]])
                {
                    OSPMapCSSSizeListSpecifier *dashSizeSpec = (OSPMapCSSSizeListSpecifier *)dashSpec;
                    CGFloat *dashes = malloc([[dashSizeSpec sizes] count]);
                    int i = 0;
                    for (OSPMapCSSSize *size in [dashSizeSpec sizes])
                    {
                        dashes[i] = [size value] * scale;
                        i++;
                    }
                    CGContextSetLineDash(ctx, 0.0f, dashes, [[dashSizeSpec sizes] count]);
                    free(dashes);
                }
                else
                {
                    CGContextSetLineDash(ctx, 0.0f, NULL, 0);
                }
            }
            else
            {
                CGSize s = [strokeImage size];
                CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);
                CGContextSetStrokeColorSpace(ctx, patternSpace);
                CGColorSpaceRelease(patternSpace);
                static const CGPatternCallbacks callbacks = { 0, &patternCallback, NULL };
                CGPatternRef pat = CGPatternCreate((__bridge void *)[NSDictionary dictionaryWithObjectsAndKeys:strokeImage, @"I", [NSValue valueWithCGSize:s], @"s", nil], CGRectMake(0.0f, 0.0f, s.width, s.height), CGAffineTransformMakeScale(1.0, -1.0), s.width, s.height, kCGPatternTilingNoDistortion, true, &callbacks);
                CGFloat alpha = 1;
                CGContextSetStrokePattern(ctx, pat, &alpha);
                CGPatternRelease(pat);
            }
            
            CGContextStrokePath(ctx);
            CGPathRelease(path);
        }
    }
}

- (void)renderNode:(OSPMapCSSStyledObject *)node inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    [self renderObject:node atPoint:[(OSPNode *)[node object] projectedLocation] inContext:ctx withScaleMultiplier:scale];
}

- (void)renderObjectAtCentroid:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    if (nil != [self imageWithSpecifier:[style objectForKey:@"icon-image"]])
    {
        OSPWay *way = (OSPWay *)[object object];
        OSPCoordinate2D c = [way projectedCentroid];
        [self renderObject:object atPoint:c inContext:ctx withScaleMultiplier:scale];
    }
}

- (void)renderObject:(OSPMapCSSStyledObject *)object atPoint:(OSPCoordinate2D)loc inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    
    UIImage *image = [self imageWithSpecifier:[style objectForKey:@"icon-image"]];
    if (nil != image)
    {
        OSPMapCSSSpecifier *opacitySpec = [style objectForKey:@"icon-opacity"];
        CGContextSaveGState(ctx);
        CGContextSetAlpha(ctx, [opacitySpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]] ? [(OSPMapCSSSize *)[[(OSPMapCSSSizeListSpecifier *)opacitySpec sizes] objectAtIndex:0] value] : 1.0f);
        OSPMapCSSSpecifier *widthSpec = [style objectForKey:@"icon-width"];
        OSPMapCSSSpecifier *heightSpec = [style objectForKey:@"icon-height"];
        
        CGFloat width = [image size].width;
        CGFloat height = [image size].height;
        
        if ([widthSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]])
        {
            OSPMapCSSSize *ws = [[(OSPMapCSSSizeListSpecifier *)widthSpec sizes] objectAtIndex:0];
            width = [ws unit] == OSPMapCSSUnitPercent ? width * [ws value] * 0.01f : [ws value];
        }
        if ([heightSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]])
        {
            OSPMapCSSSize *hs = [[(OSPMapCSSSizeListSpecifier *)heightSpec sizes] objectAtIndex:0];
            height = [hs unit] == OSPMapCSSUnitPercent ? height * [hs value] * 0.01f : [hs value];
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
    
    OSPMapCSSNamedSpecifier *textSpecifier = [style objectForKey:@"text"];
    NSString *title = [self applyTextTransform:style toString:[textSpecifier name]];
    
    if (nil != title)
    {
        OSPMapCSSNamedSpecifier *positionSpecifier = [style objectForKey:@"text-position"];
        NSString *position = nil == positionSpecifier ? @"center" : [positionSpecifier name];
        
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
    
    OSPMapCSSNamedSpecifier *textSpecifier = [style objectForKey:@"text"];
    NSString *title = [self applyTextTransform:style toString:[[node tags] objectForKey:[textSpecifier name]]];
    
    if (nil != title)
    {
        OSPCoordinate2D c = [node projectedLocation];
        CGPoint textPosition = CGPointMake(c.x, c.y);
        
        [self drawText:title atPoint:textPosition inContext:ctx withStyle:style scaleMultiplier:scale];
    }
}

- (NSString *)applyTextTransform:(NSDictionary *)style toString:(NSString *)str
{
    OSPMapCSSNamedSpecifier *textTransformSpecifier = [style objectForKey:@"text-transform"];
    NSString *textTransform = [textTransformSpecifier name];
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
    
    OSPMapCSSSizeListSpecifier *haloSizeSpecifier = [style objectForKey:@"text-halo-radius"];
    CGFloat haloRadius = nil == haloSizeSpecifier ? 0.0f : [(OSPMapCSSSize *)[[haloSizeSpecifier sizes] objectAtIndex:0] value];
    BOOL hasHalo = haloRadius != 0.0f;
    
    CGFloat lineHeight = CTFontGetAscent(scaledFont) + CTFontGetDescent(scaledFont) + CTFontGetLeading(scaledFont) + haloRadius * scale;
    
    UIColor *haloColour = [self colourWithColourSpecifier:[style objectForKey:@"text-halo-color"] opacitySpecifier:[style objectForKey:@"text-halo-opacity"]];
    UIColor *colour = [self colourWithColourSpecifier:[style objectForKey:@"text-color"] opacitySpecifier:[style objectForKey:@"text-opacity"]];
    
    OSPMapCSSSizeListSpecifier *vOffsetSpecifier = [style objectForKey:@"text-offset"];
    CGFloat offset = nil == vOffsetSpecifier ? 0.0f : [(OSPMapCSSSize *)[[vOffsetSpecifier sizes] objectAtIndex:0] value];
    CGFloat scaledOffset = offset * scale;
    
    OSPMapCSSSizeListSpecifier *widthSpecifier = [style objectForKey:@"max-width"];
    CGFloat width = nil == widthSpecifier ? 100.0f : [(OSPMapCSSSize *)[[widthSpecifier sizes] objectAtIndex:0] value];
    
    CGFloat scaledWidth = width * scale;
    
    textPosition.y += scaledOffset;
    
    const CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    const CTParagraphStyleSetting paragraphStyleSettings[] = {{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(lineBreakMode), .value = &lineBreakMode}};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyleSettings, sizeof(paragraphStyleSettings) / sizeof(paragraphStyleSettings[0]));
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                (__bridge id)font, kCTFontAttributeName,
                                paragraphStyle, kCTParagraphStyleAttributeName,
                                nil];
    NSMutableDictionary *scaledAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             (__bridge id)scaledFont, kCTFontAttributeName,
                                             kCFBooleanTrue, kCTForegroundColorFromContextAttributeName,
                                             paragraphStyle, kCTParagraphStyleAttributeName,
                                             nil];
    
    CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)text, (__bridge CFDictionaryRef)attributes);
    CFAttributedStringRef scaledAttrString = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)text, (__bridge CFDictionaryRef)scaledAttributes);
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(attrString);
    CTTypesetterRef scaledTypesetter = CTTypesetterCreateWithAttributedString(scaledAttrString);
    CFRelease(attrString);
    CFRelease(scaledAttrString);
    
    OSPMapCSSNamedSpecifier *textDecorationSpecifier = [style objectForKey:@"text-decoration"];
    BOOL shouldUnderline = [[textDecorationSpecifier name] isEqualToString:@"underline"];
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
    
    CFRelease(font);
    CFRelease(scaledFont);
}

- (void)drawText:(NSString *)text onWay:(OSPWay *)textWay inContext:(CGContextRef)ctx withStyle:(NSDictionary *)style scaleMultiplier:(CGFloat)scale
{
    CTFontRef scaledFont = nil;
    CTFontRef font = [self createFontWithStyle:style scaledVariant:&scaledFont atScale:scale];
    
    OSPMapCSSSizeListSpecifier *haloSizeSpecifier = [style objectForKey:@"text-halo-radius"];
    CGFloat haloRadius = nil == haloSizeSpecifier ? 0.0f : [(OSPMapCSSSize *)[[haloSizeSpecifier sizes] objectAtIndex:0] value];
    BOOL hasHalo = haloRadius != 0.0f;
    
    UIColor *haloColour = [self colourWithColourSpecifier:[style objectForKey:@"text-halo-color"] opacitySpecifier:[style objectForKey:@"text-halo-opacity"]];
    UIColor *colour = [self colourWithColourSpecifier:[style objectForKey:@"text-color"] opacitySpecifier:[style objectForKey:@"text-opacity"]];
    
    OSPMapCSSSizeListSpecifier *vOffsetSpecifier = [style objectForKey:@"text-offset"];
    CGFloat offset = nil == vOffsetSpecifier ? 0.0f : [(OSPMapCSSSize *)[[vOffsetSpecifier sizes] objectAtIndex:0] value];
    CGFloat scaledOffset = offset * scale;
    
    NSMutableDictionary *scaledAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             (__bridge id)scaledFont, kCTFontAttributeName,
                                             kCFBooleanTrue, kCTForegroundColorFromContextAttributeName,
                                             nil];
    
    CFAttributedStringRef scaledAttrString = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)text, (__bridge CFDictionaryRef)scaledAttributes);
    CTTypesetterRef scaledTypesetter = CTTypesetterCreateWithAttributedString(scaledAttrString);
    CTLineRef line = CTTypesetterCreateLine(scaledTypesetter, CFRangeMake(0, CFAttributedStringGetLength(scaledAttrString)));
    CFRelease(scaledAttrString);
    
    double lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
    double wayLength = [textWay length];
    
    CGContextSetLineWidth(ctx, haloRadius * 2.0f * scale);
    CGContextSetFillColorWithColor(ctx, [colour CGColor]);
    CGContextSetStrokeColorWithColor(ctx, [haloColour CGColor]);
    
    CGFontRef gFont = CTFontCopyGraphicsFont(scaledFont, NULL);
    CGContextSetFont(ctx, gFont);
    CGContextSetFontSize(ctx, CTFontGetSize(scaledFont));
    CFRelease(gFont);
    
    if (wayLength > lineWidth)
    {
        double wayOffset = (wayLength - lineWidth) * 0.5;
        BOOL backwards = [textWay positionOnWayWithOffset:wayOffset heightAboveWay:0.0 backwards:NO].x > [textWay positionOnWayWithOffset:wayOffset + lineWidth heightAboveWay:0.0 backwards:NO].x;
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        int numRuns = CFArrayGetCount(runs);
        for (int runNumber = 0; runNumber < numRuns; runNumber++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, runNumber);
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
    
    CFRelease(line);
    CFRelease(scaledTypesetter);
    CFRelease(scaledFont);
    CFRelease(font);
}

- (CTFontRef)createFontWithStyle:(NSDictionary *)style scaledVariant:(CTFontRef *)scaledFont atScale:(CGFloat)scale
{
    OSPMapCSSNamedSpecifier *fontFamilySpecifier = [style objectForKey:@"font-family"];
    NSString *fontFamily = nil == fontFamilySpecifier ? @"Helvetica" : [fontFamilySpecifier name];
    OSPMapCSSSizeListSpecifier *fontSizeSpecifier = [style objectForKey:@"font-size"];
    CGFloat fontSize = nil == fontSizeSpecifier ? 12.0f : [(OSPMapCSSSize *)[[fontSizeSpecifier sizes] objectAtIndex:0] value];
    
    CTFontSymbolicTraits traits = 0x0;
    OSPMapCSSNamedSpecifier *fontWeightSpecifier = [style objectForKey:@"font-weight"];
    OSPMapCSSNamedSpecifier *fontStyleSpecifier = [style objectForKey:@"font-style"];
    traits |= nil != fontWeightSpecifier && [[fontWeightSpecifier name] isEqualToString:@"bold"] ? kCTFontBoldTrait : 0x0;
    traits |= nil != fontStyleSpecifier && [[fontStyleSpecifier name] isEqualToString:@"italic"] ? kCTFontItalicTrait : 0x0;
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

- (UIImage *)imageWithSpecifier:(OSPMapCSSSpecifier *)spec
{
    if ([spec isKindOfClass:[OSPMapCSSURLSpecifier class]])
    {
        OSPMapCSSUrl *u = [(OSPMapCSSURLSpecifier *)spec url];
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

