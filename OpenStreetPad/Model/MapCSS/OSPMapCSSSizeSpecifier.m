//
//  SizeListSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSizeSpecifier.h"

#import "OSPMapCSSSize.h"

@implementation OSPMapCSSSizeSpecifier

@synthesize size;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        [self setSize:[syntaxTree children][0]];
    }
    
    return self;
}

- (id)initWithSize:(OSPMapCSSSize *)initSize
{
    self = [super init];
    
    if (nil != self)
    {
        [self setSize:initSize];
    }
    
    return self;
}

- (NSString *)description
{
    return [[self size] description];
}

- (NSString *)stringValue
{
    return [self description];
}

- (OSPMapCSSSize *)sizeValue
{
    return [self size];
}

#if TARGET_OS_IPHONE
- (UIColor *)colourValue
{
    return nil;
}
#endif

- (OSPMapCSSUrl *)urlValue
{
    return nil;
}

@end
