//
//  Zoom.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 01/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSZoom.h"

@implementation OSPMapCSSZoom

@synthesize minimumZoom;
@synthesize maximumZoom;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        CPSyntaxTree *range = [[syntaxTree children] objectAtIndex:1];
        
        if ([[range children] count] == 1)
        {
            float r = [[[[range children] objectAtIndex:0] number] floatValue];
            [self setMinimumZoom:r];
            [self setMaximumZoom:r];
        }
        else
        {
            [self setMinimumZoom:[[[[range children] objectAtIndex:0] number] floatValue]];
            [self setMaximumZoom:[[[[range children] objectAtIndex:2] number] floatValue]];
        }
    }
    
    return self;
}

@end
