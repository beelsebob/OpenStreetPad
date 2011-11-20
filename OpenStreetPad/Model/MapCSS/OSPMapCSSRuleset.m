//
//  Ruleset.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSRuleset.h"

#import "OSPMapCSSRule.h"
#import "OSPMapCSSSubselector.h"
#import "OSPMapCSSDeclaration.h"
#import "OSPMapCSSStyle.h"

@implementation OSPMapCSSRuleset

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
    NSMutableDictionary *style = [NSMutableDictionary dictionary];
    for (id rule in [self rules])
    {
        if ([rule isKindOfClass:[OSPMapCSSRule class]])
        {
            [style addEntriesFromDictionary:[rule applyToObjcet:object]];
        }
    }
    return style;
}

- (NSDictionary *)styleForCanvas
{
    for (id rule in [self rules])
    {
        if ([rule isKindOfClass:[OSPMapCSSRule class]])
        {
            BOOL matches = NO;
            for (NSArray *selector in [rule selectors])
            {
                if ([selector count] == 1 && [[selector objectAtIndex:0] objectType] == OSPMapCSSObjectTypeCanvas)
                {
                    matches = YES;
                }
            }
            
            if (matches)
            {
                NSMutableDictionary *style = [[NSMutableDictionary alloc] init];
                for (OSPMapCSSDeclaration *decl in [rule declarations])
                {
                    for (OSPMapCSSStyle *st in [decl styles])
                    {
                        [style setObject:[st specifier] forKey:[[st key] description]];
                    }
                }
                return [style copy];
            }
        }
    }
    return [NSDictionary dictionary];
}

@end
