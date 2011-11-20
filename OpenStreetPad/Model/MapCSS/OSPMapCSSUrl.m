//
//  Url.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSUrl.h"

#import "OSPMapCSSEval.h"

@implementation OSPMapCSSUrl

@synthesize eval;
@synthesize content;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        id zerothChild = [[syntaxTree children] objectAtIndex:0];
        [self setEval:![zerothChild isKindOfClass:[CPKeywordToken class]]];
        if ([self isEval])
        {
            id child = [[zerothChild children] objectAtIndex:0];
            [self setContent:child];
        }
        else
        {
            [self setContent:[[[[[syntaxTree children] objectAtIndex:2] children] objectAtIndex:0] content]];
        }
    }
    
    return self;
}

- (NSString *)description
{
    if ([self isEval])
    {
        return [NSString stringWithFormat:@"eval(%@)", [[self content] expression]];
    }
    else
    {
        return [NSString stringWithFormat:@"\"%@\"", [self content]];
    }
}

@end
