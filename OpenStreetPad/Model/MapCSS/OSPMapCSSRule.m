//
//  Rule.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSRule.h"

#import "OSPMapCSSSubselector.h"
#import "OSPMapCSSDeclaration.h"

#import "OSPAPIObjectReference.h"
#import "OSPMap.h"

#import "OSPMapCSSStyle.h"

#import "OSPMapCSSStyleSheet.h"

#import "OSPMapCSSTagSpecifier.h"

#import <objc/runtime.h>

@interface OSPMapCSSRule ()

- (BOOL)selector:(NSArray *)selector matchesObject:(OSPAPIObject *)object;

@end

@implementation OSPMapCSSRule

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
        for (OSPMapCSSSubselector *subselector in selector)
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
    
    for (OSPMapCSSDeclaration *decl in [self declarations])
    {
        [desc appendFormat:@"%@\n", decl];
    }
    return desc;
}

extern char styleKey;

- (NSDictionary *)applyToObjcet:(OSPAPIObject *)object
{
    BOOL matched = NO;
    
    for (NSArray *selector in [self selectors])
    {
        if ([self selector:selector matchesObject:object])
        {
            matched = YES;
            break;
        }
    }
    
    if (matched)
    {
        NSMutableDictionary *style = [[NSMutableDictionary alloc] init];
        for (OSPMapCSSDeclaration *decl in [self declarations])
        {
            for (OSPMapCSSStyle *st in [decl styles])
            {
                OSPMapCSSSpecifier *spec = [st specifier];
                if ([spec isKindOfClass:[OSPMapCSSTagSpecifier class]])
                {
                    spec = [(OSPMapCSSTagSpecifier *)spec specifierWithAPIObject:object];
                }
                if (nil != spec)
                {
                    [style setObject:spec forKey:[[st key] description]];
                }
            }
        }
        return [style copy];
    }
    
    return [NSDictionary dictionary];
}

- (BOOL)selector:(NSArray *)selector matchesObject:(OSPAPIObject *)object
{
    NSUInteger c = [selector count];
    
    if (c == 1)
    {
        return [[selector objectAtIndex:0] matchesObject:object];
    }
    else if (c > 0)
    {
        if ([[selector lastObject] matchesObject:object])
        {
            OSPMap *m = [object map];
            for (OSPAPIObjectReference *parent in [object parents])
            {
                if ([self selector:[selector subarrayWithRange:NSMakeRange(0, c - 1)]
                     matchesObject:[m apiObjectOfType:[parent memberType] withId:[parent identity]]])
                {
                    return YES;
                }
            }
            return NO;
        }
        else
        {
            return NO;
        }
    }
    else
    {
        return YES;
    }
}

@end
