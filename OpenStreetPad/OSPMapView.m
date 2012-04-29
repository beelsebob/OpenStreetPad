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
#import "OSPOpenStreetMapPBFFile.h"

#import "OSPAPIObject.h"
#import "OSPWay.h"
#import "OSPNode.h"

#import "OSPMap.h"

#import "OSPMapCSSParser.h"

@interface OSPMapView () <OSPDataSourceDelegate>

@property (readwrite, strong) OSPDataSource *dataSource;

@property (readwrite, strong) UIView *frontView;
@property (readwrite, strong) UIView *backView;

@property (readwrite, strong) OSPMetaTileView *bottomLeft;
@property (readwrite, strong) OSPMetaTileView *bottomRight;
@property (readwrite, strong) OSPMetaTileView *topLeft;
@property (readwrite, strong) OSPMetaTileView *topRight;

@property (readwrite, assign) OSPCoordinate2D startPoint;

- (void)commonInit;

- (IBAction)pan:(id)sender;
- (IBAction)zoom:(id)sender;

@end

@implementation OSPMapView

@synthesize dataSource;
@synthesize mapArea;
@synthesize frontView;
@synthesize backView;
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
        [self setDataSource:[OSPOpenStreetMapPBFFile osmFileWithPath:[[NSBundle mainBundle] pathForResource:@"TestData" ofType:@"pbf"]]];
        //[self setDataSource:[OSPOpenStreetMapXMLFile osmFileWithPath:[[NSBundle mainBundle] pathForResource:@"TestData" ofType:@"xml"]]];
        //[self setDataSource:[OSPMapServer serverWithURL:[NSURL URLWithString:@"http://api.openstreetmap.org"]]];
        [self setMapArea:OSPMapAreaMake(OSPCoordinate2DProjectLocation(CLLocationCoordinate2DMake(43.73602,7.42166)), 17.0)];
        
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
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"osm" withExtension:@"mcs"];
    NSString *style = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    if (nil != style)
    {
        OSPMapCSSParser *p = [[OSPMapCSSParser alloc] init];
        [self setStylesheet:[p parse:style]];
        [[self stylesheet] deleteMetaAndLoadImportsRelativeToURL:[url URLByDeletingLastPathComponent]];
    }
    
    [[self dataSource] setDelegate:self];
    float zoom = [self mapArea].zoomLevel;
    double outsetSize = 1.0 / pow(2.0, zoom + 1.0);
    OSPCoordinateRect mapRect = OSPRectForMapAreaInRect([self mapArea], [self bounds]);
    [[self dataSource] loadObjectsInBounds:mapRect withOutset:outsetSize];
    
    [self setClipsToBounds:YES];
    
    [self setBackView:nil];
    [self regenerateMetaTileViews];
        
    UIPanGestureRecognizer *gestureRecogniser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [gestureRecogniser setMaximumNumberOfTouches:1];
    [gestureRecogniser setMinimumNumberOfTouches:1];
    [self addGestureRecognizer:gestureRecogniser];
    
    UIPinchGestureRecognizer *pinchRecogniser = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoom:)];
    [self addGestureRecognizer:pinchRecogniser];
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

#define kMinZoom 14.0f
#define kMaxZoom 20.0f

- (void)zoom:(UIPinchGestureRecognizer *)sender
{
    CGFloat s = [sender scale];
    CGFloat newZoom = [self mapArea].zoomLevel + log2(s);
    NSLog(@"%f, %F", s, newZoom);
    if (newZoom < kMinZoom)
    {
        newZoom = kMinZoom;
        s = exp2(kMinZoom - [self mapArea].zoomLevel);
    }
    if (newZoom > kMaxZoom)
    {
        newZoom = kMaxZoom;
        s = exp2(kMaxZoom - [self mapArea].zoomLevel);
    }
    
    switch ([sender state])
    {
        case UIGestureRecognizerStateBegan:
        {
            [[self backView] removeFromSuperview];
            [self setBackView:nil];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            [self setMapArea:OSPMapAreaMake([self mapArea].centre, newZoom)];
            [self setBackView:[self frontView]];
            [UIView animateWithDuration:2.0
                             animations:^()
             {
                 [[self backView] setAlpha:0.0f];
             }
                             completion:^(BOOL finished)
             {
                 if (finished)
                 {
                     [[self backView] removeFromSuperview];
                     [self setBackView:nil];
                 }
             }];
            [self regenerateMetaTileViews];
            break;
        }
        case UIGestureRecognizerStateChanged:
            [[[self frontView] layer] setAffineTransform:CGAffineTransformMakeScale(s, s)];
        default:
            break;
    }
}

- (OSPMetaTileView *)metaTileViewWithFrame:(CGRect)frame mapArea:(OSPMapArea)ma
{
    OSPMetaTileView *metaTileView = [[OSPMetaTileView alloc] initWithFrame:frame];
    [metaTileView setMapArea:ma];
    [metaTileView setDataSource:[self dataSource]];
    [metaTileView setStylesheet:[self stylesheet]];
    return metaTileView;
}

- (void)regenerateMetaTileViews
{
    float zoom = [self mapArea].zoomLevel;
    OSPCoordinateRect mapRect = OSPRectForMapAreaInRect([self mapArea], [self bounds]);
    float metaZoom = zoom - 2.0f;
    float numberOfMetaTilesAcrossWorld = pow(2.0, metaZoom);
    float xFloatingMetaTile = numberOfMetaTilesAcrossWorld * mapRect.origin.x;
    int xMetaTile = (int)xFloatingMetaTile;
    float xMetaTilePosition = 1024.0f * (xFloatingMetaTile - (float)xMetaTile);
    float yFloatingMetaTile = numberOfMetaTilesAcrossWorld * mapRect.origin.y;
    int yMetaTile = (int)yFloatingMetaTile;
    float yMetaTilePosition = 1024.0f * (yFloatingMetaTile - (float)yMetaTile);
    double metaTileSize = 1.0 / numberOfMetaTilesAcrossWorld;
    
    [self setFrontView:[[UIView alloc] initWithFrame:[self bounds]]];
    [[self frontView] setOpaque:NO];
    [[self frontView] setBackgroundColor:[UIColor clearColor]];
    [self addSubview:[self frontView]];
    
    [self setBottomLeft: [self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition          , -yMetaTilePosition          , 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 0.5f) * metaTileSize, ((float)yMetaTile + 0.5f) * metaTileSize), zoom)]];
    [self setBottomRight:[self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition + 1024.0f, -yMetaTilePosition          , 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 1.5f) * metaTileSize, ((float)yMetaTile + 0.5f) * metaTileSize), zoom)]];
    [self setTopLeft:    [self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition          , -yMetaTilePosition + 1024.0f, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 0.5f) * metaTileSize, ((float)yMetaTile + 1.5f) * metaTileSize), zoom)]];
    [self setTopRight:   [self metaTileViewWithFrame:CGRectMake(-xMetaTilePosition + 1024.0f, -yMetaTilePosition + 1024.0f, 1024.0f, 1024.0f) mapArea:OSPMapAreaMake(OSPCoordinate2DMake(((float)xMetaTile + 1.5f) * metaTileSize, ((float)yMetaTile + 1.5f) * metaTileSize), zoom)]];
    [[self frontView] addSubview:[self bottomLeft]];
    [[self frontView] addSubview:[self bottomRight]];
    [[self frontView] addSubview:[self topLeft]];
    [[self frontView] addSubview:[self topRight]];
}

@end
