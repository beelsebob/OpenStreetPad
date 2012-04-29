//
//  Subselector.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSubselector.h"

#import "OSPMapCSSZoom.h"
#import "OSPMapCSSTest.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"

#import "NSString+OpenStreetPad.h"

@interface OSPMapCSSSubselector ()

- (BOOL)typeMatchesObject:(OSPAPIObject *)object;
- (BOOL)testsMatchObject:(OSPAPIObject *)object;

@end

@implementation OSPMapCSSSubselector

@synthesize objectType;
@synthesize constrainedToZoomRange;
@synthesize minimumZoom;
@synthesize maximumZoom;
@synthesize tests;
@synthesize requiredClass;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        OSPMapCSSObject *first = [[syntaxTree children] objectAtIndex:0];
        [self setObjectType:[first objectType]];
        id second = [[syntaxTree children] objectAtIndex:1];
        if ([second isKindOfClass:[CPWhiteSpaceToken class]] )
        {
            if ([[syntaxTree children] count] == 2)
            {
                [self setConstrainedToZoomRange:NO];
                [self setTests:[NSArray array]];
                [self setRequiredClass:nil];
            }
            else
            {
                [self setConstrainedToZoomRange:NO];
                [self setTests:nil];
                [self setRequiredClass:[[syntaxTree children] objectAtIndex:1]];
            }
        }
        else if ([second isKindOfClass:[OSPMapCSSZoom class]])
        {
            [self setConstrainedToZoomRange:YES];
            [self setMinimumZoom:[(OSPMapCSSZoom *)second minimumZoom]];
            [self setMaximumZoom:[(OSPMapCSSZoom *)second maximumZoom]];
            [self setTests:[[syntaxTree children] objectAtIndex:2]];
            [self setRequiredClass:nil];
        }
        else
        {
            [self setConstrainedToZoomRange:NO];
            [self setTests:[[syntaxTree children] objectAtIndex:1]];
            [self setRequiredClass:nil];
        }
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:NSStringFromOSPMapCSSObjectType([self objectType])];
    
    if (nil != [self requiredClass])
    {
        [desc appendFormat:@" %@", [self requiredClass]];
    }
    else
    {
        if ([self isConstrainedToZoomRange])
        {
            [desc appendFormat:@"|z%1.1f-%1.1f", [self minimumZoom], [self maximumZoom]];
        }
        
        for (OSPMapCSSTest *test in [self tests])
        {
            [desc appendFormat:@"%@", test];
        }
    }
    
    return desc;
}

- (BOOL)matchesObject:(OSPAPIObject *)object atZoom:(float)zoom
{
    return ((!constrainedToZoomRange || ((minimumZoom < 0.0f || minimumZoom <= zoom) && (maximumZoom < 0.0f || maximumZoom >= zoom))) &&
            [self typeMatchesObject:object] &&
            [self testsMatchObject:object]);
}

- (BOOL)zoomIsInRange:(float)zoom
{
    return !constrainedToZoomRange || ((minimumZoom < 0.0f || minimumZoom <= zoom) && (maximumZoom < 0.0f || maximumZoom >= zoom));
}

- (BOOL)typeMatchesObject:(OSPAPIObject *)object
{
    OSPMemberType t = [object memberType];
    switch (objectType)
    {
        case OSPMapCSSObjectTypeNode:
            return t == OSPMemberTypeNode;
        case OSPMapCSSObjectTypeWay:
            return t == OSPMemberTypeWay;
        case OSPMapCSSObjectTypeRelation:
            return t == OSPMemberTypeRelation;
        case OSPMapCSSObjectTypeLine:
            if (t == OSPMemberTypeWay)
            {
                if (![[[object tags] objectForKey:@"area"] ospTruthValue])
                {
                    return YES;
                }
                NSArray *nodes = [(OSPWay *)object nodes];
                return [[nodes objectAtIndex:0] integerValue] != [[nodes lastObject] integerValue];
            }
            return NO;
        case OSPMapCSSObjectTypeArea:
            if (t == OSPMemberTypeWay)
            {
                if ([[[object tags] objectForKey:@"area"] ospTruthValue])
                {
                    return YES;
                }
                NSArray *nodes = [(OSPWay *)object nodes];
                return [[nodes objectAtIndex:0] integerValue] == [[nodes lastObject] integerValue];
            }
            return NO;
        case OSPMapCSSObjectTypeAll:
            return YES;
        case OSPMapCSSObjectTypeCanvas:
        case OSPMapCSSObjectTypeMeta:
            return NO;
    }
}

- (BOOL)testsMatchObject:(OSPAPIObject *)object
{
    for (OSPMapCSSTest *t in tests)
    {
        if (![t matchesObject:object])
        {
            return NO;
        }
    }
    
    return YES;
}

@end
