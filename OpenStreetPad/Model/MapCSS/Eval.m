//
//  Eval.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Eval.h"

@implementation Eval

@synthesize expression;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setExpression:[[[syntaxTree children] objectAtIndex:2] content]];
    }
    
    return self;
}

@end
