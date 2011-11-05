//
//  OSPMapCSSClass.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSClass.h"

@implementation OSPMapCSSClass

@synthesize positive;
@synthesize className;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        BOOL pos = [[syntaxTree children] count] == 2;
        [self setPositive:pos];
        [self setClassName:[[[[[syntaxTree children] objectAtIndex:pos ? 0 : 1] children] objectAtIndex:1] identifier]];
    }
    
    return self;
}

@end
