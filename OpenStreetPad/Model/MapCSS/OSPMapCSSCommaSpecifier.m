//
//  OSPMapCSCommaSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSCommaSpecifier.h"

@implementation OSPMapCSSCommaSpecifier

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    return [[syntaxTree children] objectAtIndex:1];
}

@end
