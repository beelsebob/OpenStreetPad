//
//  OSPOpenStreetMapPBFFile.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 21/04/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOpenStreetMapPBFFile.h"

#import "OSPOpenStreetMapPBFParser.h"

#import "OSPMap.h"

@interface OSPOpenStreetMapPBFFile () <OSPOpenStreetMapParserDelegate>

@property (readwrite, strong) id<OSPDataProvider, OSPDataStore> cache;
@property (readwrite, strong) OSPOpenStreetMapPBFParser *parser;

@end

@implementation OSPOpenStreetMapPBFFile

@synthesize path;

@synthesize parser;
@synthesize cache;

+ (id)osmFileWithPath:(NSString *)path
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
                      NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:[self path]];
                      [self setParser:[[OSPOpenStreetMapPBFParser alloc] initWithStream:stream]];
                      [[self parser] setDelegate:self];
                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^()
                                     {
                                         [[self parser] parse];
                                     });
                  });
}

- (void)parser:(OSPOpenStreetMapPBFParser *)parser didFindAPIObject:(OSPAPIObject *)object
{
    if ([[self cache] isKindOfClass:[OSPMap class]])
    {
        [object setMap:(OSPMap *)[self cache]];
    }
    [[self cache] addObject:object];
}

- (void)parser:(OSPOpenStreetMapPBFParser *)parser didFailWithError:(NSError *)error
{
}

- (void)parserDidEndDocument:(OSPOpenStreetMapPBFParser *)parser
{
    [[self delegate] dataSource:self didLoadObjectsInArea:OSPCoordinateRectMake(0.0, 0.0, 1.0, 1.0)];
}

- (void)addObject:(id)apiObject
{
    [[self cache] addObject:apiObject];
}

@end
