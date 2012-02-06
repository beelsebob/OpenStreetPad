//
//  NamedSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSNamedSpecifier.h"

@implementation OSPMapCSSNamedSpecifier

@synthesize name;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        [self setName:[[[syntaxTree children] objectAtIndex:0] name]];
    }
    
    return self;
}

- (id)initWithName:(NSString *)initName
{
    self = [super init];
    
    if (nil != self)
    {
        [self setName:initName];
    }
    
    return self;
}

- (NSString *)description
{
    return [self name];
}

- (NSArray *)values
{
    return [NSArray arrayWithObject:[[self name] copy]];
}

@end
