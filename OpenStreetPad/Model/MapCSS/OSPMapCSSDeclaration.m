//
//  Declaration.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSDeclaration.h"

#import "OSPMapCSSStyle.h"

@implementation OSPMapCSSDeclaration

@synthesize styles;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        if ([[syntaxTree children] count] == 3)
        {
            [self setStyles:[[syntaxTree children] objectAtIndex:1]];
        }
        else
        {
            [self setStyles:[NSArray array]];
        }
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:@"{\n"];
    
    for (OSPMapCSSStyle *style in [self styles])
    {
        [desc appendFormat:@"  %@\n", style];
    }
    [desc appendString:@"}"];
    return desc;
}

@end
