//
//  OSPOpenStreetMapXMLFile.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 28/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOpenStreetMapXMLFile.h"

#import "OSPOpenStreetMapXMLParser.h"
#import "OSPOpenStreetMapXMLWriter.h"

#import "OSPMap.h"

@interface OSPOpenStreetMapXMLFile () <OSPOpenStreetMapParserDelegate>

@property (readwrite, strong) id<OSPDataProvider, OSPDataStore> cache;
@property (readwrite, strong) OSPOpenStreetMapXMLParser *parser;

@end

@implementation OSPOpenStreetMapXMLFile

@synthesize path;

@synthesize parser;
@synthesize cache;

+ (id)osmFileWithPath:(NSString *)path
{
    return [[OSPOpenStreetMapXMLFile alloc] initWithPath:path];
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
        [self setParser:[[OSPOpenStreetMapXMLParser alloc] initWithStream:stream]];
        [[self parser] setDelegate:self];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^()
                       {
                           [[self parser] parse];
                       });
    });
}

- (void)parser:(OSPOpenStreetMapXMLParser *)parser didFindAPIObject:(OSPAPIObject *)object
{
    if ([[self cache] isKindOfClass:[OSPMap class]])
    {
        [object setMap:(OSPMap *)[self cache]];
    }
    [[self cache] addObject:object];
}

- (void)parser:(OSPOpenStreetMapXMLParser *)parser didFailWithError:(NSError *)error
{
}

- (void)parserDidEndDocument:(OSPOpenStreetMapXMLParser *)parser
{
    [[self delegate] dataSource:self didLoadObjectsInArea:OSPCoordinateRectMake(0.0, 0.0, 1.0, 1.0)];
}

- (void)addObject:(id)apiObject
{
    [[self cache] addObject:apiObject];
}

- (void)save
{
    [[NSFileManager defaultManager] createFileAtPath:[self path] contents:[NSData data] attributes:nil];
    NSOutputStream *oStream = [NSOutputStream outputStreamToFileAtPath:[self path] append:NO];
    [oStream open];
    OSPOpenStreetMapXMLWriter *writer = [[OSPOpenStreetMapXMLWriter alloc] initWithStream:oStream];
    [writer writeDataProvider:[self cache]];
    [oStream close];
}

@end
