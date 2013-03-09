//
//  OSPTileArray.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 21/01/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPTileArray.h"

#import "OSPValue.h"

typedef enum
{
    OSPTileTreeQuadrantTopLeft = 0,
    OSPTileTreeQuadrantTopRight   ,
    OSPTileTreeQuadrantBottomLeft ,
    OSPTileTreeQuadrantBottomRight
} OSPTileTreeQuadrant;

@interface OSPTileTree : NSObject

@property (readwrite, assign) OSPTile representedTile;
@property (readwrite, assign, getter=isLeaf) BOOL leaf;
@property (readwrite, assign, getter=isIncluded) BOOL included;
@property (readwrite, strong) NSArray *subTrees;

- (id)initWithTile:(OSPTile)initTile;

- (void)addTile:(OSPTile)tile;
- (BOOL)containsTile:(OSPTile)tile;
- (NSArray *)notIncludedSubtilesOfTile:(OSPTile)t;
- (NSArray *)notIncludedSubtiles;
- (uint8_t)indexForChild:(OSPTile)tile;

@end

@implementation OSPTileTree

@synthesize representedTile;
@synthesize leaf;
@synthesize included;
@synthesize subTrees;

- (id)init
{
    return [self initWithTile:(OSPTile){.x=0, .y=0, .zoom=0}];
}

- (id)initWithTile:(OSPTile)initTile
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRepresentedTile:initTile];
        [self setLeaf:YES];
        [self setIncluded:NO];
    }
    
    return self;
}

- (void)addTile:(OSPTile)tile
{
    @synchronized(self)
    {
        if (![self isLeaf] || ![self isIncluded])
        {
            OSPTile t = [self representedTile];
            if (OSPTileEqual(tile, t))
            {
                [self setLeaf:YES];
                [self setIncluded:YES];
                [self setSubTrees:nil];
            }
            else
            {
                if ([self isLeaf])
                {
                    [self setLeaf:NO];
                    OSPTileTree *bottomLeft  = [[OSPTileTree alloc] initWithTile:(OSPTile){.x = t.x * 2    , .y = t.y * 2    , .zoom = t.zoom + 1}];
                    OSPTileTree *bottomRight = [[OSPTileTree alloc] initWithTile:(OSPTile){.x = t.x * 2 + 1, .y = t.y * 2    , .zoom = t.zoom + 1}];
                    OSPTileTree *topLeft     = [[OSPTileTree alloc] initWithTile:(OSPTile){.x = t.x * 2    , .y = t.y * 2 + 1, .zoom = t.zoom + 1}];
                    OSPTileTree *topRight    = [[OSPTileTree alloc] initWithTile:(OSPTile){.x = t.x * 2 + 1, .y = t.y * 2 + 1, .zoom = t.zoom + 1}];
                    [self setSubTrees:@[bottomLeft, bottomRight, topLeft, topRight]];
                }
                [[[self subTrees] objectAtIndex:[self indexForChild:tile]] addTile:tile];
                BOOL allIncluded = YES;
                for (OSPTileTree *t in [self subTrees])
                {
                    allIncluded &= [t isIncluded];
                }
                if (allIncluded)
                {
                    [self setLeaf:YES];
                    [self setIncluded:YES];
                    [self setSubTrees:nil];
                }
            }
        }
    }
}

- (uint8_t)indexForChild:(OSPTile)tile
{
    OSPTile t = [self representedTile];
    NSUInteger shift = tile.zoom - t.zoom - 1;
    uint8_t xHalf = (uint8_t)((NSUInteger)0x1 & (tile.x >> shift));
    uint8_t yHalf = (uint8_t)((NSUInteger)0x1 & (tile.y >> shift));
    return yHalf * 2 + xHalf;
}

- (BOOL)containsTile:(OSPTile)tile
{
    @synchronized(self)
    {
        if ([self isIncluded])
        {
            return YES;
        }
        
        if ([self isLeaf])
        {
            return NO;
        }
        
        OSPTile t = [self representedTile];
        if (OSPTileEqual(tile, t))
        {
            return NO;
        }
        
        return [[[self subTrees] objectAtIndex:[self indexForChild:tile]] containsTile:tile];
    }
}

- (NSArray *)notIncludedSubtilesOfTile:(OSPTile)tile
{
    @synchronized(self)
    {
        if ([self isIncluded])
        {
            return @[];
        }
        
        if ([self isLeaf])
        {
            return @[[OSPValue valueWithTile:tile]];
        }
        
        OSPTile t = [self representedTile];
        if (OSPTileEqual(tile, t))
        {
            return [self notIncludedSubtiles];
        }
        
        return [[[self subTrees] objectAtIndex:[self indexForChild:tile]] notIncludedSubtilesOfTile:tile];
    }
}

- (NSArray *)notIncludedSubtiles
{
    @synchronized(self)
    {
        if ([self isIncluded])
        {
            return @[];
        }
        
        if ([self isLeaf])
        {
            return @[[OSPValue valueWithTile:[self representedTile]]];
        }
        
        NSMutableArray *childNotIncludedTiles = [NSMutableArray array];
        for (OSPTileTree *t in [self subTrees])
        {
            [childNotIncludedTiles addObjectsFromArray:[t notIncludedSubtiles]];
        }
        return childNotIncludedTiles;
    }
}

@end

@interface OSPTileArray ()

@property (readwrite, strong) OSPTileTree *tileTree;

@end

@implementation OSPTileArray

@synthesize tileTree;

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setTileTree:[[OSPTileTree alloc] init]];
    }
    
    return self;
}

- (void)addTile:(OSPTile)t
{
    [[self tileTree] addTile:t];
}

- (BOOL)containsTile:(OSPTile)t
{
    return [[self tileTree] containsTile:t];
}

- (NSArray *)notIncludedSubtilesOfTile:(OSPTile)t
{
    return [[self tileTree] notIncludedSubtilesOfTile:t];
}

@end
