//
//  Url.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSUrl.h"

#import "OSPMapCSSEval.h"

@implementation OSPMapCSSUrl

@synthesize content;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        NSArray *c = [syntaxTree children];
        [self setContent:[NSURL URLWithString:[[c objectAtIndex:[c count] == 1 ? 0 : 2] content]]];
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    
    if (nil != self)
    {
        [self setContent:url];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"url(\"%@\")", [self content]];
}

@end
