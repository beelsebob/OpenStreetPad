//
//  Colour.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSColour.h"

#import "OSPMapCSSHashColourToken.h"

@implementation OSPMapCSSColour

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
#if TARGET_OS_IPHONE
    CPToken *firstToken = [syntaxTree children][0];
    
    if ([firstToken isKindOfClass:[CPKeywordToken class]])
    {
        NSString *keyword = [(CPKeywordToken *)firstToken keyword];
        if ([keyword isEqualToString:@"rgb"])
        {
            return (OSPMapCSSColour *)[UIColor colorWithRed:[[[syntaxTree children][2] number] floatValue] green:[[[syntaxTree children][4] number] floatValue] blue:[[[syntaxTree children][6] number] floatValue] alpha:1.0f];
        }
        else
        {
            return (OSPMapCSSColour *)[UIColor colorWithRed:[[[syntaxTree children][2] number] floatValue] green:[[[syntaxTree children][4] number] floatValue] blue:[[[syntaxTree children][6] number] floatValue] alpha:[[[syntaxTree children][8] number] floatValue]];
        }
    }
    else if ([firstToken isKindOfClass:[OSPMapCSSHashColourToken class]])
    {
        return (OSPMapCSSColour *)[(OSPMapCSSHashColourToken *)firstToken colour];
    }
#endif
    
    return nil;
}

@end
