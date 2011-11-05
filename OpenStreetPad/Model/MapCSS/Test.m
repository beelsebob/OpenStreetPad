//
//  Test.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Test.h"

#import "PlaceholderTest.h"

@implementation Test

+ (id)allocWithZone:(NSZone *)zone
{
    return self == [Test class] ? [PlaceholderTest allocWithZone:zone] : [super allocWithZone:zone];
}

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    return [super init];
}

- (BOOL)matchesObject:(OSPAPIObject *)object
{
    return NO;
}

@end
