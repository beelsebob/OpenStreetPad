//
//  PlaceholderSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 01/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSPlaceholderSpecifier.h"

#import "OSPMapCSSNamedSpecifier.h"
#import "OSPMapCSSSizeSpecifier.h"
#import "OSPMapCSSColourSpecifier.h"
#import "OSPMapCSSURLSpecifier.h"
#import "OSPMapCSSEvalSpecifier.h"
#import "OSPMapCSSTagSpecifier.h"

#import "OSPMapCSSNamed.h"
#import "OSPMapCSSSize.h"
#import "OSPMapCSSUrl.h"
#import "OSPMapCSSEval.h"
#import "OSPMapCSSTagSpec.h"

@implementation OSPMapCSSPlaceholderSpecifier

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    id item = [[syntaxTree children] objectAtIndex:0];
    
    if ([item isKindOfClass:[OSPMapCSSNamed class]])
    {
        return (id)[[OSPMapCSSNamedSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
    else if ([item isKindOfClass:[OSPMapCSSSize class]])
    {
        return (id)[[OSPMapCSSSizeSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
#if TARGET_OS_IPHONE
    else if ([item isKindOfClass:[UIColor class]])
    {
        return (id)[[OSPMapCSSColourSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
#endif
    else if ([item isKindOfClass:[OSPMapCSSUrl class]])
    {
        return (id)[[OSPMapCSSURLSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
    else if ([item isKindOfClass:[OSPMapCSSEval class]])
    {
        return (id)[[OSPMapCSSEvalSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
    else
    {
        return (id)[[OSPMapCSSTagSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
}

@end
