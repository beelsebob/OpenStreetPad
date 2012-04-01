//
//  CommaSelector.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSCommaSelector.h"

@implementation OSPMapCSSCommaSelector

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    return [[syntaxTree children] objectAtIndex:1];
}

@end
