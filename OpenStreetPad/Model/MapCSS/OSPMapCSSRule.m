//
//  Rule.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSRule.h"

#import "OSPMapCSSSelector.h"
#import "OSPMapCSSSubselector.h"
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
        NSArray *c = [syntaxTree children];
        if ([c count] == 1)
        {
            return c[0];
        }
        else
        {
            NSArray *selectorCommas = c[0];
            NSMutableArray *ses = [NSMutableArray arrayWithCapacity:[selectorCommas count]];
            for (NSArray *t in selectorCommas)
            {
                [ses addObject:t[0]];
            }
            [self setSelectors:ses];
            [self setDeclarations:c[1]];
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

- (NSDictionary *)applyToObject:(OSPAPIObject *)object atZoom:(float)zoom stop:(BOOL *)stop
{
    NSMutableArray *matchingLayerIdentifiers = [NSMutableArray array];
    
    for (OSPMapCSSSelector *selector in selectors)
    {
        if ([selector matchesObject:object atZoom:zoom])
        {
            [matchingLayerIdentifiers addObject:[selector layerIdentifier]];
        }
    }
    
    if ([matchingLayerIdentifiers count] > 0)
    {
        NSMutableDictionary *layerIdentifiers = [NSMutableDictionary dictionaryWithCapacity:[matchingLayerIdentifiers count]];
        for (NSString *layerIdentifier in matchingLayerIdentifiers)
        {
            layerIdentifiers[layerIdentifier] = [NSMutableDictionary dictionary];
        }
        for (OSPMapCSSDeclaration *decl in [self declarations])
        {
            for (OSPMapCSSStyle *st in [decl styles])
            {
                if ([st isExit])
                {
                    *stop = YES;
                }
                else if ([st containsRule])
                {
                    NSDictionary *subStyle = [[st rule] applyToObject:object atZoom:zoom stop:stop];
                    for (NSString *layerIdentifier in matchingLayerIdentifiers)
                    {
                        if ([layerIdentifier isEqualToString:@"default"])
                        {
                            for (NSString *subLayerIdentifier in subStyle)
                            {
                                NSMutableDictionary *d = layerIdentifiers[subLayerIdentifier];
                                NSDictionary *otherD = subStyle[subLayerIdentifier];
                                if (nil == d)
                                {
                                    d = [NSMutableDictionary dictionaryWithCapacity:[otherD count]];
                                    layerIdentifiers[subLayerIdentifier] = d;
                                }
                                [d addEntriesFromDictionary:otherD];
                            }
                        }
                        else
                        {
                            NSMutableDictionary *d = layerIdentifiers[layerIdentifier];
                            [d addEntriesFromDictionary:subStyle[layerIdentifier]];
                            [d addEntriesFromDictionary:subStyle[@"default"]];
                        }
                    }
                }
                else
                {
                    OSPMapCSSSpecifierList *specList = [st specifiers];
                    NSArray *specs = [specList specifiers];
                    NSMutableArray *processedSpecifiers = [NSMutableArray arrayWithCapacity:[specs count]];
                    for (OSPMapCSSSpecifier *spec in specs)
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
                        for (NSString *layerIdentifier in matchingLayerIdentifiers)
                        {
                            layerIdentifiers[layerIdentifier][[st key]] = newList;
                        }
                    }
                }
                if (*stop)
                {
                    break;
                }
            }
            if (*stop)
            {
                break;
            }
        }
        
        return layerIdentifiers;
    }
    
    return @{};
}

- (BOOL)isOnlyMeta
{
    for (OSPMapCSSSelector *selector in selectors)
    {
        if ([[selector subselectors][0] objectType] != OSPMapCSSObjectTypeMeta)
        {
            return NO;
        }
    }
    return YES;
}

@end
