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
    
    [[self writer] writeStartElement:@"osm" withAttributes:@{@"version" : @"0.6", @"generator" : @"OpenStreetPad"}];
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
                     withAttributes:@{@"minlat" : [NSString stringWithFormat:@"%f", b.origin.y],
                                      @"minlon" : [NSString stringWithFormat:@"%f", b.origin.x],
                                      @"maxlat" : [NSString stringWithFormat:@"%f", b.origin.y + b.size.y],
                                      @"maxlon" : [NSString stringWithFormat:@"%f", b.origin.x + b.size.x]}];
         
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
                      withAttributes:@{
     @"id"        : [NSString stringWithFormat:@"%ld", (long)[node identity]],
     @"lon"       : [NSString stringWithFormat:@"%f", l.longitude],
     @"lat"       : [NSString stringWithFormat:@"%f", l.latitude],
     @"user"      : [node user],
     @"uid"       : [NSString stringWithFormat:@"%lu", (long)[node userId]],
     @"visible"   : [node visible] ? @"true" : @"false",
     @"version"   : [NSString stringWithFormat:@"%lu", (long)[node version]],
     @"changeset" : [NSString stringWithFormat:@"%lu", (long)[node changesetId]],
     @"timestamp" : [[self dateFormatter] stringFromDate:[node timestamp]]}];
    NSDictionary *ts = [node tags];
    for (NSString *tagKey in ts)
    {
        [[self writer] writeElement:@"tag"
                     withAttributes:@{
         @"k" : tagKey,
         @"v" : ts[tagKey]}];
    }
    [[self writer] writeEndElement];
}

- (void)writeWay:(OSPWay *)way
{
    [[self writer] writeStartElement:@"way"
                      withAttributes:@{
     @"id"        : [NSString stringWithFormat:@"%ld", (long)[way identity]],
     @"user"      : [way user],
     @"uid"       : [NSString stringWithFormat:@"%lu", (long)[way userId]],
     @"visible"   : [way visible] ? @"true" : @"false",
     @"version"   : [NSString stringWithFormat:@"%lu", (long)[way version]],
     @"changeset" : [NSString stringWithFormat:@"%lu", (long)[way changesetId]],
     @"timestamp" : [[self dateFormatter] stringFromDate:[way timestamp]]}];
    for (NSNumber *nodeRef in [way nodes])
    {
        [[self writer] writeElement:@"nd"
                     withAttributes:@{ @"ref" : [nodeRef description] }];
    }
    NSDictionary *ts = [way tags];
    for (NSString *tagKey in ts)
    {
        [[self writer] writeElement:@"tag"
                     withAttributes:@{
         @"k" : tagKey,
         @"v" : ts[tagKey]}];
    }
    [[self writer] writeEndElement];
}

- (void)writeRelation:(OSPRelation *)relation
{
    [[self writer] writeStartElement:@"relation"
                      withAttributes:@{
     @"id"        : [NSString stringWithFormat:@"%ld", (long)[relation identity]],
     @"user"      : [relation user],
     @"uid"       : [NSString stringWithFormat:@"%lu", (long)[relation userId]],
     @"visible"   : [relation visible] ? @"true" : @"false",
     @"version"   : [NSString stringWithFormat:@"%lu", (long)[relation version]],
     @"changeset" : [NSString stringWithFormat:@"%lu", (long)[relation changesetId]],
     @"timestamp" : [[self dateFormatter] stringFromDate:[relation timestamp]]}];
    for (OSPMember *member in [relation members])
    {
        [[self writer] writeElement:@"member"
                     withAttributes:@{
         @"type" : NSStringFromOSPMemberType([member referencedObjectType]),
         @"ref"  : [NSString stringWithFormat:@"%lu", (long)[member referencedObjectId]],
         @"role" : [member role]}];
    }
    NSDictionary *ts = [relation tags];
    for (NSString *tagKey in ts)
    {
        [[self writer] writeElement:@"tag"
                     withAttributes:@{
         @"k" : tagKey,
         @"v" : ts[tagKey]}];
    }
    [[self writer] writeEndElement];
}

@end
