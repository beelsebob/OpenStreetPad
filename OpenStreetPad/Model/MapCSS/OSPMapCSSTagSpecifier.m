//
//  OSPMapCSSTagSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSTagSpecifier.h"

#import "OSPMapCSSNamedSpecifier.h"
#import "OSPMapCSSSizeSpecifier.h"
#import "OSPMapCSSColourSpecifier.h"
#import "OSPMapCSSURLSpecifier.h"

#import "OSPMapCSSSize.h"

@implementation OSPMapCSSTagSpecifier

@synthesize tag;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        [self setTag:[[syntaxTree children] objectAtIndex:0]];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"tag(\"%@\")", [[self tag] tag]];
}

- (OSPMapCSSSpecifier *)specifierWithAPIObject:(OSPAPIObject *)object
{
    id value = [[object tags] objectForKey:[[self tag] tag]];
    if ([value isKindOfClass:[NSString class]])
    {
        return [[OSPMapCSSNamedSpecifier alloc] initWithName:value];
    }
    else if ([value isKindOfClass:[NSNumber class]])
    {
        return [[OSPMapCSSSizeSpecifier alloc] initWithSize:[[OSPMapCSSSize alloc] initWithValue:value units:OSPMapCSSUnitPt]];
    }
    else if ([value isKindOfClass:[NSURL class]])
    {
        return [[OSPMapCSSURLSpecifier alloc] initWithURL:[[OSPMapCSSUrl alloc] initWithURL:value]];
    }
#if TARGET_OS_IPHONE
    else if ([value isKindOfClass:[UIColor class]])
    {
        return [[OSPMapCSSColourSpecifier alloc] initWithColour:value];
    }
#endif
    
    return nil;
}

@end
