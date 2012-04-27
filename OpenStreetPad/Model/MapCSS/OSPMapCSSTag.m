//
//  Tag.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSTag.h"

#import "OSPMapCSSKey.h"

@implementation OSPMapCSSTag

@synthesize pseudoTag;
@synthesize keys;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        NSArray *possiblyTag = [[syntaxTree children] objectAtIndex:0];
        BOOL ps = [possiblyTag count] == 0;
        [self setPseudoTag:ps];
        NSMutableArray *ks = [[NSMutableArray alloc] initWithCapacity:[[[syntaxTree children] objectAtIndex:1] count] + 1];
        if (!ps)
        {
            [ks addObject:[[possiblyTag objectAtIndex:0] key]];
        }
        for (NSArray *k in [[syntaxTree children] objectAtIndex:1])
        {
            [ks addObject:[[k objectAtIndex:1] key]];
        }
        [self setKeys:ks];
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [self isPseudoTag] ? [NSMutableString stringWithString:@":"] : [NSMutableString string];
    NSUInteger keyNum = 0;
    
    for (NSString *key in [self keys])
    {
        if (keyNum < [[self keys] count] - 1)
        {
            [desc appendFormat:@"%@:", key];
        }
        else
        {
            [desc appendString:key];
        }
        keyNum++;
    }
    return desc;
}

@end
