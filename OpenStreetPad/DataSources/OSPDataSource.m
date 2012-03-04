//
//  OSPDataSource.m
//  
//
//  Created by Thomas Davie on 25/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
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

- (NSSet *)allObjects
{
    return [self objectsInBounds:OSPCoordinateRectMake(-180.0, -90.0, 360.0, 180.0)];
}

@end
