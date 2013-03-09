//
//  Key.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSKey.h"

@implementation OSPMapCSSKey

@synthesize key;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setKey:[[syntaxTree children][0] identifier]];
    }
    
    return self;
}

@end
