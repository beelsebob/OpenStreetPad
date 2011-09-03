//
//  OSPCoordinateRect.c
//  OpenStreetPad
//
//  Created by Thomas Davie on 13/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPCoordinateRect.h"

#import "OSPMaths.h"

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
    return [NSString stringWithFormat:@"(%f, %f)", l.x, l.y];
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
    return ((OSPCoordinateRectGetMinLongitude(b) < OSPCoordinateRectGetMaxLongitude(a) ||
             OSPCoordinateRectGetMaxLongitude(b) > OSPCoordinateRectGetMinLongitude(a)) &&
            (OSPCoordinateRectGetMinLatitude(b) < OSPCoordinateRectGetMaxLatitude(a) ||
             OSPCoordinateRectGetMaxLatitude(b) > OSPCoordinateRectGetMinLatitude(a)));
}

