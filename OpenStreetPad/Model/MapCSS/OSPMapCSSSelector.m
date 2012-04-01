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

@interface OSPMapCSSSelector ()

- (BOOL)subSelectors:(NSArray *)subSelectors matchObject:(OSPAPIObject *)object atZoom:(float)zoom;

@end

@implementation OSPMapCSSSelector

@synthesize subselectors;
@synthesize layerIdentifier;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setSubselectors:[[syntaxTree children] objectAtIndex:0]];
        NSArray *maybeLayerIdentifier = [[syntaxTree children] objectAtIndex:1];
        [self setLayerIdentifier:[maybeLayerIdentifier count] > 0 ? [[[[maybeLayerIdentifier objectAtIndex:0] children] objectAtIndex:1] identifier] : @"default"];
    }
    
    return self;
}

- (BOOL)matchesObject:(OSPAPIObject *)object atZoom:(float)zoom
{
    return [self subSelectors:[self subselectors] matchObject:object atZoom:zoom];
}

- (BOOL)subSelectors:(NSArray *)subSelectors matchObject:(OSPAPIObject *)object atZoom:(float)zoom
{
    NSUInteger c = [subSelectors count];
    
    if (c == 1)
    {
        return [[subSelectors objectAtIndex:0] matchesObject:object atZoom:zoom];
    }
    else if (c > 0)
    {
        if ([[subSelectors lastObject] matchesObject:object atZoom:zoom])
        {
            OSPMap *m = [object map];
            for (OSPAPIObjectReference *parent in [object parents])
            {
                if ([self subSelectors:[subSelectors subarrayWithRange:NSMakeRange(0, c - 1)]
                           matchObject:[m apiObjectOfType:[parent memberType] withId:[parent identity]]
                                atZoom:zoom])
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
