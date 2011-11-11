//
//  OSPMapCSSStyleSheet.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 05/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSStyleSheet.h"

#import <objc/runtime.h>

char styleKey;


@implementation OSPMapCSSStyleSheet

@synthesize ruleset;

- (id)initWithRules:(Ruleset *)initRuleset
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRuleset:initRuleset];
    }
    
    return self;
}

- (void)styleObjects:(NSSet *)objects
{
    for (OSPAPIObject *object in objects)
    {
        id style = objc_getAssociatedObject(object, &styleKey);
        
        if (nil == style)
        {
            objc_setAssociatedObject(object, &styleKey, [[self ruleset] applyToObjcet:object], OBJC_ASSOCIATION_RETAIN);
        }
    }
}

- (NSDictionary *)styleForCanvas
{
    return [[self ruleset] styleForCanvas];
}

@end
