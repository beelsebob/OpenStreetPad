//
//  Import.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSImport.h"

@implementation OSPMapCSSImport

@synthesize url;
@synthesize mediaType;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setUrl:[NSURL URLWithString:[[[syntaxTree children] objectAtIndex:3] content]]];
        [self setMediaType:[[[syntaxTree children] objectAtIndex:5] identifier]];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"@import url(\"%@\") %@\n", url, mediaType];
}

@end
