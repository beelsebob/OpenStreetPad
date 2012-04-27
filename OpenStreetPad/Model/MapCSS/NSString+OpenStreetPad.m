//
//  NSString+OpenStreetPad.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 05/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "NSString+OpenStreetPad.h"

@implementation NSString (OpenStreetPad)

- (BOOL)ospTruthValue
{
    NSString *l = [self lowercaseString];
    return [l isEqual:@"yes"] || [l isEqual:@"true"] || [l isEqual:@"1"];
}

- (BOOL)ospUntruthValue
{
    NSString *l = [self lowercaseString];
    return [l isEqual:@"no"] || [l isEqual:@"false"];
}

@end
