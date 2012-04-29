//
//  OSPMapCSSSelector.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 01/04/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSelector.h"

#import "OSPMapCSSSubselector.h"

#import "OSPAPIObjectReference.h"

BOOL subSelectorsMatchObjectAtZoom(NSArray *subSelectors, NSInteger lastIndex, OSPAPIObject *object, float zoom);

BOOL subSelectorsMatchObjectAtZoom(NSArray *subSelectors, NSInteger lastIndex, OSPAPIObject *object, float zoom)
{
    if (lastIndex == 0)
    {
        return [[subSelectors objectAtIndex:0] matchesObject:object atZoom:zoom];
    }
        
    if (![[subSelectors objectAtIndex:lastIndex] matchesObject:object atZoom:zoom])
    {
        return NO;
    }
    
    OSPMap *m = [object map];
    for (OSPAPIObjectReference *parent in [object parents])
    {
        if (subSelectorsMatchObjectAtZoom(subSelectors, lastIndex - 1, [m apiObjectOfType:[parent memberType] withId:[parent identity]], zoom))
        {
            return YES;
        }
    }
    
    return NO;
}

@implementation OSPMapCSSSelector

@synthesize subselectors;
@synthesize layerIdentifier;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        NSArray *subSelectors = [[syntaxTree children] objectAtIndex:0];
        NSMutableArray *realSubselectors = [NSMutableArray arrayWithCapacity:[subSelectors count]];
        for (NSArray *a in subSelectors)
        {
            [realSubselectors addObject:[a objectAtIndex:0]];
        }
        [self setSubselectors:realSubselectors];
        NSArray *maybeLayerIdentifier = [[syntaxTree children] objectAtIndex:1];
        if ([maybeLayerIdentifier count] > 0)
        {
            id identifier = [[[maybeLayerIdentifier objectAtIndex:0] children] objectAtIndex:1];
            [self setLayerIdentifier:[identifier isKindOfClass:[CPKeywordToken class]] ? @"*": [identifier identifier]];
        }
        else
        {
            [self setLayerIdentifier:@"default"];
        }
    }
    
    return self;
}

- (BOOL)matchesObject:(OSPAPIObject *)object atZoom:(float)zoom
{
    return subSelectorsMatchObjectAtZoom(subselectors, [subselectors count] - 1, object, zoom);
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString string];
    
    NSUInteger subSelectorNumber = 0;
    for (OSPMapCSSSubselector *subSelector in [self subselectors])
    {
        if (subSelectorNumber < [[self subselectors] count] - 1)
        {
            [desc appendFormat:@"%@ ", subSelector];
        }
        else
        {
            [desc appendString:[subSelector description]];
        }
        subSelectorNumber++;
    }
    
    if (nil != [self layerIdentifier])
    {
        [desc appendFormat:@"::%@", [self layerIdentifier]];
    }
    
    return desc;
}

@end
