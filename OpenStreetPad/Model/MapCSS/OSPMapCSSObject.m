//
//  OSPMapCSSObject.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSObject.h"

NSString *NSStringFromOSPMapCSSObjectType(OSPMapCSSObjectType t)
{
    switch (t)
    {
        case OSPMapCSSObjectTypeAll:
            return @"*";
        case OSPMapCSSObjectTypeWay:
            return @"way";
        case OSPMapCSSObjectTypeArea:
            return @"area";
        case OSPMapCSSObjectTypeLine:
            return @"line";
        case OSPMapCSSObjectTypeNode:
            return @"node";
        case OSPMapCSSObjectTypeCanvas:
            return @"canvas";
        case OSPMapCSSObjectTypeMeta:
            return @"meta";
        case OSPMapCSSObjectTypeRelation:
            return @"relation";
    }
}

OSPMapCSSObjectType OSPMapCSSObjectTypeFromNSString(NSString *s)
{
    if ([s isEqualToString:@"*"])
    {
        return OSPMapCSSObjectTypeAll;
    }
    else if ([s isEqualToString:@"way"])
    {
        return OSPMapCSSObjectTypeWay;
    }
    else if ([s isEqualToString:@"area"])
    {
        return OSPMapCSSObjectTypeArea;
    }
    else if ([s isEqualToString:@"line"])
    {
        return OSPMapCSSObjectTypeLine;
    }
    else if ([s isEqualToString:@"node"])
    {
        return OSPMapCSSObjectTypeNode;
    }
    else if ([s isEqualToString:@"canvas"])
    {
        return OSPMapCSSObjectTypeCanvas;
    }
    else if ([s isEqualToString:@"meta"])
    {
        return OSPMapCSSObjectTypeMeta;
    }
    else
    {
        return OSPMapCSSObjectTypeRelation;
    }
}

@implementation OSPMapCSSObject

@synthesize objectType;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super init];
    
    if (nil != self)
    {
        [self setObjectType:OSPMapCSSObjectTypeFromNSString([[[syntaxTree children] objectAtIndex:0] keyword])];
    }
    
    return self;
}

@end
