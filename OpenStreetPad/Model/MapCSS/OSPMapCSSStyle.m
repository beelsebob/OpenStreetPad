//
//  Style.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSStyle.h"

#import "OSPMapCSSRule.h"

@implementation OSPMapCSSStyle

@synthesize containsRule;
@synthesize rule;
@synthesize exit;
@synthesize key;
@synthesize specifiers;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        id styledef = [syntaxTree children][0];
        
        if ([styledef isKindOfClass:[OSPMapCSSRule class]])
        {
            [self setContainsRule:YES];
            [self setRule:styledef];
        }
        else
        {
            [self setExit:[[styledef children][0] isKindOfClass:[CPKeywordToken class]]];
            if (![self isExit])
            {
                [self setKey:[[styledef children][0] key]];
                [self setSpecifiers:[styledef children][2]];
            }
        }
    }
    
    return self;
}

- (NSString *)description
{
    return [self isExit] ? @"exit" : [NSString stringWithFormat:@"%@: %@;", [self key], [self specifiers]];
}

@end
