//
//  Style.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSStyle.h"

@implementation OSPMapCSSStyle

@synthesize exit;
@synthesize key;
@synthesize specifiers;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        CPSyntaxTree *styledef = [[syntaxTree children] objectAtIndex:0];
        
        [self setExit:[[[styledef children] objectAtIndex:0] isKindOfClass:[CPKeywordToken class]]];
        if (![self isExit])
        {
            [self setKey:[[[styledef children] objectAtIndex:0] key]];
            [self setSpecifiers:[[styledef children] objectAtIndex:2]];
        }
    }
    
    return self;
}

- (NSString *)description
{
    return [self isExit] ? @"exit" : [NSString stringWithFormat:@"%@: %@;", [self key], [self specifiers]];
}

@end
