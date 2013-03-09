//
//  EvalSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSEvalSpecifier.h"

@implementation OSPMapCSSEvalSpecifier

@synthesize eval;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        [self setEval:[syntaxTree children][0]];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"eval(\"%@\")", [[self eval] expression]];
}

@end
