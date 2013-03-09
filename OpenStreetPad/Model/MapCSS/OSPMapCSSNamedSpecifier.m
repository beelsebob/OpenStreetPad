//
//  NamedSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSNamedSpecifier.h"

#if TARGET_OS_IPHONE
#import "UIColor+CSS.h"
#endif

@implementation OSPMapCSSNamedSpecifier

@synthesize name;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        [self setName:[[syntaxTree children][0] name]];
    }
    
    return self;
}

- (id)initWithName:(NSString *)initName
{
    self = [super init];
    
    if (nil != self)
    {
        [self setName:initName];
    }
    
    return self;
}

- (NSString *)description
{
    return [self name];
}

- (NSString *)stringValue
{
    return [self name];
}

- (OSPMapCSSSize *)sizeValue
{
    return nil;
}

#if TARGET_OS_IPHONE
- (UIColor *)colourValue
{
    return [UIColor colourWithCSSName:[self name]];
}
#endif

- (OSPMapCSSUrl *)urlValue
{
    return [[OSPMapCSSUrl alloc] initWithURL:[NSURL URLWithString:[self name]]];
}

@end
