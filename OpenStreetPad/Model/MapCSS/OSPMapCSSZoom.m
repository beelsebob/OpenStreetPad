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
        
        switch ([[range children] count])
        {
            case 1:
            {
                float r = [[[[range children] objectAtIndex:0] number] floatValue];
                [self setMinimumZoom:r];
                [self setMaximumZoom:r];
                break;
            }
            case 2:
            {
                if ([[[range children] objectAtIndex:0] isKindOfClass:[CPKeywordToken class]])
                {
                    [self setMinimumZoom:-1.0];
                    [self setMaximumZoom:[[[[range children] objectAtIndex:1] number] floatValue]];
                }
                else
                {
                    [self setMinimumZoom:[[[[range children] objectAtIndex:0] number] floatValue]];
                    [self setMaximumZoom:-1.0];
                }
                break;
            }
            case 3:
            {
                [self setMinimumZoom:[[[[range children] objectAtIndex:0] number] floatValue]];
                [self setMaximumZoom:[[[[range children] objectAtIndex:2] number] floatValue]];
                break;
            }
            default:
                break;
        }
    }
    
    return self;
}

@end
