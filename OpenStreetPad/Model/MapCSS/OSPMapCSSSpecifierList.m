//
//  OSPMapCSSSpecifierList.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSpecifierList.h"

#import "OSPMapCSSSpecifier.h"

@implementation OSPMapCSSSpecifierList

@synthesize specifiers;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        NSMutableArray *allButOneChild = [[syntaxTree children][1] mutableCopy];
        [allButOneChild insertObject:[syntaxTree children][0] atIndex:0];
        [self setSpecifiers:allButOneChild];
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString string];
    
    NSUInteger specNum = 0;
    for (OSPMapCSSSpecifier *s in [self specifiers])
    {
        [desc appendFormat:(specNum < [[self specifiers] count] - 1) ? @"%@, " : @"%@", s];
        specNum++;
    }
    return desc;
}

@end
