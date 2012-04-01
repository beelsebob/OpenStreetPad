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

- (NSArray *)styledObjects:(NSSet *)objects atZoom:(float)zoom
{
    NSMutableArray *styledObjects = [NSMutableSet setWithCapacity:[objects count]];
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
            NSDictionary *style = [[self ruleset] applyToObjcet:object atZoom:zoom];
            newStyledObjects = [NSArray arrayWithObjects:[OSPMapCSSStyledObject object:object withStyle:style], nil];
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
