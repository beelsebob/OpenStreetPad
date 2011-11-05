//
//  Specifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Specifier.h"

#import "PlaceholderSpecifier.h"

@implementation Specifier

+ (id)allocWithZone:(NSZone *)zone
{
    return (self == [Specifier class]) ? [PlaceholderSpecifier allocWithZone:zone] : [super allocWithZone:zone];
}

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    return [super init];
}

@end
