//
//  Named.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSNamed.h"

@implementation OSPMapCSSNamed

@synthesize name;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setName:[[[syntaxTree children] objectAtIndex:0] identifier]];
    }
    
    return self;
}

@end
