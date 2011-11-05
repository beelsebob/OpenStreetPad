//
//  PlaceholderTest.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 01/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "PlaceholderTest.h"

#import "UnaryTest.h"
#import "BinaryTest.h"

@implementation PlaceholderTest

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    CPSyntaxTree *condition = [[syntaxTree children] objectAtIndex:1];
    switch ([[condition children] count])
    {
        case 1:
        case 2:
            return (id)[[UnaryTest alloc] initWithSyntaxTree:condition];
        case 3:
            return (id)[[BinaryTest alloc] initWithSyntaxTree:condition];
        default:
            return nil;
    }
}

@end
