//
//  OSPMapCSSStyleSheet.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 05/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSStyleSheet.h"

#import "OSPMapCSSStyledObject.h"

#import <objc/runtime.h>

static char styleRef;
static char oldZoomRef;

@implementation OSPMapCSSStyleSheet

@synthesize ruleset;

- (id)initWithRules:(OSPMapCSSRuleset *)initRuleset
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRuleset:initRuleset];
    }
    
    return self;
}

- (void)loadImportsRelativeToURL:(NSURL *)baseURL
{
    [[self ruleset] loadImportsRelativeToURL:baseURL];
}

- (NSArray *)styledObjects:(NSSet *)objects atZoom:(float)zoom
{
    NSMutableArray *styledObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    for (OSPAPIObject *object in objects)
    {
        NSNumber *cachedStyleZoom = objc_getAssociatedObject(object, &oldZoomRef);
        NSArray *newStyledObjects = nil;
        if ([cachedStyleZoom floatValue] == zoom)
        {
            newStyledObjects = objc_getAssociatedObject(object, &styleRef);
        }
        if (nil == newStyledObjects)
        {
            NSDictionary *layerStyles = [[self ruleset] applyToObject:object atZoom:zoom];
            NSMutableArray *sos = [NSMutableArray arrayWithCapacity:[layerStyles count]];
            for (NSString *layerStyle in layerStyles)
            {
                [sos addObject:[OSPMapCSSStyledObject object:object withStyle:[layerStyles objectForKey:layerStyle]]];
            }
            newStyledObjects = [sos copy];
            objc_setAssociatedObject(object, &styleRef, newStyledObjects, OBJC_ASSOCIATION_RETAIN);
            objc_setAssociatedObject(object, &oldZoomRef, [NSNumber numberWithFloat:zoom], OBJC_ASSOCIATION_RETAIN);
        }
        [styledObjects addObjectsFromArray:newStyledObjects];
    }
    return styledObjects;
}

- (NSDictionary *)styleForCanvasAtZoom:(float)zoom
{
    return [[self ruleset] styleForCanvasAtZoom:zoom];
}

@end
