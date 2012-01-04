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

- (NSArray *)styledObjects:(NSSet *)objects
{
    NSMutableArray *styledObjects = [NSMutableSet setWithCapacity:[objects count]];
    for (OSPAPIObject *object in objects)
    {
        NSArray *sos = objc_getAssociatedObject(object, &styleRef);
        if (nil == sos)
        {
            NSDictionary *style = [[self ruleset] applyToObjcet:object];
            sos = [NSArray arrayWithObjects:[OSPMapCSSStyledObject object:object withStyle:style], nil];
            objc_setAssociatedObject(object, &styleRef, sos, OBJC_ASSOCIATION_RETAIN);
        }
        [styledObjects addObjectsFromArray:sos];
    }
    return styledObjects;
}

- (NSDictionary *)styleForCanvas
{
    return [[self ruleset] styleForCanvas];
}

@end
