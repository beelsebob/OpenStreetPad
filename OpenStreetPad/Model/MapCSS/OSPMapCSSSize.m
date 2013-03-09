//
//  Size.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSize.h"

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

@implementation OSPMapCSSSize

@synthesize value;
@synthesize unit;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setValue:[[[syntaxTree children][0] number] floatValue]];
        if ([[[syntaxTree children][1] children] count] > 0)
        {
            [self setUnit:OSPMapCSSUnitFromNSString([[[syntaxTree children][1] children][0] keyword])];
        }
        else
        {
            [self setUnit:OSPMapCSSUnitNone];
        }
    }
    
    return self;
}

- (id)initWithValue:(NSNumber *)initValue units:(OSPMapCSSUnit)initUnit
{
    self = [super init];
    
    if (nil != self)
    {
        [self setValue:[initValue floatValue]];
        [self setUnit:initUnit];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[OSPMapCSSSize allocWithZone:zone] initWithValue:@([self value]) units:[self unit]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%f %@", [self value], NSStringFromOSPMapCSSUnit([self unit])];
}

@end
