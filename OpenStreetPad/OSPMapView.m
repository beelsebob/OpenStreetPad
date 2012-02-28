//
//  OSPMapView.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPMapView.h"

#import "OSPMapServer.h"
#import "OSPOSMFile.h"

#import "OSPAPIObject.h"
#import "OSPWay.h"
#import "OSPNode.h"

#import "OSPMap.h"

#import "OSPMapCSSParser.h"

@interface OSPMapView () <OSPDataSourceDelegate>

@property (readwrite, strong) OSPDataSource *dataSource;

@property (readwrite, strong) OSPMetaTileView *metaView;
@property (readwrite, assign) OSPCoordinate2D startPoint;

- (void)commonInit;

- (IBAction)pan:(id)sender;

@end

@implementation OSPMapView

@synthesize dataSource;
@synthesize mapArea;
@synthesize metaView;
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
        [self setDataSource:[OSPOSMFile osmFileWithPath:[[NSBundle mainBundle] pathForResource:@"TestData" ofType:@"xml"]]];
        //[self setDataSource:[OSPMapServer serverWithURL:[NSURL URLWithString:@"http://api.openstreetmap.org"]]];
        [self setMapArea:OSPMapAreaMake(OSPCoordinate2DProjectLocation(CLLocationCoordinate2DMake(57.647491, -3.313065)), 17.0)];
        
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
    double outsetSize = 1.0 / pow(2.0, [self mapArea].zoomLevel + 1.0);
    [[self dataSource] loadObjectsInBounds:OSPRectForMapAreaInRect([self mapArea], [self bounds]) withOutset:outsetSize];
    
    [self setClipsToBounds:YES];
    
    [self setMetaView:[[OSPMetaTileView alloc] initWithFrame:CGRectMake(-1664.0, -1568.0, 4096.0, 4096.0)]];
    [[self metaView] setMapArea:[self mapArea]];
    [[self metaView] setDataSource:[self dataSource]];
    [[self metaView] setStylesheet:[self stylesheet]];
    [self addSubview:[self metaView]];
    
    UIPanGestureRecognizer *gestureRecogniser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [gestureRecogniser setMaximumNumberOfTouches:1];
    [gestureRecogniser setMinimumNumberOfTouches:1];
    [self addGestureRecognizer:gestureRecogniser];
}

- (void)dataSource:(OSPDataSource *)mapServer didLoadObjectsInArea:(OSPCoordinateRect)area
{
    [[self metaView] setNeedsDisplayInMapArea:area];
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
    CGPoint t = [sender translationInView:self];
    double invPixelSize = pow(2.0, [self mapArea].zoomLevel + 8.0);
    double pixelSize = 1.0 / invPixelSize;
    OSPCoordinate2D newC = OSPCoordinate2DMake([self startPoint].x - t.x * pixelSize, [self startPoint].y - t.y * pixelSize);
    [self setMapArea:OSPMapAreaMake(newC, [self mapArea].zoomLevel)];
    [[self dataSource] loadObjectsInBounds:OSPRectForMapAreaInRect([self mapArea], [self bounds]) withOutset:128.0 * pixelSize];
    OSPCoordinate2D c = [[self metaView] mapArea].centre;
    [[self metaView] setCenter:CGPointMake((c.x - newC.x) * invPixelSize + [self center].x, (c.y - newC.y) * invPixelSize + [self center].y)];
}

@end
