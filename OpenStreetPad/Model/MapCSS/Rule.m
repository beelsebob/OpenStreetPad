//
//  Rule.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Rule.h"

#import "Subselector.h"
#import "Declaration.h"

#import "OSPMapCSSStyle.h"

@interface Rule ()

- (void)addObjectsDerivedFrom:(OSPAPIObject *)root matchingSelector:(NSArray *)selector to:(NSMutableArray *)matches;

@end

@implementation Rule

@synthesize selectors;
@synthesize declarations;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        if ([[syntaxTree children] count] == 1)
        {
            return [[syntaxTree children] objectAtIndex:0];
        }
        else
        {
            [self setSelectors:[[NSArray arrayWithObject:[[[[syntaxTree children] objectAtIndex:0] children] objectAtIndex:0]] arrayByAddingObjectsFromArray:[[syntaxTree children] objectAtIndex:1]]];
            [self setDeclarations:[[syntaxTree children] objectAtIndex:2]];
        }
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString string];
    
    for (NSArray *selector in [self selectors])
    {
        NSUInteger subselNumber = 0;
        for (Subselector *subselector in selector)
        {
            if (subselNumber < [selector count] - 1)
            {
                [desc appendFormat:@"%@ ", subselector];
            }
            else
            {
                [desc appendString:[subselector description]];
            }
        }
        [desc appendString:@",\n"];
    }
    
    for (Declaration *decl in [self declarations])
    {
        [desc appendFormat:@"%@\n", decl];
    }
    return desc;
}

- (void)applyToObjcet:(OSPAPIObject *)object addingToStyle:(NSMutableDictionary *)style
{
    NSMutableArray *matchingObjects = [NSMutableArray array];
    
    for (NSArray *selector in [self selectors])
    {
        [self addObjectsDerivedFrom:object matchingSelector:selector to:matchingObjects];
    }
    
/*    for (OSPAPIObject *o in matchingObjects)
    {*/
    if ([matchingObjects containsObject:object])
    {
        for (Declaration *decl in [self declarations])
        {
            for (OSPMapCSSStyle *st in [decl styles])
            {
                [style setObject:[st specifier] forKey:[[st key] description]];
            }
        }
    }
}

- (void)addObjectsDerivedFrom:(OSPAPIObject *)root matchingSelector:(NSArray *)selector to:(NSMutableArray *)matches
{
    NSUInteger c = [selector count];
    if (c == 1)
    {
        if ([[selector objectAtIndex:0] matchesObject:root])
        {
            [matches addObject:root];
        }
    }
    else if (c > 0)
    {
        if ([[selector objectAtIndex:0] matchesObject:root])
        {
            NSSet *children = [root childObjects];
            for (OSPAPIObject *o in children)
            {
                [self addObjectsDerivedFrom:o matchingSelector:[selector subarrayWithRange:NSMakeRange(1, c - 1)] to:matches];
            }
        }
    }
}

@end
