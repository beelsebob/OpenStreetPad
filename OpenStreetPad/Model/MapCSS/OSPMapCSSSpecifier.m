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

- (NSString *)stringValue;
{
    [[NSException exceptionWithName:@"Abstract class exception" reason:@"OSPMapCSSSpecifier is an abstract class" userInfo:nil] raise];
    return nil;
}

- (OSPMapCSSSize *)sizeValue;
{
    [[NSException exceptionWithName:@"Abstract class exception" reason:@"OSPMapCSSSpecifier is an abstract class" userInfo:nil] raise];
    return nil;
}

#if TARGET_OS_IPHONE
- (UIColor *)colourValue;
{
    [[NSException exceptionWithName:@"Abstract class exception" reason:@"OSPMapCSSSpecifier is an abstract class" userInfo:nil] raise];
    return nil;
}
#endif

- (OSPMapCSSUrl *)urlValue
{
    [[NSException exceptionWithName:@"Abstract class exception" reason:@"OSPMapCSSSpecifier is an abstract class" userInfo:nil] raise];
    return nil;
}

@end
