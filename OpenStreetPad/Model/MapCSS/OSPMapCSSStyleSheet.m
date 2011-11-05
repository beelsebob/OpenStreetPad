//
//  OSPMapCSSStyleSheet.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 05/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSStyleSheet.h"

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

- (NSDictionary *)stylesForObject:(OSPAPIObject *)apiObject
{
    return [[self ruleset] applyToObjcet:apiObject];
}

@end
