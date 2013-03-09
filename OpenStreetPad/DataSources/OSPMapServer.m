//
//  OSPMapServer.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 07/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPMapServer.h"

#import "OSPMap.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"
#import "OSPMember.h"
#import "OSPAPIObjectReference.h"

#import "OSPNonRectangularArea.h"
#import "OSPValue.h"

#import "OSPTileArray.h"

#import "OSPOpenStreetMapXMLParser.h"

typedef enum
{
    OSPRequestTypeCapabilities = 0,
    OSPRequestTypeMapArea         ,
} OSPRequestType;

@class OSPConnection;

@protocol OSPConnectionDelegate <NSObject>

- (void)connection:(OSPConnection *)connection didReceiveAPIObject:(OSPAPIObject *)object;
- (void)connectionDidFinishLoading:(OSPConnection *)connection;
- (void)connection:(OSPConnection *)connection didFailWithError:(NSError *)err;

@end

@interface OSPConnection : NSObject <NSStreamDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, OSPOpenStreetMapParserDelegate>

@property (readwrite, strong) NSURLConnection *connection;
@property (readwrite, strong) NSURLRequest *request;
@property (readwrite, assign) OSPRequestType requestType;
@property (readwrite, strong) OSPOpenStreetMapXMLParser *parser;
@property (readwrite, strong) NSOutputStream *parserStream;
@property (readwrite, assign, getter=isCompleted) BOOL completed;
@property (readwrite, strong) NSMutableData *data;
@property (readwrite, weak  ) id<OSPConnectionDelegate> delegate;

@property (readonly , assign) OSPCoordinateRect mapArea;
@property (readwrite, assign) OSPTile tile;

@property (readwrite, copy  ) NSArray *receivedObjects;

- (void)attemptToWriteToStream;

@end

@implementation OSPConnection
{
    __strong NSMutableArray *receivedObjects;
}

@synthesize connection;
@synthesize request;
@synthesize requestType;
@synthesize parser;
@synthesize parserStream;
@synthesize completed;
@synthesize data;
@synthesize delegate;

@synthesize tile;

- (OSPCoordinateRect)mapArea
{
    return OSPCoordinateRectFromTile([self tile]);
}

- (NSArray *)receivedObjects
{
    return receivedObjects;
}

- (void)setReceivedObjects:(NSArray *)newReceivedObjects
{
    receivedObjects = [newReceivedObjects mutableCopy];
}

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setCompleted:NO];
        [self setData:[NSMutableData data]];
        [self setReceivedObjects:@[]];
    }
    
    return self;
}

- (void)attemptToWriteToStream
{
    if ([[self data] length] > 0)
    {
        NSUInteger written = [[self parserStream] write:[[self data] bytes] maxLength:[[self data] length]];
        [[self data] replaceBytesInRange:NSMakeRange(0,written) withBytes:"" length:0];
    }
}

- (void)stream:(NSStream *)s handleEvent:(NSStreamEvent)event
{
    if (NSStreamEventHasSpaceAvailable == event)
    {
        if ([self isCompleted] && [[self data] length] == 0)
        {
            [[self parserStream] close];
        }
        else
        {
            [self attemptToWriteToStream];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d
{
    [[self data] appendData:d];
    [self attemptToWriteToStream];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self delegate] connection:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self setCompleted:YES];
    [self attemptToWriteToStream];
}

- (void)parser:(OSPOpenStreetMapXMLParser *)parser didFindAPIObject:(OSPAPIObject *)object
{
    [receivedObjects addObject:object];
    [[self delegate] connection:self didReceiveAPIObject:object];
}

- (void)parser:(OSPOpenStreetMapXMLParser *)parser didFailWithError:(NSError *)error
{
    [[self delegate] connection:self didFailWithError:error];
}

- (void)parserDidEndDocument:(OSPOpenStreetMapXMLParser *)parser
{
    dispatch_async(dispatch_get_main_queue(), ^()
                   {
                       [[self delegate] connectionDidFinishLoading:self];
                   });
}

@end

#define OSPUserAgentName    @"OpenStreetPad"
#define OSPUserAgentVersion @"0.1"

#define OSPMapServerMaxSimultaneousConnections 2

@interface OSPMapServer () <OSPConnectionDelegate>

@property (readwrite, copy  ) NSURL *serverURL;
@property (readwrite, strong) id<OSPDataProvider,OSPDataStore> cache;
@property (readwrite, strong) NSMutableArray *currentConnections;
@property (readwrite, strong) NSMutableArray *connectionQueue;

@property (readwrite, strong) OSPTileArray *requestedTiles;

- (void)makeRequestForURL:(NSURL *)url ofType:(OSPRequestType)type tile:(OSPTile)tile;
- (void)requestDataInTile:(OSPTile)tile;
- (void)queueConnection:(OSPConnection *)rec;
- (void)popConnectionQueue;

@end

@implementation OSPMapServer

@synthesize serverURL;
@synthesize cache;
@synthesize currentConnections;
@synthesize connectionQueue;
@synthesize requestedTiles;

+ (id)serverWithURL:(NSURL *)serverURL
{
    return [[self alloc] initWithURL:serverURL];
}

- (id)initWithURL:(NSURL *)initServerURL
{
    self = [super init];
    
    if (nil != self)
    {
        [self setServerURL:initServerURL];
        [self setCache:[[OSPMap alloc] init]];
        [self setRequestedTiles:[[OSPTileArray alloc] init]];
        [self setCurrentConnections:[[NSMutableArray alloc] initWithCapacity:OSPMapServerMaxSimultaneousConnections]];
        [self setConnectionQueue:[NSMutableArray array]];
    }
    
    return self;
}

- (id)init
{
    return [self initWithURL:[NSURL URLWithString:@"http://api.openstreetmap.org"]];
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
    for (OSPValue *tileValue in NSArrayOfTilesFromCoordinateRect(bounds, outsetSize))
    {
        OSPTile tile = [tileValue tileValue];
        for (OSPValue *subTileValue in [[self requestedTiles] notIncludedSubtilesOfTile:tile])
        {
            OSPTile subTile = [subTileValue tileValue];
            [self requestDataInTile:subTile];
        }
    }
}

- (void)requestDataInTile:(OSPTile)tile
{
    OSPCoordinateRect rect = OSPCoordinateRectFromTile(tile);
    CLLocationCoordinate2D from = OSPCoordinate2DUnproject(OSPCoordinateRectGetMinCoord(rect));
    CLLocationCoordinate2D to = OSPCoordinate2DUnproject(OSPCoordinateRectGetMaxCoord(rect));
    
    NSURL *mapURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/0.6/map?bbox=%f,%f,%f,%f", [self serverURL], from.longitude, to.latitude, to.longitude, from.latitude]];
    
    [self makeRequestForURL:mapURL ofType:OSPRequestTypeMapArea tile:tile];
}

- (void)makeRequestForURL:(NSURL *)url ofType:(OSPRequestType)type tile:(OSPTile)tile
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:OSPUserAgentName @"/" OSPUserAgentVersion forHTTPHeaderField:@"User-Agent"];
        
    OSPConnection *rec = [[OSPConnection alloc] init];
    [rec setTile:tile];
    [rec setRequest:req];
    [rec setRequestType:type];
    [rec setDelegate:self];
    [self queueConnection:rec];
}

- (void)queueConnection:(OSPConnection *)newConnection
{
    [[self connectionQueue] addObject:newConnection];
    [self popConnectionQueue];
}

- (void)popConnectionQueue
{
    @synchronized(self)
    {
        while ([[self currentConnections] count] < OSPMapServerMaxSimultaneousConnections && [[self connectionQueue] count] > 0)
        {
            OSPConnection *rec = [[self connectionQueue] objectAtIndex:0];
            [[self connectionQueue] removeObjectAtIndex:0];
            
            if ([[self delegate] dataSource:self shouldLoadObjectsInArea:OSPCoordinateRectFromTile([rec tile])] &&
                ![[self requestedTiles] containsTile:[rec tile]])
            {
                [[self requestedTiles] addTile:[rec tile]];
                [[self currentConnections] addObject:rec];
                [rec setConnection:[NSURLConnection connectionWithRequest:[rec request] delegate:rec]];
                [[rec connection] start];
                CFReadStreamRef readStream;
                CFWriteStreamRef writeStream;
                CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 4096);
                NSInputStream *iStream = CFBridgingRelease(readStream);
                NSOutputStream *oStream = CFBridgingRelease(writeStream);
                [oStream setDelegate:rec];
                NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
                [iStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
                [oStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
                [iStream open];
                [oStream open];
                [rec setParserStream:oStream];
                OSPOpenStreetMapXMLParser *parser = [[OSPOpenStreetMapXMLParser alloc] initWithStream:iStream];
                [parser setDelegate:rec];
                [rec setParser:parser];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^()
                               {
                                   [parser parse];
                               });
            }
        }
    }
}

- (void)connection:(OSPConnection *)connection didReceiveAPIObject:(OSPAPIObject *)object
{
    if ([[self cache] isKindOfClass:[OSPMap class]])
    {
        [object setMap:(OSPMap *)[self cache]];
    }
    [[self cache] addObject:object];
}

- (void)connectionDidFinishLoading:(OSPConnection *)connection
{
    for (OSPAPIObject *o in [connection receivedObjects])
    {
        OSPAPIObjectReference *ref = [[OSPAPIObjectReference alloc] initWithType:[o memberType] identity:[o identity]];
        for (OSPAPIObject *child in [o childObjects])
        {
            [child addParent:ref];
        }
    }
    
    [[self delegate] dataSource:self didLoadObjectsInArea:[connection mapArea]];
    [[connection parserStream] setDelegate:nil];
    [[connection parser] setDelegate:nil];
    [[self currentConnections] removeObject:connection];
    [self popConnectionQueue];
}

- (void)connection:(OSPConnection *)connection didFailWithError:(NSError *)err
{
    [[self currentConnections] removeObject:connection];
    [self popConnectionQueue];
}

@end
