//
//  OSPOpenStreetMapParser.m
//  
//
//  Created by Thomas Davie on 04/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOpenStreetMapParser.h"

@implementation OSPOpenStreetMapParser

@synthesize delegate;

- (id)initWithStream:(NSInputStream *)stream
{
    return [super init];
}

- (void)parse
{
    [NSException raise:@"Abstract Class Exception" format:@"OSPOSMParser is an abstract class, use a concrete subclass"];
}

@end
