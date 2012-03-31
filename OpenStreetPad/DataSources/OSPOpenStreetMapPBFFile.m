//
//  OSPOpenStreetMapPBFFile.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 04/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOpenStreetMapPBFFile.h"

#import "OSPDataStore.h"

#import "OSPMap.h"

@interface OSPOpenStreetMapPBFFile ()

@property (readwrite, strong) id<OSPDataProvider, OSPDataStore> cache;

@end

@implementation OSPOpenStreetMapPBFFile

@synthesize path;

@synthesize cache;

+ (id)pbfFileWithPath:(NSString *)path
{
    return [[OSPOpenStreetMapPBFFile alloc] initWithPath:path];
}

- (id)initWithPath:(NSString *)initPath
{
    self = [super init];
    
    if (nil != self)
    {
        [self setPath:initPath];
        [self setCache:[[OSPMap alloc] init]];
    }
    
    return self;
}

- (NSSet *)objectsInBounds:(OSPCoordinateRect)bounds
{
    return [[self cache] objectsInBounds:bounds];
}

- (NSSet *)allObjects
{
    return [[self cache] allObjects];
}

- (void)loadObjectsInBounds:(OSPCoordinateRect)bounds withOutset:(double)outsetSize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^()
                  {
//                      NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:[self path]];
                  });
}

- (void)addObject:(id)apiObject
{
    [[self cache] addObject:apiObject];
}

@end
