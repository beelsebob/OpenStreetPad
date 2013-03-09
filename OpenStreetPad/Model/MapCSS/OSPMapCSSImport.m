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
        [self setUrl:[[syntaxTree children][3] content]];
        [self setMediaType:[[syntaxTree children][5] identifier]];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"@import url(\"%@\") %@\n", [self url], [self mediaType]];
}

@end
