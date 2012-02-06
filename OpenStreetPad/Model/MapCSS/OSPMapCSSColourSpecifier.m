//
//  ColourSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSColourSpecifier.h"

@implementation OSPMapCSSColourSpecifier

#if TARGET_OS_IPHONE
@synthesize colour;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        [self setColour:[[syntaxTree children] objectAtIndex:0]];
    }
    
    return self;
}

- (id)initWithColour:(UIColor *)initColour
{
    self = [super init];
    
    if (nil != self)
    {
        [self setColour:initColour];
    }
    
    return self;
}

- (NSString *)description
{
    CGFloat red;
    CGFloat green; 
    CGFloat blue;
    CGFloat alpha;
    [[self colour] getRed:&red green:&green blue:&blue alpha:&alpha];
    return [NSString stringWithFormat:@"rgba(%1.2f, %1.2f, %1.2f, %1.2f)", red, green, blue, alpha];
}

- (NSArray *)values
{
    return [NSArray arrayWithObject:[self colour]];
}
#endif

@end
