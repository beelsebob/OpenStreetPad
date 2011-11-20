//
//  Colour.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSColour.h"

@implementation OSPMapCSSColour

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    CPToken *firstToken = [[syntaxTree children] objectAtIndex:0];
    
    if ([firstToken isKindOfClass:[CPKeywordToken class]])
    {
#if TARGET_OS_IPHONE
        NSString *keyword = [(CPKeywordToken *)firstToken keyword];
        if ([keyword isEqualToString:@"rgb"])
        {
            return (OSPMapCSSColour *)[UIColor colorWithRed:[[[[syntaxTree children] objectAtIndex:2] number] floatValue] green:[[[[syntaxTree children] objectAtIndex:4] number] floatValue] blue:[[[[syntaxTree children] objectAtIndex:6] number] floatValue] alpha:1.0f];
        }
        else
        {
            return (OSPMapCSSColour *)[UIColor colorWithRed:[[[[syntaxTree children] objectAtIndex:2] number] floatValue] green:[[[[syntaxTree children] objectAtIndex:4] number] floatValue] blue:[[[[syntaxTree children] objectAtIndex:6] number] floatValue] alpha:[[[[syntaxTree children] objectAtIndex:8] number] floatValue]];
        }
#endif
    }
    else
    {
        NSLog(@"%@", NSStringFromClass([firstToken class]));
#warning Missing case for dealing with hash colour.
    }
    
    return nil;
}

@end
