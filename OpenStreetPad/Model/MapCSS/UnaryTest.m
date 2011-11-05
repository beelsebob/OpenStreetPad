//
//  UnaryTest.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "UnaryTest.h"

@implementation UnaryTest

@synthesize negated;
@synthesize tag;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        switch ([[syntaxTree children] count])
        {
            case 1:
                [self setNegated:NO];
                [self setTag:[[syntaxTree children] objectAtIndex:0]];
                break;
            case 2:
                [self setNegated:YES];
                [self setTag:[[syntaxTree children] objectAtIndex:1]];
            default:
                break;
        }
    }
    
    return self;
}

- (NSString *)description
{
    if ([self isNegated])
    {
        return [NSString stringWithFormat:@"[!%@]", [self tag]];
    }
    else
    {
        return [NSString stringWithFormat:@"[%@]", [self tag]];
    }
}

- (BOOL)matchesObject:(OSPAPIObject *)object
{
    id value = [[object tags] objectForKey:[[self tag] description]];
//    NSLog(@"Matching object against %@ and returning %d:\n%@", self, (negated ? value == nil : value != nil), [object tags]);
    
    return negated ? value == nil : value != nil;
}

@end
