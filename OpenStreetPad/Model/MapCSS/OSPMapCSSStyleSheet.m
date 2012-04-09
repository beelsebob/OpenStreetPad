//
//  OSPMapCSSStyleSheet.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 05/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSStyleSheet.h"

#import "OSPMapCSSStyledObject.h"

#import "OSPNode.h"

#import <objc/runtime.h>

static char styleRef;
static char oldZoomRef;

@interface OSPMapCSSStyleSheet ()

@property (readwrite, strong) NSMutableDictionary *emptyNodeStyles;

@end

@implementation OSPMapCSSStyleSheet

@synthesize ruleset;
@synthesize emptyNodeStyles;

- (id)initWithRules:(OSPMapCSSRuleset *)initRuleset
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRuleset:initRuleset];
        [self setEmptyNodeStyles:[NSMutableDictionary dictionary]];
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
            NSNumber *zNum = [NSNumber numberWithFloat:zoom];
            if ([object memberType] == OSPMemberTypeNode && [[object tags] count] == 0)
            {
                newStyledObjects = [[self emptyNodeStyles] objectForKey:zNum];
                if (nil == newStyledObjects)
                {
                    NSDictionary *layerStyles = [[self ruleset] applyToObject:object atZoom:zoom];
                    NSMutableArray *sos = [NSMutableArray arrayWithCapacity:[layerStyles count]];
                    for (NSString *layerStyle in layerStyles)
                    {
                        [sos addObject:[OSPMapCSSStyledObject object:object withStyle:[layerStyles objectForKey:layerStyle]]];
                    }
                    newStyledObjects = [sos copy];
                    [[self emptyNodeStyles] setObject:newStyledObjects forKey:zNum];
                }
            }
            else
            {
                NSDictionary *layerStyles = [[self ruleset] applyToObject:object atZoom:zoom];
                NSMutableArray *sos = [NSMutableArray arrayWithCapacity:[layerStyles count]];
                for (NSString *layerStyle in layerStyles)
                {
                    [sos addObject:[OSPMapCSSStyledObject object:object withStyle:[layerStyles objectForKey:layerStyle]]];
                }
                newStyledObjects = [sos copy];
            }
            objc_setAssociatedObject(object, &styleRef, newStyledObjects, OBJC_ASSOCIATION_RETAIN);
            objc_setAssociatedObject(object, &oldZoomRef, zNum, OBJC_ASSOCIATION_RETAIN);
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
