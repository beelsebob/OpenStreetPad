//
//  CommaSize.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSCommaSize.h"

@implementation OSPMapCSSCommaSize

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    return [[syntaxTree children] objectAtIndex:1];
}

@end
