//
//  CommaSelector.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "CommaSelector.h"

@implementation CommaSelector

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    return [[[[syntaxTree children] objectAtIndex:1] children] objectAtIndex:0];
}

@end
