//
//  OSPMapCSSStyledObject.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 20/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSStyledObject.h"

@implementation OSPMapCSSStyledObject

@synthesize object;
@synthesize style;

+ (id)object:(OSPAPIObject *)o withStyle:(NSDictionary *)style
{
    return [[self alloc] initWithObject:o style:style];
}

- (id)initWithObject:(OSPAPIObject *)o style:(NSDictionary *)s
{
    self = [super init];
    
    if (nil != self)
    {
        [self setObject:o];
        [self setStyle:s];
    }
    
    return self;
}

@end
