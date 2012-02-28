//
//  OSPDataSource.m
//  
//
//  Created by Thomas Davie on 25/02/2012.
//  Copyright (c) 2012 Hunted Cow Studios. All rights reserved.
//

#import "OSPDataSource.h"

@implementation OSPDataSource

@synthesize delegate;

- (void)loadObjectsInBounds:(OSPCoordinateRect)bounds withOutset:(double)outsetSize
{
    [[NSException exceptionWithName:@"Abstract Superclass Exception" reason:@"OSPDataSource is an abstract superclass, use a concrete subclass" userInfo:nil] raise];
}

- (NSSet *)objectsInBounds:(OSPCoordinateRect)bounds
{
    [[NSException exceptionWithName:@"Abstract Superclass Exception" reason:@"OSPDataSource is an abstract superclass, use a concrete subclass" userInfo:nil] raise];
    return nil;
}

@end
