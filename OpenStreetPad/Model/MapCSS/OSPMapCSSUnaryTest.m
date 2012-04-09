//
//  UnaryTest.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSUnaryTest.h"

@implementation OSPMapCSSUnaryTest

@synthesize negated;
@synthesize tagName;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        switch ([[syntaxTree children] count])
        {
            case 1:
                [self setNegated:NO];
                [self setTagName:[[[syntaxTree children] objectAtIndex:0] description]];
                break;
            case 2:
                [self setNegated:YES];
                [self setTagName:[[[syntaxTree children] objectAtIndex:1] description]];
            default:
                break;
        }
    }
    
    return self;
}

- (NSString *)description
{
    return [self isNegated] ? [NSString stringWithFormat:@"[!%@]", tagName] : [NSString stringWithFormat:@"[%@]", tagName];
}

- (BOOL)matchesObject:(OSPAPIObject *)object
{
    id value = [[object tags] objectForKey:tagName];
    
    return negated ? value == nil : value != nil;
}

@end
