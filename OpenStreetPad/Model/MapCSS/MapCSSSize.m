//
//  Size.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "MapCSSSize.h"

OSPMapCSSUnit OSPMapCSSUnitFromNSString(NSString *s)
{
    if ([s isEqualToString:@"pt"])
    {
        return OSPMapCSSUnitPt;
    }
    else if ([s isEqualToString:@"pt"])
    {
        return OSPMapCSSUnitPx;
    }
    else
    {
        return OSPMapCSSUnitPercent;
    }
}

NSString *NSStringFromOSPMapCSSUnit(OSPMapCSSUnit u)
{
    switch (u)
    {
        case OSPMapCSSUnitPt:
            return @"pt";
        case OSPMapCSSUnitPx:
            return @"px";
        case OSPMapCSSUnitPercent:
            return @"%";
        case OSPMapCSSUnitNone:
            return @"";
    }
}

@implementation MapCSSSize

@synthesize value;
@synthesize unit;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setValue:[[[[syntaxTree children] objectAtIndex:0] number] floatValue]];
        if ([[[[syntaxTree children] objectAtIndex:1] children] count] > 0)
        {
            [self setUnit:OSPMapCSSUnitFromNSString([[[[[syntaxTree children] objectAtIndex:1] children] objectAtIndex:0] keyword])];
        }
        else
        {
            [self setUnit:OSPMapCSSUnitNone];
        }
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%f %@", [self value], NSStringFromOSPMapCSSUnit([self unit])];
}

@end
