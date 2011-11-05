//
//  PlaceholderSpecifier.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 01/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "PlaceholderSpecifier.h"

#import "NamedSpecifier.h"
#import "SizeListSpecifier.h"
#import "ColourSpecifier.h"
#import "URLSpecifier.h"
#import "EvalSpecifier.h"

#import "Named.h"
#import "MapCSSSize.h"
#import "Url.h"
#import "Eval.h"

@implementation PlaceholderSpecifier

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    id item = [[syntaxTree children] objectAtIndex:0];
    
    if ([item isKindOfClass:[Named class]])
    {
        return (id)[[NamedSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
    else if ([item isKindOfClass:[MapCSSSize class]])
    {
        return (id)[[SizeListSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
#if TARGET_OS_IPHONE
    else if ([item isKindOfClass:[UIColor class]])
    {
        return (id)[[ColourSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
#endif
    else if ([item isKindOfClass:[Url class]])
    {
        return (id)[[URLSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
    else
    {
        return (id)[[EvalSpecifier alloc] initWithSyntaxTree:syntaxTree];
    }
}

@end
