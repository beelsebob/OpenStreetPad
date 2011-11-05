//
//  CommaSize.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "CommaSize.h"

@implementation CommaSize

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    return [[syntaxTree children] objectAtIndex:1];
}

@end
