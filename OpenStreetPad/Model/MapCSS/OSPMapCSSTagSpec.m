//
//  OSPMapCSSTagSpec.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSTagSpec.h"

@implementation OSPMapCSSTagSpec

@synthesize tag;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setTag:[[[syntaxTree children] objectAtIndex:2] content]];
    }
    
    return self;
}

@end
