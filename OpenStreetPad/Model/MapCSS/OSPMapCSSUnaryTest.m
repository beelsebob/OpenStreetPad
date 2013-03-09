//
//  UnaryTest.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSUnaryTest.h"

#import "NSString+OpenStreetPad.h"

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
                [self setTagName:[[syntaxTree children][0] description]];
                break;
            case 2:
                [self setNegated:YES];
                [self setTagName:[[syntaxTree children][1] description]];
            default:
                break;
        }
    }
    
    return self;
}

- (id)initWithTagName:(NSString *)tn negated:(BOOL)n
{
    self = [super init];
    
    if (nil != self)
    {
        [self setTagName:tn];
        [self setNegated:n];
    }
    
    return self;
}

- (NSString *)description
{
    return [self isNegated] ? [NSString stringWithFormat:@"[!%@]", tagName] : [NSString stringWithFormat:@"[%@]", tagName];
}

- (BOOL)matchesObject:(OSPAPIObject *)object
{
    NSString *value = [object valueForTag:tagName];
    
    return negated ? nil == value || [value ospUntruthValue] : nil != value && ![value ospUntruthValue];
}

@end
