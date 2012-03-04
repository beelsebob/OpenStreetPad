//
//  OSPMap.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPMap.h"

#import "OSPAPIObjectReference.h"

#import "OSPQuadTree.h"

@interface OSPMap ()

@property (readwrite, strong) CFMutableSetRef __attribute__((NSObject)) contents;
@property (readwrite, strong) OSPQuadTree *tree;
@property (readwrite, strong) NSRecursiveLock *readLock;

- (OSPAPIObject *)apiObjectMatchingReference:(OSPAPIObjectReference *)ref;

@end

Boolean APIObjectEqual (const void *value1, const void *value2);

Boolean APIObjectEqual (const void *value1, const void *value2)
{
    return [(__bridge OSPAPIObject *)value1 isEqualToAPIObject:(__bridge OSPAPIObject *)value2];
}

@implementation OSPMap

@synthesize contents;
@synthesize tree;
@synthesize readLock;

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        CFSetCallBacks callbacks = kCFTypeSetCallBacks;
        callbacks.equal = APIObjectEqual;
        CFMutableSetRef s = CFSetCreateMutable(NULL, 0, &callbacks);
        [self setContents:s];
        CFRelease(s);
        
        [self setReadLock:[[NSRecursiveLock alloc] init]];
        
        [self setTree:[[OSPQuadTree alloc] initWithBounds:OSPCoordinateRectMake(0.0, 0.0, 1.0, 1.0)]];
    }
    
    return self;
}

- (void)addObject:(OSPAPIObject *)apiObject
{
    [[self readLock] lock];
    CFSetAddValue([self contents], (__bridge const void *)apiObject);
    [[self readLock] unlock];
    
    [[self tree] addObject:apiObject];
}

- (NSSet *)objectsInBounds:(OSPCoordinateRect)searchBounds
{
    return [[self tree] objectsInBounds:searchBounds];
}

- (OSPNode *)nodeWithId:(NSInteger)nodeId
{
    return (OSPNode *)[self apiObjectOfType:OSPMemberTypeNode withId:nodeId];
}

- (OSPWay *)wayWithId:(NSInteger)wayId
{
    return (OSPWay *)[self apiObjectOfType:OSPMemberTypeWay withId:wayId];
}

- (OSPRelation *)relationWithId:(NSInteger)relationId
{
    return (OSPRelation *)[self apiObjectOfType:OSPMemberTypeRelation withId:relationId];
}

- (OSPAPIObject *)apiObjectOfType:(OSPMemberType)type withId:(NSInteger)objectId
{
    return [self apiObjectMatchingReference:[OSPAPIObjectReference apiObjectReferenceWithType:type identity:objectId]];
}

- (OSPAPIObject *)apiObjectMatchingReference:(OSPAPIObjectReference *)ref
{
    [[self readLock] lock];
    OSPAPIObject *o = (__bridge OSPAPIObject *)CFSetGetValue([self contents], (__bridge const void *)ref);
    [[self readLock] unlock];
    return o;
}

- (NSSet *)allObjects
{
    return [(__bridge NSSet *)[self contents] copy];
}

- (OSPCoordinateRect)bounds
{
    CFSetRef c = [self contents];
    if (CFSetGetCount(c) > 0)
    {
        OSPCoordinateRect b;
        for (OSPAPIObject *obj in (__bridge NSSet *)c)
        {
            if ([obj memberType] == OSPMemberTypeNode)
            {
                CLLocationCoordinate2D l = [(OSPNode *)obj location];
                b = OSPCoordinateRectMake(l.longitude, l.latitude, 0.0, 0.0);
                break;
            }
        }
        for (OSPAPIObject *obj in (__bridge NSSet *)c)
        {
            if ([obj memberType] == OSPMemberTypeNode)
            {
                CLLocationCoordinate2D l = [(OSPNode *)obj location];
                b = OSPCoordinateRectUnion(b, OSPCoordinateRectMake(l.longitude, l.latitude, 0.0, 0.0));
            }
        }
        return b;
    }
    
    return OSPCoordinateRectMake(0.0, 0.0, 0.0, 0.0);
}

@end
