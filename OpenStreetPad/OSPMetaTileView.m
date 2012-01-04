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

- (void)renderLayers:(NSDictionary *)layers inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderWay:(OSPMapCSSStyledObject *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderCasing:(OSPMapCSSStyledObject *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderNode:(OSPMapCSSStyledObject *)node inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderObjectAtCentroid:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderObject:(OSPMapCSSStyledObject *)obj atPoint:(OSPCoordinate2D)loc inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;

- (void)renderWayLabel:(OSPMapCSSStyledObject *)styledWay inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderNodeLabel:(OSPMapCSSStyledObject *)styledWay inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;

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
        c = [(OSPMapCSSColourSpecifier *)colour colour];
    }
    else if ([colour isKindOfClass:[OSPMapCSSNamedSpecifier class]])
    {
        NSString *colourName = [(OSPMapCSSNamedSpecifier *)colour name];
        c = [UIColor colourWithCSSName:colourName];
    }
    
    if (nil != c && [opacity isKindOfClass:[OSPMapCSSSizeListSpecifier class]])
    {
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        [c getRed:&red green:&green blue:&blue alpha:&alpha];
        alpha = [(OSPMapCSSSize *)[[(OSPMapCSSSizeListSpecifier *)opacity sizes] objectAtIndex:0] value];
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
                               float z1 = [z1s isKindOfClass:[OSPMapCSSSizeListSpecifier class]] ? [(OSPMapCSSSize *)[[(OSPMapCSSSizeListSpecifier *)z1s sizes] objectAtIndex:0] value] : 0.0f;
                               float z2 = [z2s isKindOfClass:[OSPMapCSSSizeListSpecifier class]] ? [(OSPMapCSSSize *)[[(OSPMapCSSSizeListSpecifier *)z2s sizes] objectAtIndex:0] value] : 0.0f;
                               
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
        for (OSPMapCSSStyledObject *object in layer)
        {
            if ([[object object] isKindOfClass:[OSPWay class]])
            {
                [self renderCasing:object inContext:ctx withScaleMultiplier:scale];
            }
        }
        for (OSPMapCSSStyledObject *object in layer)
        {
            if ([[object object] isKindOfClass:[OSPWay class]])
            {
                [self renderWay:object inContext:ctx withScaleMultiplier:scale];
            }
            else if ([[object object] isKindOfClass:[OSPNode class]])
            {
                [self renderNode:object inContext:ctx withScaleMultiplier:scale];
            }
        }
        for (OSPMapCSSStyledObject *object in layer)
        {
            if ([[object object] isKindOfClass:[OSPWay class]])
            {
                [self renderWayLabel:object inContext:ctx withScaleMultiplier:scale];
            }
            else if ([[object object] isKindOfClass:[OSPNode class]])
            {
                [self renderNodeLabel:object inContext:ctx withScaleMultiplier:scale];
            }
        }
    }
}

extern char styleKey;

- (void)renderCasing:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    OSPWay *way = (OSPWay *)[object object];
    
    NSArray *nodes = [way nodes];
    OSPMapCSSSpecifier *widthSpec = [style objectForKey:@"width"];
    OSPMapCSSSpecifier *casingWidthSpec = [style objectForKey:@"casing-width"];
    
    if ([nodes count] > 1 && [widthSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]] && [casingWidthSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]])
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
        
        CGContextSetLineWidth(ctx, ([(OSPMapCSSSize *)[[(OSPMapCSSSizeListSpecifier *)widthSpec sizes] objectAtIndex:0] value] + [(OSPMapCSSSize *)[[(OSPMapCSSSizeListSpecifier *)casingWidthSpec sizes] objectAtIndex:0] value]) * scale);
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
    }
}

- (void)renderWay:(OSPMapCSSStyledObject *)object inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [object style];
    OSPWay *way = (OSPWay *)[object object];
    
    NSArray *nodes = [way nodeObjects];
    OSPMapCSSSpecifier *widthSpec = [style objectForKey:@"width"];
    UIColor *fillColour = [self colourWithColourSpecifier:[style objectForKey:@"fill-color"] opacitySpecifier:[style objectForKey:@"fill-opacity"]];
    
    UIImage *fillImage = [self imageWithSpecifier:[style objectForKey:@"fill-image"]];
    UIImage *strokeImage = [self imageWithSpecifier:[style objectForKey:@"image"]];
    
    BOOL strokeValid = [widthSpec isKindOfClass:[OSPMapCSSSizeListSpecifier class]];
    BOOL fillValid = fillColour != nil || fillImage != nil;
    
    if ([nodes count] > 1)
    {
        if (strokeValid || fillValid)
        {
            OSPNode *firstNode = [nodes objectAtIndex:0];
            OSPCoordinate2D l = [firstNode projectedLocation];
            
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, l.x, l.y);
            for (OSPNode *node in [nodes subarrayWithRange:NSMakeRange(1, [nodes count] - 1)])
            {
                OSPCoordinate2D nl = [node projectedLocation];
                CGPathAddLineToPoint(path, NULL, nl.x, nl.y);
            }
            
            if (fillValid)
            {
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
            }
            
            if (strokeValid)
            {
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
            }
            CGPathRelease(path);
        }
        
        [self renderObjectAtCentroid:object inContext:ctx withScaleMultiplier:scale];
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
        
        CGContextDrawImage(ctx, CGRectMake(loc.x - width * 0.5f, loc.y - height * 0.5f, width, height), [image CGImage]);
        CGContextRestoreGState(ctx);
    }
}

- (void)renderWayLabel:(OSPMapCSSStyledObject *)styledWay inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = [styledWay style];
    OSPWay *way = (OSPWay *)[styledWay object];
    BOOL hasHalo = NO;
    
    OSPMapCSSNamedSpecifier *textSpecifier = [style objectForKey:@"text"];
    NSString *title = [[way tags] objectForKey:[textSpecifier name]];
    OSPMapCSSNamedSpecifier *textTransformSpecifier = [style objectForKey:@"text-transform"];
    NSString *textTransform = [textTransformSpecifier name];
    if ([textTransform isEqualToString:@"uppercase"])
    {
        title = [title uppercaseString];
    }
    else if ([textTransform isEqualToString:@"lowercase"])
    {
        title = [title lowercaseString];
    }
    else if ([textTransform isEqualToString:@"capitalize"])
    {
        title = [title capitalizedString];
    }
    
    if (nil != title)
    {
        OSPMapCSSNamedSpecifier *positionSpecifier = [style objectForKey:@"text-position"];
        NSString *position = nil == positionSpecifier ? @"center" : [positionSpecifier name];
        
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
        CTFontRef scaledFont = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize * scale, NULL, newTraits, newTraits);
        if (NULL == scaledFont)
        {
            newTraits &= (0xffffffff ^ kCTFontItalicTrait);
            scaledFont = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize * scale, NULL, newTraits, newTraits);
        }
        if (NULL == scaledFont)
        {
            newTraits = traits & (0xffffffff ^ kCTFontBoldTrait);
            scaledFont = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize * scale, NULL, newTraits, newTraits);
        }
        if (NULL == scaledFont)
        {
            newTraits = 0x0;
            scaledFont = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize * scale, NULL, newTraits, newTraits);
        }
        CTFontRef font = CTFontCreateCopyWithSymbolicTraits(baseFont, fontSize, NULL, newTraits, newTraits);
        CFRelease(baseFont);
        CGFloat lineHeight = (CTFontGetAscent(scaledFont) + CTFontGetDescent(scaledFont) + CTFontGetLeading(scaledFont));
        
        OSPMapCSSSizeListSpecifier *haloSizeSpecifier = [style objectForKey:@"text-halo-radius"];
        CGFloat haloRadius = nil == haloSizeSpecifier ? 0.0f : [(OSPMapCSSSize *)[[haloSizeSpecifier sizes] objectAtIndex:0] value];
        hasHalo = haloRadius != 0.0f;
        
        UIColor *haloColour = [self colourWithColourSpecifier:[style objectForKey:@"text-halo-color"] opacitySpecifier:[style objectForKey:@"text-halo-opacity"]];
        UIColor *colour = [self colourWithColourSpecifier:[style objectForKey:@"text-color"] opacitySpecifier:[style objectForKey:@"text-opacity"]];
        
        if ([position isEqualToString:@"line"])
        {
            
        }
        else if ([position isEqualToString:@"center"])
        {
            OSPMapCSSSizeListSpecifier *widthSpecifier = [style objectForKey:@"max-width"];
            CGFloat width = nil == widthSpecifier ? 100.0f : [(OSPMapCSSSize *)[[widthSpecifier sizes] objectAtIndex:0] value];
             
            OSPMapCSSSizeListSpecifier *vOffsetSpecifier = [style objectForKey:@"text-offset"];
            CGFloat offset = nil == vOffsetSpecifier ? 0.0f : [(OSPMapCSSSize *)[[vOffsetSpecifier sizes] objectAtIndex:0] value];
            
            CGFloat scaledWidth = width * scale;
            CGFloat scaledOffset = offset * scale;
            
            OSPCoordinate2D c = [way projectedCentroid];
            CGPoint textPosition = CGPointMake(c.x, c.y);
            textPosition.y += scaledOffset;
            
            const CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
            const CTParagraphStyleSetting paragraphStyleSettings[] = {{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(lineBreakMode), .value = &lineBreakMode}};
            CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyleSettings, sizeof(paragraphStyleSettings) / sizeof(paragraphStyleSettings[0]));
            OSPMapCSSNamedSpecifier *textDecorationSpecifier = [style objectForKey:@"text-decoration"];
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge id)font, kCTFontAttributeName,
                                        paragraphStyle, kCTParagraphStyleAttributeName,
                                        nil];
            NSMutableDictionary *scaledAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     (__bridge id)scaledFont, kCTFontAttributeName,
                                                     kCFBooleanTrue, kCTForegroundColorFromContextAttributeName,
                                                     paragraphStyle, kCTParagraphStyleAttributeName,
                                                     [[textDecorationSpecifier name] isEqualToString:@"underline"] ? [NSNumber numberWithInt:kCTUnderlineStyleSingle] : [NSNumber numberWithInt:kCTUnderlineStyleNone], kCTUnderlineStyleAttributeName,
                                                     nil];
            
            CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)title, (__bridge CFDictionaryRef)attributes);
            CFAttributedStringRef scaledAttrString = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)title, (__bridge CFDictionaryRef)scaledAttributes);
            CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(attrString);
            CTTypesetterRef scaledTypesetter = CTTypesetterCreateWithAttributedString(scaledAttrString);
            CFRelease(attrString);
            CFRelease(scaledAttrString);
            
            CFIndex start = 0;
            CFIndex length = [title length];
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
                CTLineDraw(line, ctx);
                
                CFRelease(line);

                textPosition.y += lineHeight;
                
                start += count;
            }
            while (start < length);
            CFRelease(typesetter);
        }
        CFRelease(font);
        CFRelease(scaledFont);
    }
}

- (void)renderNodeLabel:(OSPMapCSSStyledObject *)node inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    
}

- (UIImage *)imageWithSpecifier:(OSPMapCSSSpecifier *)spec
{
    if ([spec isKindOfClass:[OSPMapCSSURLSpecifier class]])
    {
        OSPMapCSSUrl *u = [(OSPMapCSSURLSpecifier *)spec url];
        if (![u isEval])
        {
            NSString *url = [u content];
            NSString *ext = [url pathExtension];
            NSString *resName = [[url lastPathComponent] stringByDeletingPathExtension];
            NSString *dir = [url stringByDeletingLastPathComponent];
            NSString *path = [[NSBundle mainBundle] pathForResource:resName ofType:ext inDirectory:dir];
            return [UIImage imageWithContentsOfFile:path];
        }
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

