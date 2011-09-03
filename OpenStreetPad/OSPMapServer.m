//
//  OSPMapServer.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 07/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//

#import "OSPMapServer.h"

#import "OSPMap.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"
#import "OSPMember.h"

typedef enum
{
    OSPRequestTypeCapabilities = 0,
    OSPRequestTypeMapArea         ,
} OSPRequestType;

@class OSPConnection;

@protocol OSPConnectionDelegate <NSObject>

- (void)connection:(OSPConnection *)connection didReceiveAPIObject:(OSPAPIObject *)object;
- (void)connectionDidFinishLoading:(OSPConnection *)connection;

@end

@interface OSPConnection : NSObject <NSStreamDelegate, NSXMLParserDelegate, NSURLConnectionDelegate>

@property (readwrite, strong) NSURLConnection *connection;
@property (readwrite, strong) NSURLRequest *request;
@property (readwrite, assign) OSPRequestType requestType;
@property (readwrite, strong) NSXMLParser *parser;
@property (readwrite, strong) NSOutputStream *parserStream;
@property (readwrite, assign, getter=isCompleted) BOOL completed;
@property (readwrite, strong) NSMutableData *data;
@property (readwrite, weak  ) id<OSPConnectionDelegate> delegate;

@property (readwrite, strong) OSPWay *currentWay;
@property (readwrite, strong) OSPRelation *currentRelation;

- (void)attemptToWriteToStream;

- (void)setupAPIObject:(OSPAPIObject *)object withAttributes:(NSDictionary *)attributes;

@end

@implementation OSPConnection

@synthesize connection;
@synthesize request;
@synthesize requestType;
@synthesize parser;
@synthesize parserStream;
@synthesize completed;
@synthesize data;
@synthesize delegate;

@synthesize currentWay;
@synthesize currentRelation;

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setCompleted:NO];
        [self setData:[NSMutableData data]];
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
    NSLog(@"Asplode");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self setCompleted:YES];
    [self attemptToWriteToStream];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    @autoreleasepool
    {
        if ([elementName isEqualToString:@"node"])
        {
            OSPNode *node = [[OSPNode alloc] init];
            
            [self setupAPIObject:node withAttributes:attributeDict];
            [node setLocation:CLLocationCoordinate2DMake([[attributeDict objectForKey:@"lat"] doubleValue], [[attributeDict objectForKey:@"lon"] doubleValue])];
            
            [[self delegate] connection:self didReceiveAPIObject:node];
        }
        else if ([elementName isEqualToString:@"way"])
        {
            [self setCurrentWay:[[OSPWay alloc] init]];
            
            [self setupAPIObject:[self currentWay] withAttributes:attributeDict];
        }
        else if (nil != [self currentWay] && [elementName isEqualToString:@"nd"])
        {
            [[self currentWay] addNodeWithId:[[attributeDict objectForKey:@"ref"] integerValue]];
        }
        else if ([elementName isEqualToString:@"relation"])
        {
            [self setCurrentRelation:[[OSPRelation alloc] init]];
            
            [self setupAPIObject:[self currentRelation] withAttributes:attributeDict];
        }
        else if (nil != [self currentRelation] && [elementName isEqualToString:@"member"])
        {
            NSString *typeString = [attributeDict objectForKey:@"type"];
            OSPMemberType t = [typeString isEqualToString:@"node"] ? OSPMemberTypeNode : [typeString isEqualToString:@"way"] ? OSPMemberTypeWay : OSPMemberTypeRelation;
            [[self currentRelation] addMember:[OSPMember memberWithType:t referencedObjectId:[[attributeDict objectForKey:@"ref"] integerValue] role:[attributeDict objectForKey:@"role"]]];
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    @autoreleasepool
    {
        if (nil != [self currentWay] && [elementName isEqualToString:@"way"])
        {
            [[self delegate] connection:self didReceiveAPIObject:[self currentWay]];
            [self setCurrentWay:nil];
        }
        else if (nil != [self currentRelation] && [elementName isEqualToString:@"relation"])
        {
            [[self delegate] connection:self didReceiveAPIObject:[self currentRelation]];
            [self setCurrentRelation:nil];
        }
    }
}

- (void)setupAPIObject:(OSPAPIObject *)object withAttributes:(NSDictionary *)attributes
{
    [object setChangesetId:[[attributes objectForKey:@"changeset"] integerValue]];
    [object setIdentity:[[attributes objectForKey:@"id"] integerValue]];
    [object setUserId:[[attributes objectForKey:@"uid"] integerValue]];
    [object setUser:[attributes objectForKey:@"user"]];
    [object setVersion:[[attributes objectForKey:@"version"] integerValue]];
    [object setVisible:[[attributes objectForKey:@"visible"] boolValue]];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    [[self delegate] connectionDidFinishLoading:self];
}

@end

#define OSPUserAgentName    @"OpenStreetPad"
#define OSPUserAgentVersion @"0.1"

#define OSPMapServerMaxSimultaneousConnections 2

@interface OSPMapServer () <OSPConnectionDelegate>

@property (readwrite, copy  ) NSURL *serverURL;
@property (readwrite, strong) OSPMap *mapCache;
@property (readwrite, strong) NSMutableArray *currentConnections;
@property (readwrite, strong) NSMutableArray *connectionQueue;

- (void)makeRequestForURL:(NSURL *)url ofType:(OSPRequestType)type;
- (void)queueConnection:(OSPConnection *)rec;
- (void)popConnectionQueue;

@end

@implementation OSPMapServer

@synthesize serverURL;
@synthesize mapCache;
@synthesize delegate;
@synthesize currentConnections;
@synthesize connectionQueue;

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
        [self setMapCache:[[OSPMap alloc] init]];
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
    return [[self mapCache] objectsInBounds:bounds];
}

- (void)loadObjectsInBounds:(OSPCoordinateRect)bounds
{
    CLLocationCoordinate2D from = OSPCoordinate2DUnproject(OSPCoordinateRectGetMinCoord(bounds));
    CLLocationCoordinate2D to = OSPCoordinate2DUnproject(OSPCoordinateRectGetMaxCoord(bounds));
    
    NSURL *mapURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/0.6/map?bbox=%f,%f,%f,%f", [self serverURL], from.longitude, to.latitude, to.longitude, from.latitude]];
    
    [self makeRequestForURL:mapURL ofType:OSPRequestTypeMapArea];
}

- (void)makeRequestForURL:(NSURL *)url ofType:(OSPRequestType)type
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:OSPUserAgentName @"/" OSPUserAgentVersion forHTTPHeaderField:@"User-Agent"];
    
    OSPConnection *rec = [[OSPConnection alloc] init];
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
    while ([[self currentConnections] count] < OSPMapServerMaxSimultaneousConnections && [[self connectionQueue] count] > 0)
    {
        OSPConnection *rec = [[self connectionQueue] objectAtIndex:0];
        [[self connectionQueue] removeObjectAtIndex:0];
        [[self currentConnections] addObject:rec];
        [rec setConnection:[NSURLConnection connectionWithRequest:[rec request] delegate:rec]];
        [[rec connection] start];
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 4096);
        NSInputStream *iStream = (__bridge_transfer NSInputStream *)readStream;
        NSOutputStream *oStream = (__bridge_transfer NSOutputStream *)writeStream;
        [oStream setDelegate:rec];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [iStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        [oStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        [iStream open];
        [oStream open];
        [rec setParserStream:oStream];
        NSXMLParser *parser = [[NSXMLParser alloc] initWithStream:iStream];
        [parser setDelegate:rec];
        [rec setParser:parser];
        [NSThread detachNewThreadSelector:@selector(parse) toTarget:parser withObject:nil];
    }
}

- (void)connection:(OSPConnection *)connection didReceiveAPIObject:(OSPAPIObject *)object
{
    [object setMap:[self mapCache]];
    [[self mapCache] addObject:object];
}

- (void)connectionDidFinishLoading:(OSPConnection *)connection
{
    [[self delegate] mapServerDidLoadObjects:self];
}

@end
