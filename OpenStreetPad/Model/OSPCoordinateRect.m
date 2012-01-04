//
//  OSPCoordinateRect.c
//  OpenStreetPad
//
//  Created by Thomas Davie on 13/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPCoordinateRect.h"

#import "OSPMaths.h"

#import "OSPValue.h"

inline OSPCoordinate2D OSPCoordinate2DMake(double x, double y)
{
    return (OSPCoordinate2D){.x = x, .y = y};
}

inline OSPCoordinate2D OSPCoordinate2DProjectLocation(CLLocationCoordinate2D l)
{
    double lonDegrees = l.longitude;
    double latRadians = normalisedRadians(degreesToRadians(l.latitude));
    return OSPCoordinate2DMake((lonDegrees + 180.0) / 360.0, (1.0 - log(tan(latRadians) + 1.0 / cos(latRadians)) / M_PI) / 2.0);
}

inline CLLocationCoordinate2D OSPCoordinate2DUnproject(OSPCoordinate2D l)
{
    double lon = 360.0 * l.x - 180.0;
    double lat = 180.0 * atan(sinh(M_PI * (1.0 - 2.0 * l.y))) / M_PI;
    return CLLocationCoordinate2DMake(lat, lon);
}

NSString *NSStringFromOSPCoordinate2D(OSPCoordinate2D l)
{
    return [NSString stringWithFormat:@"(%1.12f, %1.12f)", l.x, l.y];
}

const OSPCoordinateRect OSPCoordinateRectZero = (OSPCoordinateRect){.origin = {0.0, 0.0}, .size = {0.0,0.0}};

inline OSPCoordinateRect OSPCoordinateRectMake(double x, double y, double w, double h)
{
    return (OSPCoordinateRect){.origin = OSPCoordinate2DMake(x, y), .size = OSPCoordinate2DMake(w, h)};
}

inline OSPCoordinateRect OSPCoordinateRectUnion(OSPCoordinateRect a, OSPCoordinateRect b)
{
    double minLong = MIN(OSPCoordinateRectGetMinLongitude(a), OSPCoordinateRectGetMinLongitude(b));
    double maxLong = MAX(OSPCoordinateRectGetMaxLongitude(a), OSPCoordinateRectGetMaxLongitude(b));
    double minLat = MIN(OSPCoordinateRectGetMinLatitude(a), OSPCoordinateRectGetMinLatitude(b));
    double maxLat = MAX(OSPCoordinateRectGetMaxLatitude(a), OSPCoordinateRectGetMaxLatitude(b));
    
    return OSPCoordinateRectMake(minLong, minLat, maxLong - minLong, maxLat - minLat);
}

inline double OSPCoordinateRectGetMinLongitude(OSPCoordinateRect r)
{
    return r.size.x >= 0.0 ? r.origin.x : r.origin.x + r.size.x;
}

inline double OSPCoordinateRectGetMaxLongitude(OSPCoordinateRect r)
{
    return r.size.x <  0.0 ? r.origin.x : r.origin.x + r.size.x;
}

inline double OSPCoordinateRectGetMinLatitude(OSPCoordinateRect r)
{
    return r.size.y >= 0.0 ? r.origin.y : r.origin.y + r.size.y;
}

inline double OSPCoordinateRectGetMaxLatitude(OSPCoordinateRect r)
{
    return r.size.y <  0.0 ? r.origin.y : r.origin.y + r.size.y;
}

inline double OSPCoordinateRectGetWidth(OSPCoordinateRect r)
{
    return fabs(r.size.x);
}

inline double OSPCoordinateRectGetHeight(OSPCoordinateRect r)
{
    return fabs(r.size.y);
}

inline double OSPCoordinateRectArea(OSPCoordinateRect r)
{
    return r.size.x * r.size.y;
}

inline OSPCoordinate2D OSPCoordinateRectGetMinCoord(OSPCoordinateRect r)
{
    return OSPCoordinate2DMake(OSPCoordinateRectGetMinLongitude(r), OSPCoordinateRectGetMinLatitude(r));
}

inline OSPCoordinate2D OSPCoordinateRectGetMaxCoord(OSPCoordinateRect r)
{
    return OSPCoordinate2DMake(OSPCoordinateRectGetMaxLongitude(r), OSPCoordinateRectGetMaxLatitude(r));
}

inline BOOL OSPCoordinateRectContainsRect(OSPCoordinateRect a, OSPCoordinateRect b)
{
    return (OSPCoordinateRectGetMinLongitude(a) <= OSPCoordinateRectGetMinLongitude(b) &&
            OSPCoordinateRectGetMaxLongitude(a) >= OSPCoordinateRectGetMaxLongitude(b) &&
            OSPCoordinateRectGetMinLatitude(a)  <= OSPCoordinateRectGetMinLatitude(b)  &&
            OSPCoordinateRectGetMaxLatitude(a)  >= OSPCoordinateRectGetMaxLatitude(b));
}

inline BOOL OSPCoordinateRectIntersectsRect(OSPCoordinateRect a, OSPCoordinateRect b)
{
    return !(OSPCoordinateRectGetMaxLongitude(a) < OSPCoordinateRectGetMinLongitude(b) ||
             OSPCoordinateRectGetMinLongitude(a) > OSPCoordinateRectGetMaxLongitude(b) ||
             OSPCoordinateRectGetMaxLatitude(a) < OSPCoordinateRectGetMinLatitude(b) ||
             OSPCoordinateRectGetMinLatitude(a) > OSPCoordinateRectGetMaxLatitude(b));
}

inline OSPCoordinateRect OSPCoordinateRectOutset(OSPCoordinateRect r, double xOutset, double yOutset)
{
    return OSPCoordinateRectMake(r.origin.x - xOutset, r.origin.y - yOutset, r.size.x + 2.0 * xOutset, r.size.y + 2.0 * yOutset);
}

NSArray *OSPCoordinateRectSubtract(OSPCoordinateRect a, OSPCoordinateRect b)
{
    if (OSPCoordinateRectIntersectsRect(a, b))
    {
        NSMutableArray *chops = [NSMutableArray arrayWithCapacity:4];
        
        // Left
        if (a.origin.x < b.origin.x)
        {
            [chops addObject:[OSPValue valueWithRect:OSPCoordinateRectMake(a.origin.x, a.origin.y, b.origin.x - a.origin.x, a.size.y)]];
            a.size.x = a.size.x + a.origin.x - b.origin.x;
            a.origin.x = b.origin.x;
        }
        // Right
        double aRight = a.origin.x + a.size.x;
        double bRight = b.origin.x + b.size.x;
        if (aRight > bRight)
        {
            [chops addObject:[OSPValue valueWithRect:OSPCoordinateRectMake(bRight, a.origin.y, aRight - bRight, a.size.y)]];
            a.size.x = a.size.x - aRight + bRight;
        }
        // Bottom
        if (a.origin.y < b.origin.y)
        {
            [chops addObject:[OSPValue valueWithRect:OSPCoordinateRectMake(a.origin.x, a.origin.y, a.size.x, b.origin.y - a.origin.y)]];
        }
        // Top
        double aTop = a.origin.y + a.size.y;
        double bTop = b.origin.y + b.size.y;
        if (aTop > bTop)
        {
            [chops addObject:[OSPValue valueWithRect:OSPCoordinateRectMake(a.origin.x, bTop, a.size.x, aTop - bTop)]];
        }
        
        return [chops copy];
    }
    else
    {
        return [NSArray arrayWithObject:[OSPValue valueWithRect:a]];
    }
}

NSString *NSStringFromOSPCoordinateRect(OSPCoordinateRect r)
{
    return [NSString stringWithFormat:@"(%@, %@)", NSStringFromOSPCoordinate2D(r.origin), NSStringFromOSPCoordinate2D(r.size)];
}
