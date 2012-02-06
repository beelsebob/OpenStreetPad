//
//  Specifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSpecifier.h"

#import "OSPMapCSSPlaceholderSpecifier.h"

@implementation OSPMapCSSSpecifier

+ (id)allocWithZone:(NSZone *)zone
{
    return (self == [OSPMapCSSSpecifier class]) ? [OSPMapCSSPlaceholderSpecifier allocWithZone:zone] : [super allocWithZone:zone];
}

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    return [super init];
}

- (NSArray *)values
{
    [NSException exceptionWithName:@"Abstract class exception" reason:@"-values is an abstract method, call it on a subclass" userInfo:nil];
    return nil;
}

@end
