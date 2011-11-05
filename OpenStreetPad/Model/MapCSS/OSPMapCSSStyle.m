//
//  Style.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSStyle.h"

@implementation OSPMapCSSStyle

@synthesize key;
@synthesize specifier;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        CPSyntaxTree *styledef = [[syntaxTree children] objectAtIndex:0];
        
        [self setKey:[[[styledef children] objectAtIndex:0] key]];
        [self setSpecifier:[[styledef children] objectAtIndex:2]];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@;", [self key], [self specifier]];
}

@end
