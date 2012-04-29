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
@synthesize tagName;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        NSArray *c = [syntaxTree children];
        NSString *tn = nil;
        
        if ([c count] == 1)
        {
            tn = [[c objectAtIndex:0] content];
            if ([tn characterAtIndex:0] == ':')
            {
                [self setPseudoTag:YES];
            }
        }
        else
        {
            NSArray *possiblyTag = [c objectAtIndex:0];
            BOOL ps = [possiblyTag count] == 0;
            [self setPseudoTag:ps];
            tn = ps ? [NSMutableString string] : [[[possiblyTag objectAtIndex:0] key] mutableCopy];
            for (NSArray *k in [c objectAtIndex:1])
            {
                [(NSMutableString *)tn appendFormat:@":%@", [[k objectAtIndex:1] key]];
            }
        }
        
        [self setTagName:[self isPseudoTag] ? [tn substringFromIndex:1] : tn];
    }
    
    return self;
}

- (NSString *)description
{
    return [self isPseudoTag] ? [NSString stringWithFormat:@":%@", [self tagName]] : [self tagName];
}

@end
