//
//  Ruleset.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Ruleset.h"

#import "Rule.h"

@implementation Ruleset

@synthesize rules;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRules:[[syntaxTree children] objectAtIndex:0]];
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *ruleset = [NSMutableString string];
    
    for (id rule in [self rules])
    {
        [ruleset appendFormat:@"%@\n", rule];
    }
    
    return ruleset;
}

- (NSDictionary *)applyToObjcet:(OSPAPIObject *)object
{
    NSMutableDictionary *currentStyle = [NSMutableDictionary dictionary];
    
    for (id rule in [self rules])
    {
        if ([rule isKindOfClass:[Rule class]])
        {
            [rule applyToObjcet:object addingToStyle:currentStyle];
        }
    }
    
    return [currentStyle copy];
}

@end
