//
//  SizeListSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "SizeListSpecifier.h"

#import "MapCSSSize.h"

@implementation SizeListSpecifier

@synthesize sizes;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        NSMutableArray *allButOneChild = [[[syntaxTree children] objectAtIndex:1] mutableCopy];
        [allButOneChild insertObject:[[syntaxTree children] objectAtIndex:0] atIndex:0];
        [self setSizes:allButOneChild];
    }
    
    return  self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString string];
    
    NSUInteger sizeNum = 0;
    for (MapCSSSize *s in [self sizes])
    {
        if (sizeNum < [[self sizes] count] - 1)
        {
            [desc appendFormat:@"%@, ", s];
        }
        else
        {
            [desc appendFormat:@"%@", s];
        }
        sizeNum++;
    }
    return desc;
}

@end
