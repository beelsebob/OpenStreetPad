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

#import "Specifier.h"
#import "SizeListSpecifier.h"
#import "ColourSpecifier.h"
#import "NamedSpecifier.h"
#import "MapCSSSize.h"
#import "URLSpecifier.h"

#import <objc/runtime.h>

void patternCallback(void *info, CGContextRef ctx);

@interface OSPMetaTileView ()

- (NSDictionary *)sortedObjects:(NSSet *)objects;

- (UIColor *)colourWithColourSpecifier:(Specifier *)colour opacitySpecifier:(Specifier *)opacity;
- (UIColor *)colourFromName:(NSString *)colourName;
- (UIImage *)imageWithSpecifier:(Specifier *)spec;

- (void)renderLayers:(NSDictionary *)layers inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderWay:(OSPWay *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;
- (void)renderCasing:(OSPWay *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale;

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
    
    NSSet *objects = [[self server] objectsInBounds:dataRect];
    
    [[self stylesheet] styleObjects:objects];
    [self renderLayers:[self sortedObjects:objects] inContext:ctx withScaleMultiplier:oneOverScale];
}

- (UIColor *)colourWithColourSpecifier:(Specifier *)colour opacitySpecifier:(Specifier *)opacity
{
    UIColor *c = nil;
    if ([colour isKindOfClass:[ColourSpecifier class]])
    {
        c = [(ColourSpecifier *)colour colour];
    }
    else if ([colour isKindOfClass:[NamedSpecifier class]])
    {
        NSString *colourName = [(NamedSpecifier *)colour name];
        c = [self colourFromName:colourName];
    }
    
    if (nil != c && [opacity isKindOfClass:[SizeListSpecifier class]])
    {
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        [c getRed:&red green:&green blue:&blue alpha:&alpha];
        alpha = [(MapCSSSize *)[[(SizeListSpecifier *)opacity sizes] objectAtIndex:0] value];
        c = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }
    
    return c;
}

static NSDictionary *colours = nil;

- (UIColor *)colourFromName:(NSString *)colourName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colours = [NSDictionary dictionaryWithObjectsAndKeys:
                   [UIColor colorWithRed:240.0f / 255.0f green:248.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"aliceblue"           ,
                   [UIColor colorWithRed:250.0f / 255.0f green:235.0f / 255.0f blue:215.0f / 255.0f alpha:1.0], @"antiquewhite"        ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"aqua"                ,
                   [UIColor colorWithRed:127.0f / 255.0f green:255.0f / 255.0f blue:212.0f / 255.0f alpha:1.0], @"aquamarine"          ,
                   [UIColor colorWithRed:240.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"azure"               ,
                   [UIColor colorWithRed:245.0f / 255.0f green:245.0f / 255.0f blue:220.0f / 255.0f alpha:1.0], @"beige"               ,
                   [UIColor colorWithRed:255.0f / 255.0f green:228.0f / 255.0f blue:196.0f / 255.0f alpha:1.0], @"bisque"              ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:  0.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"black"               ,
                   [UIColor colorWithRed:255.0f / 255.0f green:235.0f / 255.0f blue:205.0f / 255.0f alpha:1.0], @"blanchedalmond"      ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:  0.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"blue"                ,
                   [UIColor colorWithRed:138.0f / 255.0f green: 43.0f / 255.0f blue:226.0f / 255.0f alpha:1.0], @"blueviolet"          ,
                   [UIColor colorWithRed:165.0f / 255.0f green: 42.0f / 255.0f blue: 42.0f / 255.0f alpha:1.0], @"brown"               ,
                   [UIColor colorWithRed:222.0f / 255.0f green:184.0f / 255.0f blue:135.0f / 255.0f alpha:1.0], @"burlywood"           ,
                   [UIColor colorWithRed: 95.0f / 255.0f green:158.0f / 255.0f blue:160.0f / 255.0f alpha:1.0], @"cadetblue"           ,
                   [UIColor colorWithRed:127.0f / 255.0f green:255.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"chartreuse"          ,
                   [UIColor colorWithRed:210.0f / 255.0f green:105.0f / 255.0f blue: 30.0f / 255.0f alpha:1.0], @"chocolate"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:127.0f / 255.0f blue: 80.0f / 255.0f alpha:1.0], @"coral"               ,
                   [UIColor colorWithRed:100.0f / 255.0f green:149.0f / 255.0f blue:237.0f / 255.0f alpha:1.0], @"cornflowerblue"      ,
                   [UIColor colorWithRed:255.0f / 255.0f green:248.0f / 255.0f blue:220.0f / 255.0f alpha:1.0], @"cornsilk"            ,
                   [UIColor colorWithRed:220.0f / 255.0f green: 20.0f / 255.0f blue: 60.0f / 255.0f alpha:1.0], @"crimson"             ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"cyan"                ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:  0.0f / 255.0f blue:139.0f / 255.0f alpha:1.0], @"darkblue"            ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:139.0f / 255.0f blue:139.0f / 255.0f alpha:1.0], @"darkcyan"            ,
                   [UIColor colorWithRed:184.0f / 255.0f green:134.0f / 255.0f blue: 11.0f / 255.0f alpha:1.0], @"darkgoldenrod"       ,
                   [UIColor colorWithRed:169.0f / 255.0f green:169.0f / 255.0f blue:169.0f / 255.0f alpha:1.0], @"darkgray"            ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:100.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"darkgreen"           ,
                   [UIColor colorWithRed:169.0f / 255.0f green:169.0f / 255.0f blue:169.0f / 255.0f alpha:1.0], @"darkgrey"            ,
                   [UIColor colorWithRed:189.0f / 255.0f green:183.0f / 255.0f blue:107.0f / 255.0f alpha:1.0], @"darkkhaki"           ,
                   [UIColor colorWithRed:139.0f / 255.0f green:  0.0f / 255.0f blue:139.0f / 255.0f alpha:1.0], @"darkmagenta"         ,
                   [UIColor colorWithRed: 85.0f / 255.0f green:107.0f / 255.0f blue: 47.0f / 255.0f alpha:1.0], @"darkolivegreen"      ,
                   [UIColor colorWithRed:255.0f / 255.0f green:140.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"darkorange"          ,
                   [UIColor colorWithRed:153.0f / 255.0f green: 50.0f / 255.0f blue:204.0f / 255.0f alpha:1.0], @"darkorchid"          ,
                   [UIColor colorWithRed:139.0f / 255.0f green:  0.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"darkred"             ,
                   [UIColor colorWithRed:233.0f / 255.0f green:150.0f / 255.0f blue:122.0f / 255.0f alpha:1.0], @"darksalmon"          ,
                   [UIColor colorWithRed:143.0f / 255.0f green:188.0f / 255.0f blue:143.0f / 255.0f alpha:1.0], @"darkseagreen"        ,
                   [UIColor colorWithRed: 72.0f / 255.0f green: 61.0f / 255.0f blue:139.0f / 255.0f alpha:1.0], @"darkslateblue"       ,
                   [UIColor colorWithRed: 47.0f / 255.0f green: 79.0f / 255.0f blue: 79.0f / 255.0f alpha:1.0], @"darkslategray"       ,
                   [UIColor colorWithRed: 47.0f / 255.0f green: 79.0f / 255.0f blue: 79.0f / 255.0f alpha:1.0], @"darkslategrey"       ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:206.0f / 255.0f blue:209.0f / 255.0f alpha:1.0], @"darkturquoise"       ,
                   [UIColor colorWithRed:148.0f / 255.0f green:  0.0f / 255.0f blue:211.0f / 255.0f alpha:1.0], @"darkviolet"          ,
                   [UIColor colorWithRed:255.0f / 255.0f green: 20.0f / 255.0f blue:147.0f / 255.0f alpha:1.0], @"deeppink"            ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:191.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"deepskyblue"         ,
                   [UIColor colorWithRed:105.0f / 255.0f green:105.0f / 255.0f blue:105.0f / 255.0f alpha:1.0], @"dimgray"             ,
                   [UIColor colorWithRed:105.0f / 255.0f green:105.0f / 255.0f blue:105.0f / 255.0f alpha:1.0], @"dimgrey"             ,
                   [UIColor colorWithRed: 30.0f / 255.0f green:144.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"dodgerblue"          ,
                   [UIColor colorWithRed:178.0f / 255.0f green: 34.0f / 255.0f blue: 34.0f / 255.0f alpha:1.0], @"firebrick"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:250.0f / 255.0f blue:240.0f / 255.0f alpha:1.0], @"floralwhite"         ,
                   [UIColor colorWithRed: 34.0f / 255.0f green:139.0f / 255.0f blue: 34.0f / 255.0f alpha:1.0], @"forestgreen"         ,
                   [UIColor colorWithRed:255.0f / 255.0f green:  0.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"fuchsia"             ,
                   [UIColor colorWithRed:220.0f / 255.0f green:220.0f / 255.0f blue:220.0f / 255.0f alpha:1.0], @"gainsboro"           ,
                   [UIColor colorWithRed:248.0f / 255.0f green:248.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"ghostwhite"          ,
                   [UIColor colorWithRed:255.0f / 255.0f green:215.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"gold"                ,
                   [UIColor colorWithRed:218.0f / 255.0f green:165.0f / 255.0f blue: 32.0f / 255.0f alpha:1.0], @"goldenrod"           ,
                   [UIColor colorWithRed:128.0f / 255.0f green:128.0f / 255.0f blue:128.0f / 255.0f alpha:1.0], @"gray"                ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:128.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"green"               ,
                   [UIColor colorWithRed:173.0f / 255.0f green:255.0f / 255.0f blue: 47.0f / 255.0f alpha:1.0], @"greenyellow"         ,
                   [UIColor colorWithRed:128.0f / 255.0f green:128.0f / 255.0f blue:128.0f / 255.0f alpha:1.0], @"grey"                ,
                   [UIColor colorWithRed:240.0f / 255.0f green:255.0f / 255.0f blue:240.0f / 255.0f alpha:1.0], @"honeydew"            ,
                   [UIColor colorWithRed:255.0f / 255.0f green:105.0f / 255.0f blue:180.0f / 255.0f alpha:1.0], @"hotpink"             ,
                   [UIColor colorWithRed:205.0f / 255.0f green: 92.0f / 255.0f blue: 92.0f / 255.0f alpha:1.0], @"indianred"           ,
                   [UIColor colorWithRed: 75.0f / 255.0f green:  0.0f / 255.0f blue:130.0f / 255.0f alpha:1.0], @"indigo"              ,
                   [UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:240.0f / 255.0f alpha:1.0], @"ivory"               ,
                   [UIColor colorWithRed:240.0f / 255.0f green:230.0f / 255.0f blue:140.0f / 255.0f alpha:1.0], @"khaki"               ,
                   [UIColor colorWithRed:230.0f / 255.0f green:230.0f / 255.0f blue:250.0f / 255.0f alpha:1.0], @"lavender"            ,
                   [UIColor colorWithRed:255.0f / 255.0f green:240.0f / 255.0f blue:245.0f / 255.0f alpha:1.0], @"lavenderblush"       ,
                   [UIColor colorWithRed:124.0f / 255.0f green:252.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"lawngreen"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:250.0f / 255.0f blue:205.0f / 255.0f alpha:1.0], @"lemonchiffon"        ,
                   [UIColor colorWithRed:173.0f / 255.0f green:216.0f / 255.0f blue:230.0f / 255.0f alpha:1.0], @"lightblue"           ,
                   [UIColor colorWithRed:240.0f / 255.0f green:128.0f / 255.0f blue:128.0f / 255.0f alpha:1.0], @"lightcyan"           ,
                   [UIColor colorWithRed:224.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"lightcoral"          ,
                   [UIColor colorWithRed:250.0f / 255.0f green:250.0f / 255.0f blue:210.0f / 255.0f alpha:1.0], @"lightgoldenrodyellow",
                   [UIColor colorWithRed:211.0f / 255.0f green:211.0f / 255.0f blue:211.0f / 255.0f alpha:1.0], @"lightgray"           ,
                   [UIColor colorWithRed:144.0f / 255.0f green:238.0f / 255.0f blue:144.0f / 255.0f alpha:1.0], @"lightgreen"          ,
                   [UIColor colorWithRed:211.0f / 255.0f green:211.0f / 255.0f blue:211.0f / 255.0f alpha:1.0], @"lightgrey"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:182.0f / 255.0f blue:193.0f / 255.0f alpha:1.0], @"lightpink"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:160.0f / 255.0f blue:122.0f / 255.0f alpha:1.0], @"lightsalmon"         ,
                   [UIColor colorWithRed: 32.0f / 255.0f green:178.0f / 255.0f blue:170.0f / 255.0f alpha:1.0], @"lightseagreen"       ,
                   [UIColor colorWithRed:135.0f / 255.0f green:206.0f / 255.0f blue:250.0f / 255.0f alpha:1.0], @"lightskyblue"        ,
                   [UIColor colorWithRed:119.0f / 255.0f green:136.0f / 255.0f blue:153.0f / 255.0f alpha:1.0], @"lightslategray"      ,
                   [UIColor colorWithRed:119.0f / 255.0f green:136.0f / 255.0f blue:153.0f / 255.0f alpha:1.0], @"lightslategrey"      ,
                   [UIColor colorWithRed:176.0f / 255.0f green:196.0f / 255.0f blue:222.0f / 255.0f alpha:1.0], @"lightsteelblue"      ,
                   [UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:224.0f / 255.0f alpha:1.0], @"lightyellow"         ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:255.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"lime"                ,
                   [UIColor colorWithRed: 50.0f / 255.0f green:205.0f / 255.0f blue: 50.0f / 255.0f alpha:1.0], @"limegreen"           ,
                   [UIColor colorWithRed:250.0f / 255.0f green:240.0f / 255.0f blue:230.0f / 255.0f alpha:1.0], @"linen"               ,
                   [UIColor colorWithRed:255.0f / 255.0f green:  0.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"magenta"             ,
                   [UIColor colorWithRed:128.0f / 255.0f green:  0.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"maroon"              ,
                   [UIColor colorWithRed:102.0f / 255.0f green:205.0f / 255.0f blue:170.0f / 255.0f alpha:1.0], @"mediumaquamarine"    ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:  0.0f / 255.0f blue:205.0f / 255.0f alpha:1.0], @"mediumblue"          ,
                   [UIColor colorWithRed:186.0f / 255.0f green: 85.0f / 255.0f blue:211.0f / 255.0f alpha:1.0], @"mediumorchid"        ,
                   [UIColor colorWithRed:147.0f / 255.0f green:112.0f / 255.0f blue:219.0f / 255.0f alpha:1.0], @"mediumpurple"        ,
                   [UIColor colorWithRed: 60.0f / 255.0f green:179.0f / 255.0f blue:113.0f / 255.0f alpha:1.0], @"mediumseagreen"      ,
                   [UIColor colorWithRed:123.0f / 255.0f green:104.0f / 255.0f blue:238.0f / 255.0f alpha:1.0], @"mediumslateblue"     ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:250.0f / 255.0f blue:154.0f / 255.0f alpha:1.0], @"mediumspringgreen"   ,
                   [UIColor colorWithRed: 72.0f / 255.0f green:209.0f / 255.0f blue:204.0f / 255.0f alpha:1.0], @"mediumturquoise"     ,
                   [UIColor colorWithRed:199.0f / 255.0f green: 21.0f / 255.0f blue:133.0f / 255.0f alpha:1.0], @"mediumvioletred"     ,
                   [UIColor colorWithRed: 25.0f / 255.0f green: 25.0f / 255.0f blue:112.0f / 255.0f alpha:1.0], @"midnightblue"        ,
                   [UIColor colorWithRed:245.0f / 255.0f green:255.0f / 255.0f blue:250.0f / 255.0f alpha:1.0], @"mintcream"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:228.0f / 255.0f blue:225.0f / 255.0f alpha:1.0], @"mistyrose"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:228.0f / 255.0f blue:181.0f / 255.0f alpha:1.0], @"moccasin"            ,
                   [UIColor colorWithRed:255.0f / 255.0f green:222.0f / 255.0f blue:173.0f / 255.0f alpha:1.0], @"navajowhite"         ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:  0.0f / 255.0f blue:128.0f / 255.0f alpha:1.0], @"navy"                ,
                   [UIColor colorWithRed:253.0f / 255.0f green:245.0f / 255.0f blue:230.0f / 255.0f alpha:1.0], @"oldlace"             ,
                   [UIColor colorWithRed:128.0f / 255.0f green:128.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"olive"               ,
                   [UIColor colorWithRed:107.0f / 255.0f green:142.0f / 255.0f blue: 35.0f / 255.0f alpha:1.0], @"olivedrab"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:165.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"orange"              ,
                   [UIColor colorWithRed:255.0f / 255.0f green: 69.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"orangered"           ,
                   [UIColor colorWithRed:218.0f / 255.0f green:112.0f / 255.0f blue:214.0f / 255.0f alpha:1.0], @"orchid"              ,
                   [UIColor colorWithRed:238.0f / 255.0f green:232.0f / 255.0f blue:170.0f / 255.0f alpha:1.0], @"palegoldenrod"       ,
                   [UIColor colorWithRed:152.0f / 255.0f green:251.0f / 255.0f blue:152.0f / 255.0f alpha:1.0], @"palegreen"           ,
                   [UIColor colorWithRed:175.0f / 255.0f green:238.0f / 255.0f blue:238.0f / 255.0f alpha:1.0], @"paleturquoise"       ,
                   [UIColor colorWithRed:219.0f / 255.0f green:112.0f / 255.0f blue:147.0f / 255.0f alpha:1.0], @"palevioletred"       ,
                   [UIColor colorWithRed:255.0f / 255.0f green:239.0f / 255.0f blue:213.0f / 255.0f alpha:1.0], @"papayawhip"          ,
                   [UIColor colorWithRed:255.0f / 255.0f green:218.0f / 255.0f blue:185.0f / 255.0f alpha:1.0], @"peachpuff"           ,
                   [UIColor colorWithRed:205.0f / 255.0f green:133.0f / 255.0f blue: 63.0f / 255.0f alpha:1.0], @"peru"                ,
                   [UIColor colorWithRed:255.0f / 255.0f green:192.0f / 255.0f blue:203.0f / 255.0f alpha:1.0], @"pink"                ,
                   [UIColor colorWithRed:221.0f / 255.0f green:160.0f / 255.0f blue:221.0f / 255.0f alpha:1.0], @"plum"                ,
                   [UIColor colorWithRed:176.0f / 255.0f green:224.0f / 255.0f blue:230.0f / 255.0f alpha:1.0], @"powderblue"          ,
                   [UIColor colorWithRed:128.0f / 255.0f green:  0.0f / 255.0f blue:128.0f / 255.0f alpha:1.0], @"purple"              ,
                   [UIColor colorWithRed:255.0f / 255.0f green:  0.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"red"                 ,
                   [UIColor colorWithRed:188.0f / 255.0f green:143.0f / 255.0f blue:143.0f / 255.0f alpha:1.0], @"rosybrown"           ,
                   [UIColor colorWithRed: 65.0f / 255.0f green:105.0f / 255.0f blue:225.0f / 255.0f alpha:1.0], @"royalblue"           ,
                   [UIColor colorWithRed:139.0f / 255.0f green: 69.0f / 255.0f blue: 19.0f / 255.0f alpha:1.0], @"saddlebrown"         ,
                   [UIColor colorWithRed:250.0f / 255.0f green:128.0f / 255.0f blue:114.0f / 255.0f alpha:1.0], @"salmon"              ,
                   [UIColor colorWithRed:244.0f / 255.0f green:164.0f / 255.0f blue: 96.0f / 255.0f alpha:1.0], @"sandybrown"          ,
                   [UIColor colorWithRed: 46.0f / 255.0f green:139.0f / 255.0f blue: 87.0f / 255.0f alpha:1.0], @"seagreen"            ,
                   [UIColor colorWithRed:255.0f / 255.0f green:245.0f / 255.0f blue:238.0f / 255.0f alpha:1.0], @"seashell"            ,
                   [UIColor colorWithRed:160.0f / 255.0f green: 82.0f / 255.0f blue: 45.0f / 255.0f alpha:1.0], @"sienna"              ,
                   [UIColor colorWithRed:192.0f / 255.0f green:192.0f / 255.0f blue:192.0f / 255.0f alpha:1.0], @"silver"              ,
                   [UIColor colorWithRed:135.0f / 255.0f green:206.0f / 255.0f blue:235.0f / 255.0f alpha:1.0], @"skyblue"             ,
                   [UIColor colorWithRed:106.0f / 255.0f green: 90.0f / 255.0f blue:205.0f / 255.0f alpha:1.0], @"slateblue"           ,
                   [UIColor colorWithRed:112.0f / 255.0f green:128.0f / 255.0f blue:144.0f / 255.0f alpha:1.0], @"slategray"           ,
                   [UIColor colorWithRed:112.0f / 255.0f green:128.0f / 255.0f blue:144.0f / 255.0f alpha:1.0], @"slategrey"           ,
                   [UIColor colorWithRed:255.0f / 255.0f green:250.0f / 255.0f blue:250.0f / 255.0f alpha:1.0], @"snow"                ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:255.0f / 255.0f blue:127.0f / 255.0f alpha:1.0], @"springgreen"         ,
                   [UIColor colorWithRed: 70.0f / 255.0f green:130.0f / 255.0f blue:180.0f / 255.0f alpha:1.0], @"steelblue"           ,
                   [UIColor colorWithRed:210.0f / 255.0f green:180.0f / 255.0f blue:140.0f / 255.0f alpha:1.0], @"tan"                 ,
                   [UIColor colorWithRed:  0.0f / 255.0f green:128.0f / 255.0f blue:128.0f / 255.0f alpha:1.0], @"teal"                ,
                   [UIColor colorWithRed:216.0f / 255.0f green:191.0f / 255.0f blue:216.0f / 255.0f alpha:1.0], @"thistle"             ,
                   [UIColor colorWithRed:255.0f / 255.0f green: 99.0f / 255.0f blue: 71.0f / 255.0f alpha:1.0], @"tomato"              ,
                   [UIColor colorWithRed: 64.0f / 255.0f green:224.0f / 255.0f blue:208.0f / 255.0f alpha:1.0], @"turquoise"           ,
                   [UIColor colorWithRed:238.0f / 255.0f green:130.0f / 255.0f blue:238.0f / 255.0f alpha:1.0], @"violet"              ,
                   [UIColor colorWithRed:245.0f / 255.0f green:222.0f / 255.0f blue:179.0f / 255.0f alpha:1.0], @"wheat"               ,
                   [UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0], @"white"               ,
                   [UIColor colorWithRed:245.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0], @"whitesmoke"          ,
                   [UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:  0.0f / 255.0f alpha:1.0], @"yellow"              ,
                   [UIColor colorWithRed:154.0f / 255.0f green:205.0f / 255.0f blue: 50.0f / 255.0f alpha:1.0], @"yellowgreen"         ,
                   nil];
    });
    
    return [colours objectForKey:colourName];
}

extern char styleKey;

- (NSDictionary *)sortedObjects:(NSSet *)objects
{
    NSMutableDictionary *layers = [NSMutableDictionary dictionaryWithCapacity:5];
    for (OSPAPIObject *object in objects)
    {
        NSNumber *layerNumber = [NSNumber numberWithInt:[[[object tags] objectForKey:@"layer"] intValue]];
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
        [layers setObject:[layerObjects sortedArrayUsingComparator:^ NSComparisonResult (OSPAPIObject *o1, OSPAPIObject *o2)
                           {
                               NSDictionary *o1s = objc_getAssociatedObject(o1, &styleKey);
                               NSDictionary *o2s = objc_getAssociatedObject(o2, &styleKey);
                               Specifier *z1s = [o1s objectForKey:@"z-index"];
                               Specifier *z2s = [o2s objectForKey:@"z-index"];
                               float z1 = [z1s isKindOfClass:[SizeListSpecifier class]] ? [(MapCSSSize *)[[(SizeListSpecifier *)z1s sizes] objectAtIndex:0] value] : 0.0f;
                               float z2 = [z2s isKindOfClass:[SizeListSpecifier class]] ? [(MapCSSSize *)[[(SizeListSpecifier *)z2s sizes] objectAtIndex:0] value] : 0.0f;
                               
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
        for (OSPAPIObject *object in layer)
        {
            if ([object isKindOfClass:[OSPWay class]])
            {
                [self renderCasing:(OSPWay *)object inContext:ctx withScaleMultiplier:scale];
            }
        }
        for (OSPAPIObject *object in layer)
        {
            if ([object isKindOfClass:[OSPWay class]])
            {
                [self renderWay:(OSPWay *)object inContext:ctx withScaleMultiplier:scale];
            }
        }
    }
}

extern char styleKey;

- (void)renderCasing:(OSPWay *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = objc_getAssociatedObject(way, &styleKey);
    
    NSArray *nodes = [way nodes];
    Specifier *widthSpec = [style objectForKey:@"width"];
    Specifier *casingWidthSpec = [style objectForKey:@"casing-width"];
    
    if ([nodes count] > 1 && [widthSpec isKindOfClass:[SizeListSpecifier class]] && [casingWidthSpec isKindOfClass:[SizeListSpecifier class]])
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
        
        CGContextSetLineWidth(ctx, ([(MapCSSSize *)[[(SizeListSpecifier *)widthSpec sizes] objectAtIndex:0] value] + [(MapCSSSize *)[[(SizeListSpecifier *)casingWidthSpec sizes] objectAtIndex:0] value]) * scale);
        UIColor *colour = [self colourWithColourSpecifier:[style objectForKey:@"casing-color"] opacitySpecifier:[style objectForKey:@"casing-opacity"]];
        CGContextSetStrokeColorWithColor(ctx, colour == nil ? [[UIColor blackColor] CGColor] : [colour CGColor]);
        Specifier *lineCapSpec = [style objectForKey:@"casing-linecap"];
        CGContextSetLineCap(ctx, [lineCapSpec isKindOfClass:[NamedSpecifier class]] ? CGLineCapFromNSString([(NamedSpecifier *)lineCapSpec name]) : kCGLineCapRound);
        Specifier *lineJoinSpec = [style objectForKey:@"casing-linejoin"];
        CGContextSetLineJoin(ctx, [lineJoinSpec isKindOfClass:[NamedSpecifier class]] ? CGLineJoinFromNSString([(NamedSpecifier *)lineJoinSpec name]) : kCGLineJoinRound);
        
        Specifier *dashSpec = [style objectForKey:@"casing-dashes"];
        if ([dashSpec isKindOfClass:[SizeListSpecifier class]])
        {
            SizeListSpecifier *dashSizeSpec = (SizeListSpecifier *)dashSpec;
            CGFloat *dashes = malloc([[dashSizeSpec sizes] count]);
            int i = 0;
            for (MapCSSSize *size in [dashSizeSpec sizes])
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

- (void)renderWay:(OSPWay *)way inContext:(CGContextRef)ctx withScaleMultiplier:(CGFloat)scale
{
    NSDictionary *style = objc_getAssociatedObject(way, &styleKey);
    
    NSArray *nodes = [way nodes];
    Specifier *widthSpec = [style objectForKey:@"width"];
    UIColor *fillColour = [self colourWithColourSpecifier:[style objectForKey:@"fill-color"] opacitySpecifier:[style objectForKey:@"fill-opacity"]];
    
    UIImage *fillImage = [self imageWithSpecifier:[style objectForKey:@"fill-image"]];
    UIImage *strokeImage = [self imageWithSpecifier:[style objectForKey:@"image"]];
    
    BOOL strokeValid = [widthSpec isKindOfClass:[SizeListSpecifier class]];
    BOOL fillValid = fillColour != nil || fillImage != nil;
    
    if ([nodes count] > 1 && (strokeValid || fillValid))
    {
        OSPMap *m = [way map];
        NSNumber *firstNodeId = [nodes objectAtIndex:0];
        OSPNode *firstNode = [m nodeWithId:[firstNodeId integerValue]];
        OSPCoordinate2D l = [firstNode projectedLocation];
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, l.x, l.y);
        for (NSNumber *nodeId in [nodes subarrayWithRange:NSMakeRange(1, [nodes count] - 1)])
        {
            OSPNode *node = [m nodeWithId:[nodeId integerValue]];
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
            CGContextSetLineWidth(ctx, [(MapCSSSize *)[[(SizeListSpecifier *)widthSpec sizes] objectAtIndex:0] value] * scale);
            if (nil == strokeImage)
            {
                CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB();
                CGContextSetFillColorSpace(ctx, rgbSpace);
                CGColorSpaceRelease(rgbSpace);
                UIColor *colour = [self colourWithColourSpecifier:[style objectForKey:@"color"] opacitySpecifier:[style objectForKey:@"opacity"]];
                CGContextSetStrokeColorWithColor(ctx, colour == nil ? [[UIColor blackColor] CGColor] : [colour CGColor]);
                Specifier *lineCapSpec = [style objectForKey:@"linecap"];
                CGContextSetLineCap(ctx, [lineCapSpec isKindOfClass:[NamedSpecifier class]] ? CGLineCapFromNSString([(NamedSpecifier *)lineCapSpec name]) : kCGLineCapRound);
                Specifier *lineJoinSpec = [style objectForKey:@"linejoin"];
                CGContextSetLineJoin(ctx, [lineJoinSpec isKindOfClass:[NamedSpecifier class]] ? CGLineJoinFromNSString([(NamedSpecifier *)lineJoinSpec name]) : kCGLineJoinRound);
                
                Specifier *dashSpec = [style objectForKey:@"dashes"];
                if ([dashSpec isKindOfClass:[SizeListSpecifier class]])
                {
                    SizeListSpecifier *dashSizeSpec = (SizeListSpecifier *)dashSpec;
                    CGFloat *dashes = malloc([[dashSizeSpec sizes] count]);
                    int i = 0;
                    for (MapCSSSize *size in [dashSizeSpec sizes])
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
}

- (UIImage *)imageWithSpecifier:(Specifier *)spec
{
    if ([spec isKindOfClass:[URLSpecifier class]])
    {
        Url *u = [(URLSpecifier *)spec url];
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

