//
//  Tag.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Tag.h"

#import "Key.h"

@implementation Tag

@synthesize keys;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        NSMutableArray *ks = [[NSMutableArray alloc] initWithCapacity:[[[syntaxTree children] objectAtIndex:1] count] + 1];
        [ks addObject:[[[syntaxTree children] objectAtIndex:0] key]];
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
    NSMutableString *desc = [NSMutableString string];
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
