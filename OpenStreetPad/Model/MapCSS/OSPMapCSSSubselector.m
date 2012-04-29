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
#import "OSPMapCSSUnaryTest.h"

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

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        NSArray *c = [syntaxTree children];
        OSPMapCSSObject *first = [c objectAtIndex:0];
        [self setObjectType:[first objectType]];
        id second = [c objectAtIndex:1];
        if ([second isKindOfClass:[CPWhiteSpaceToken class]])
        {
            [self setConstrainedToZoomRange:NO];
            [self setTests:nil];
        }
        else
        {
            NSArray *ts = [c objectAtIndex:2];
            NSArray *pseudoClasses = [c objectAtIndex:3];
            
            if ([(NSArray *)second count] != 0)
            {
                OSPMapCSSZoom *zoom = [second objectAtIndex:0];
                [self setConstrainedToZoomRange:YES];
                [self setMinimumZoom:[zoom minimumZoom]];
                [self setMaximumZoom:[zoom maximumZoom]];
            }
            
            if ([pseudoClasses count] > 0)
            {
                NSMutableArray *mutableTests = [ts mutableCopy];
                
                for (OSPMapCSSClass *c in pseudoClasses)
                {
                    [mutableTests addObject:[[OSPMapCSSUnaryTest alloc] initWithTagName:[NSString stringWithFormat:@":%@", [c className]] negated:![c positive]]];
                }
                
                ts = mutableTests;
            }
            [self setTests:ts];
        }
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:NSStringFromOSPMapCSSObjectType([self objectType])];
    
    if ([self isConstrainedToZoomRange])
    {
        [desc appendFormat:@"|z%1.1f-%1.1f", [self minimumZoom], [self maximumZoom]];
    }
    
    for (OSPMapCSSTest *test in [self tests])
    {
        [desc appendFormat:@"%@", test];
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
