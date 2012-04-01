//
//  Rule.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSRule.h"

#import "OSPMapCSSSelector.h"
#import "OSPMapCSSDeclaration.h"

#import "OSPAPIObjectReference.h"
#import "OSPMap.h"

#import "OSPMapCSSStyle.h"

#import "OSPMapCSSStyleSheet.h"

#import "OSPMapCSSSpecifierList.h"
#import "OSPMapCSSTagSpecifier.h"

#import <objc/runtime.h>

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
            [self setSelectors:[[NSArray arrayWithObject:[[syntaxTree children] objectAtIndex:0]] arrayByAddingObjectsFromArray:[[syntaxTree children] objectAtIndex:1]]];
            [self setDeclarations:[[syntaxTree children] objectAtIndex:2]];
        }
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString string];
    
    for (OSPMapCSSSelector *selector in [self selectors])
    {
        [desc appendFormat:@"%@,\n", [selector description]];
    }
    
    for (OSPMapCSSDeclaration *decl in [self declarations])
    {
        [desc appendFormat:@"%@\n", decl];
    }
    return desc;
}

extern char styleKey;

- (NSDictionary *)applyToObject:(OSPAPIObject *)object atZoom:(float)zoom
{
    NSMutableArray *matchingLayerIdentifiers = [NSMutableArray array];
    
    for (OSPMapCSSSelector *selector in [self selectors])
    {
        if ([selector matchesObject:object atZoom:zoom])
        {
            [matchingLayerIdentifiers addObject:[selector layerIdentifier]];
        }
    }
    
    if ([matchingLayerIdentifiers count] > 0)
    {
        NSMutableDictionary *style = [NSMutableDictionary dictionary];
        for (OSPMapCSSDeclaration *decl in [self declarations])
        {
            for (OSPMapCSSStyle *st in [decl styles])
            {
                OSPMapCSSSpecifierList *specList = [st specifiers];
                NSMutableArray *processedSpecifiers = [NSMutableArray arrayWithCapacity:[[specList specifiers] count]];
                for (OSPMapCSSSpecifier *spec in [specList specifiers])
                {
                    if ([spec isKindOfClass:[OSPMapCSSTagSpecifier class]])
                    {
                        OSPMapCSSSpecifier *newSpec = [(OSPMapCSSTagSpecifier *)spec specifierWithAPIObject:object];
                        if (nil != newSpec)
                        {
                            [processedSpecifiers addObject:newSpec];
                        }
                    }
                    else
                    {
                        [processedSpecifiers addObject:spec];
                    }
                }
                if ([processedSpecifiers count] > 0)
                {
                    OSPMapCSSSpecifierList *newList = [[OSPMapCSSSpecifierList alloc] init];
                    [newList setSpecifiers:processedSpecifiers];
                    [style setObject:newList forKey:[[st key] description]];
                }
            }
        }
        
        NSDictionary *st = [style copy];
        NSMutableDictionary *layerIdentifiers = [NSMutableDictionary dictionaryWithCapacity:[matchingLayerIdentifiers count]];
        for (NSString *layerIdentifier in matchingLayerIdentifiers)
        {
            [layerIdentifiers setObject:st forKey:layerIdentifier];
        }
        
        return layerIdentifiers;
    }
    
    return [NSDictionary dictionary];
}

@end
