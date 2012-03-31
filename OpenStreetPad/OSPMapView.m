//
//  OSPMapView.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPMapView.h"

#import "OSPMapServer.h"
#import "OSPOpenStreetMapXMLFile.h"

#import "OSPAPIObject.h"
#import "OSPWay.h"
#import "OSPNode.h"

#import "OSPMap.h"

#import "OSPMapCSSParser.h"

@interface OSPMapView () <OSPDataSourceDelegate>

@property (readwrite, strong) OSPDataSource *dataSource;

@property (readwrite, strong) OSPMetaTileView *bottomLeft;
@property (readwrite, strong) OSPMetaTileView *bottomRight;
@property (readwrite, strong) OSPMetaTileView *topLeft;
@property (readwrite, strong) OSPMetaTileView *topRight;

@property (readwrite, assign) OSPCoordinate2D startPoint;

- (void)commonInit;

- (IBAction)pan:(id)sender;

@end

@implementation OSPMapView

@synthesize dataSource;
@synthesize mapArea;
@synthesize bottomLeft;
@synthesize bottomRight;
@synthesize topLeft;
@synthesize topRight;
@synthesize startPoint;

@synthesize stylesheet;

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame serverURL:[NSURL URLWithString:@"http://api.openstreetmap.org"] mapBounds:OSPMapAreaMake(OSPCoordinate2DMake(0.5, 0.5), 16.0)];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (nil != self)
    {
        [self setDataSource:[OSPOpenStreetMapXMLFile osmFileWithPath:[[NSBundle mainBundle] pathForResource:@"TestData" ofType:@"xml"]]];
        //[self setDataSource:[OSPMapServer serverWithURL:[NSURL URLWithString:@"http://api.openstreetmap.org"]]];
        [self setMapArea:OSPMapAreaMake(OSPCoordinate2DProjectLocation(CLLocationCoordinate2DMake(57.64674,-3.30908)), 17.0)];
        
        [self commonInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame serverURL:(NSURL *)serverURL mapBounds:(OSPMapArea)initMapArea
{
    self = [super initWithFrame:frame];
    
    if (nil != self)
    {
        [self setDataSource:[OSPMapServer serverWithURL:serverURL]];
        [self setMapArea:initMapArea];
        
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    NSError *err;
    NSString *style = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"osm" ofType:@"mcs"] encoding:NSASCIIStringEncoding error:&err];
    if (nil != style)
    {
        OSPMapCSSParser *p = [[OSPMapCSSParser alloc] init];
        [self setStylesheet:[p parse:style]];
    }
    
    [[self dataSource] setDelegate:self];
    float zoom = [self mapArea].zoomLevel;
    double outsetSize = 1.0 / pow(2.0, zoom + 1.0);
    OSPCoordinateRect mapRect = OSPRectForMapAreaInRect([self mapArea], [self bounds]);
    [[self dataSource] loadObjectsInBounds:mapRect withOutset:outsetSize];
    
    [self setClipsToBounds:YES];
    
    float metaZoom = zoom - 2.0f;
    float numberOfMetaTilesAcrossWorld = pow(2.0, metaZoom);
    float xFloatingMetaTile = numberOfMetaTilesAcrossWorld * mapRect.origin.x;
    int xMetaTile = (int)xFloatingMetaTile;
    float xMetaTilePosition = 1024.0f * (xFloatingMetaTile - (float)xMetaTile);
    float yFloatingMetaTile = numberOfMetaTilesAcrossWorld * mapRect.origin.y;
    int yMetaTile = (int)yFloatingMetaTile;
    float yMetaTilePosition = 1024.0f * (yFloatingMetaTile - (float)yMetaTile);
    double metaTileSize = 1.0 / numberOfMetaTilesAcrossWorld;
    
    [self setBottomLeft: [self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition          , -yMetaTilePosition          , 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 0.5f) * metaTileSize, ((float)yMetaTile + 0.5f) * metaTileSize), zoom)]];
    [self setBottomRight:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition + 1024.0f, -yMetaTilePosition          , 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 1.5f) * metaTileSize, ((float)yMetaTile + 0.5f) * metaTileSize), zoom)]];
    [self setTopLeft:    [self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition          , -yMetaTilePosition + 1024.0f, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 0.5f) * metaTileSize, ((float)yMetaTile + 1.5f) * metaTileSize), zoom)]];
    [self setTopRight:   [self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition + 1024.0f, -yMetaTilePosition + 1024.0f, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 1.5f) * metaTileSize, ((float)yMetaTile + 1.5f) * metaTileSize), zoom)]];
    [self addSubview:[self bottomLeft]];
    [self addSubview:[self bottomRight]];
    [self addSubview:[self topLeft]];
    [self addSubview:[self topRight]];
        
    UIPanGestureRecognizer *gestureRecogniser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [gestureRecogniser setMaximumNumberOfTouches:1];
    [gestureRecogniser setMinimumNumberOfTouches:1];
    [self addGestureRecognizer:gestureRecogniser];
}

- (void)dataSource:(OSPDataSource *)mapServer didLoadObjectsInArea:(OSPCoordinateRect)area
{
    for (OSPMetaTileView *metaTileView in [NSArray arrayWithObjects:[self bottomLeft], [self bottomRight], [self topLeft], [self topRight], nil])
    {
        [metaTileView setNeedsDisplayInMapArea:area];
    }
}

- (BOOL)dataSource:(OSPDataSource *)mapServer shouldLoadObjectsInArea:(OSPCoordinateRect)area
{
    return OSPCoordinateRectIntersectsRect(OSPRectForMapAreaInRect([self mapArea], [self bounds]), area);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setStartPoint:[self mapArea].centre];
}

- (IBAction)pan:(UIPanGestureRecognizer *)sender
{
    float zoom = [self mapArea].zoomLevel;
    CGPoint t = [sender translationInView:self];
    double invPixelSize = pow(2.0, zoom + 8.0);
    double pixelSize = 1.0 / invPixelSize;
    OSPCoordinate2D c = [self mapArea].centre;
    OSPCoordinate2D newC = OSPCoordinate2DMake([self startPoint].x - t.x * pixelSize, [self startPoint].y - t.y * pixelSize);
    [self setMapArea:OSPMapAreaMake(newC, zoom)];
    OSPCoordinateRect mapRect = OSPRectForMapAreaInRect([self mapArea], [self bounds]);
    [[self dataSource] loadObjectsInBounds:mapRect withOutset:128.0 * pixelSize];
    
    float metaZoom = zoom - 2.0f;
    float numberOfMetaTilesAcrossWorld = pow(2.0, metaZoom);
    float xFloatingMetaTile = numberOfMetaTilesAcrossWorld * mapRect.origin.x;
    int xMetaTile = (int)xFloatingMetaTile;
    float xMetaTilePosition = 1024.0f * (xFloatingMetaTile - (float)xMetaTile);
    float yFloatingMetaTile = numberOfMetaTilesAcrossWorld * mapRect.origin.y;
    int yMetaTile = (int)yFloatingMetaTile;
    float yMetaTilePosition = 1024.0f * (yFloatingMetaTile - (float)yMetaTile);
    double metaTileSize = 1.0 / numberOfMetaTilesAcrossWorld;
    for (OSPMetaTileView *metaView in [NSArray arrayWithObjects:[self bottomLeft], [self bottomRight], [self topLeft], [self topRight], nil])
    {
        CGPoint p = [metaView center];
        [metaView setCenter:CGPointMake((c.x - newC.x) * invPixelSize + p.x, (c.y - newC.y) * invPixelSize + p.y)];
    }
    
    NSLog(@"Checking whether we've left the meta tile area");
    CGRect b = [self bounds];
    if ([[self bottomLeft] frame].origin.x > 0.0f)
    {
        [[self bottomRight] removeFromSuperview];
        [self setBottomRight:[self bottomLeft]];
        [self setBottomLeft:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition, -yMetaTilePosition, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 0.5f) * metaTileSize, ((float)yMetaTile + 0.5f) * metaTileSize), zoom)]];
        [self addSubview:[self bottomLeft]];
    }
    else if (CGRectGetMaxX([[self bottomRight] frame]) < CGRectGetMaxX(b))
    {
        [[self bottomLeft] removeFromSuperview];
        [self setBottomLeft:[self bottomRight]];
        [self setBottomRight:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition + 1024.0f, -yMetaTilePosition, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 1.5f) * metaTileSize, ((float)yMetaTile + 0.5f) * metaTileSize), zoom)]];
        [self addSubview:[self bottomRight]];
    }
    
    if ([[self topLeft] frame].origin.x > 0.0f)
    {
        [[self topRight] removeFromSuperview];
        [self setTopRight:[self topLeft]];
        [self setTopLeft:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition, -yMetaTilePosition + 1024.0f, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 0.5f) * metaTileSize, ((float)yMetaTile + 1.5f) * metaTileSize), zoom)]];
        [self addSubview:[self topLeft]];
    }
    else if (CGRectGetMaxX([[self topRight] frame]) < CGRectGetMaxX(b))
    {
        [[self topLeft] removeFromSuperview];
        [self setTopLeft:[self topRight]];
        [self setTopRight:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition + 1024.0f, -yMetaTilePosition + 1024.0f, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 1.5f) * metaTileSize, ((float)yMetaTile + 1.5f) * metaTileSize), zoom)]];
        [self addSubview:[self topRight]];
    }
    
    if ([[self bottomLeft] frame].origin.y > 0.0f)
    {
        [[self topLeft] removeFromSuperview];
        [self setTopLeft:[self bottomLeft]];
        [self setBottomLeft:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition, -yMetaTilePosition, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 0.5f) * metaTileSize, ((float)yMetaTile + 0.5f) * metaTileSize), zoom)]];
        [self addSubview:[self bottomLeft]];
    }
    else if (CGRectGetMaxY([[self topLeft] frame]) < CGRectGetMaxY(b))
    {
        [[self bottomLeft] removeFromSuperview];
        [self setBottomLeft:[self topLeft]];
        [self setTopLeft:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition, -yMetaTilePosition + 1024.0f, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 0.5f) * metaTileSize, ((float)yMetaTile + 1.5f) * metaTileSize), zoom)]];
        [self addSubview:[self topLeft]];
    }
    
    if ([[self bottomRight] frame].origin.y > 0.0f)
    {
        [[self topRight] removeFromSuperview];
        [self setTopRight:[self bottomRight]];
        [self setBottomRight:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition + 1024.0f, -yMetaTilePosition, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 1.5f) * metaTileSize, ((float)yMetaTile + 0.5f) * metaTileSize), zoom)]];
        [self addSubview:[self bottomRight]];
    }
    else if (CGRectGetMaxY([[self topRight] frame]) < CGRectGetMaxY(b))
    {
        [[self bottomRight] removeFromSuperview];
        [self setBottomRight:[self topRight]];
        [self setTopRight:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition + 1024.0f, -yMetaTilePosition + 1024.0f, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 1.5f) * metaTileSize, ((float)yMetaTile + 1.5f) * metaTileSize), zoom)]];
        [self addSubview:[self topRight]];
    }
    NSAssert([[self bottomLeft] frame].origin.x < [[self bottomRight] frame].origin.x, @"Bottom Left is not left of bottom right");
    NSAssert([[self topLeft] frame].origin.x < [[self topRight] frame].origin.x, @"Top Left is not left of top right");
    NSAssert([[self bottomLeft] frame].origin.y < [[self topLeft] frame].origin.y, @"Bottom Left is not below top left");
    NSAssert([[self bottomRight] frame].origin.y < [[self topRight] frame].origin.y, @"bottom right is not below top right");
}

- (OSPMetaTileView *)metaTileViewWithFrame:(CGRect)frame mapArea:(OSPMapArea)ma
{
    OSPMetaTileView *metaTileView = [[OSPMetaTileView alloc] initWithFrame:frame];
    [metaTileView setMapArea:ma];
    [metaTileView setDataSource:[self dataSource]];
    [metaTileView setStylesheet:[self stylesheet]];
    return metaTileView;
}

@end
