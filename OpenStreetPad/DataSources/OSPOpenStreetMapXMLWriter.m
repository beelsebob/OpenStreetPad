//
//  OSPOpenStreetMapXMLWriter.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 03/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOpenStreetMapXMLWriter.h"

#import "OSPXMLWriter.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"
#import "OSPMember.h"

@interface OSPOpenStreetMapXMLWriter ()

@property (strong) OSPXMLWriter *writer;
@property (strong) NSDateFormatter *dateFormatter;

- (void)writeNode:(OSPNode *)node;
- (void)writeWay:(OSPWay *)way;
- (void)writeRelation:(OSPRelation *)relation;

@end

@implementation OSPOpenStreetMapXMLWriter

@synthesize writer;
@synthesize dateFormatter;

- (id)initWithStream:(NSOutputStream *)stream
{
    self = [super init];
    
    if (nil != self)
    {
        [self setWriter:[[OSPXMLWriter alloc] initWithOutputStream:stream encoding:NSUTF8StringEncoding]];
        [self setDateFormatter:[[NSDateFormatter alloc] init]];
        [[self dateFormatter] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [[self dateFormatter] setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [[self dateFormatter] setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    return self;
}

- (void)writeDataProvider:(id<OSPDataProvider>)dataProvider
{
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *ways = [NSMutableArray array];
    NSMutableArray *relations = [NSMutableArray array];
    
    for (OSPAPIObject *obj in [dataProvider allObjects])
    {
        switch ([obj memberType])
        {
            case OSPMemberTypeNode:
                [nodes addObject:obj];
                break;
            case OSPMemberTypeWay:
                [ways addObject:obj];
                break;
            case OSPMemberTypeRelation:
                [relations addObject:obj];
                break;
            default:
                break;
        }
    }
    
    [[self writer] writeStartElement:@"osm"
                      withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                      @"0.6", @"version",
                                      @"OpenStreetPad", @"generator",
                                      nil]];
    if ([nodes count] > 0)
    {
        OSPCoordinateRect b;
        for (OSPNode *node in nodes)
        {
            CLLocationCoordinate2D l = [node location];
            b = OSPCoordinateRectMake(l.longitude, l.latitude, 0.0, 0.0);
            break;
        }
        for (OSPNode *node in nodes)
        {
            CLLocationCoordinate2D l = [node location];
            b = OSPCoordinateRectUnion(b, OSPCoordinateRectMake(l.longitude, l.latitude, 0.0, 0.0));
        }
        
        [[self writer] writeElement:@"bounds"
                     withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSString stringWithFormat:@"%f", b.origin.y], @"minlat",
                                     [NSString stringWithFormat:@"%f", b.origin.x], @"minlon",
                                     [NSString stringWithFormat:@"%f", b.origin.y + b.size.y], @"maxlat",
                                     [NSString stringWithFormat:@"%f", b.origin.x + b.size.x], @"maxlon",
                                     nil]];
        for (OSPNode *node in nodes)
        {
            [self writeNode:node];
        }
        for (OSPWay *way in ways)
        {
            [self writeWay:way];
        }
        for (OSPRelation *rel in relations)
        {
            [self writeRelation:rel];
        }
    }
    [[self writer] writeEndElement];
}

- (void)writeNode:(OSPNode *)node
{
    CLLocationCoordinate2D l = [node location];
    [[self writer] writeStartElement:@"node"
                      withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithFormat:@"%ld", [node identity]],    @"id",
                                      [NSString stringWithFormat:@"%f", l.longitude],         @"lon",
                                      [NSString stringWithFormat:@"%f", l.latitude],          @"lat",
                                      [node user],                                            @"user",
                                      [NSString stringWithFormat:@"%lu", [node userId]],      @"uid",
                                      [node visible] ? @"true" : @"false",                    @"visible",
                                      [NSString stringWithFormat:@"%lu", [node version]],     @"version",
                                      [NSString stringWithFormat:@"%lu", [node changesetId]], @"changeset",
                                      [[self dateFormatter] stringFromDate:[node timestamp]], @"timestamp",
                                      nil]];
    NSDictionary *ts = [node tags];
    for (NSString *tagKey in ts)
    {
        [[self writer] writeElement:@"tag"
                     withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                     tagKey,                   @"k",
                                     [ts objectForKey:tagKey], @"v",
                                     nil]];
    }
    [[self writer] writeEndElement];
}

- (void)writeWay:(OSPWay *)way
{
    [[self writer] writeStartElement:@"way"
                      withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithFormat:@"%ld", [way identity]],    @"id",
                                      [way user],                                            @"user",
                                      [NSString stringWithFormat:@"%lu", [way userId]],      @"uid",
                                      [way visible] ? @"true" : @"false",                    @"visible",
                                      [NSString stringWithFormat:@"%lu", [way version]],     @"version",
                                      [NSString stringWithFormat:@"%lu", [way changesetId]], @"changeset",
                                      [[self dateFormatter] stringFromDate:[way timestamp]], @"timestamp",
                                      nil]];
    for (NSNumber *nodeRef in [way nodes])
    {
        [[self writer] writeElement:@"nd"
                     withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSString stringWithFormat:@"%@", nodeRef], @"ref",
                                     nil]];
    }
    NSDictionary *ts = [way tags];
    for (NSString *tagKey in ts)
    {
        [[self writer] writeElement:@"tag"
                     withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                     tagKey,                   @"k",
                                     [ts objectForKey:tagKey], @"v",
                                     nil]];
    }
    [[self writer] writeEndElement];
}

- (void)writeRelation:(OSPRelation *)relation
{
    [[self writer] writeStartElement:@"relation"
                      withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithFormat:@"%ld", [relation identity]],    @"id",
                                      [relation user],                                            @"user",
                                      [NSString stringWithFormat:@"%lu", [relation userId]],      @"uid",
                                      [relation visible] ? @"true" : @"false",                    @"visible",
                                      [NSString stringWithFormat:@"%lu", [relation version]],     @"version",
                                      [NSString stringWithFormat:@"%lu", [relation changesetId]], @"changeset",
                                      [[self dateFormatter] stringFromDate:[relation timestamp]], @"timestamp",
                                      nil]];
    for (OSPMember *member in [relation members])
    {
        [[self writer] writeElement:@"member"
                     withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [member referencedObjectType] == OSPMemberTypeNode ? @"node" : [member referencedObjectType] == OSPMemberTypeWay ? @"way" : @"relation", @"type",
                                     [NSString stringWithFormat:@"%lu", [member referencedObjectId]], @"ref",
                                     [member role], @"role",
                                     nil]];
    }
    NSDictionary *ts = [relation tags];
    for (NSString *tagKey in ts)
    {
        [[self writer] writeElement:@"tag"
                     withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                     tagKey,                   @"k",
                                     [ts objectForKey:tagKey], @"v",
                                     nil]];
    }
    [[self writer] writeEndElement];
}

@end
