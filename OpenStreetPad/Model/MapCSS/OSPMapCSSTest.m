//
//  Test.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSTest.h"

#import "OSPMapCSSPlaceholderTest.h"

@implementation OSPMapCSSTest

+ (id)allocWithZone:(NSZone *)zone
{
    return self == [OSPMapCSSTest class] ? [OSPMapCSSPlaceholderTest allocWithZone:zone] : [super allocWithZone:zone];
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
