//
//  OSPMapCSSHashColourToken.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 20/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSHashColourToken.h"

@implementation OSPMapCSSHashColourToken

#if TARGET_OS_IPHONE
@synthesize colour;
#endif

+ (id)tokenWithRed:(uint8_t)r green:(uint8_t)g blue:(uint8_t)b
{
    return [[self alloc] initWithRed:r green:g blue:b];
}

- (id)initWithRed:(uint8_t)r green:(uint8_t)g blue:(uint8_t)b
{
    self = [super init];
    
    if (nil != self)
    {
#if TARGET_OS_IPHONE
        [self setColour:[UIColor colorWithRed:(CGFloat)r / 255.0f green:(CGFloat)g / 255.0f blue:(CGFloat)b / 255.0f alpha:1.0f]];
#endif
    }
    
    return self;
}

- (NSString *)name
{
    return @"HashColour";
}

@end
