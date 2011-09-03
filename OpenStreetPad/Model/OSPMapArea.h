//
//  OSPMapArea.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 13/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//


#import "OSPCoordinateRect.h"

typedef struct
{
    OSPCoordinate2D centre;
    float zoomLevel;
} OSPMapArea;

OSPMapArea OSPMapAreaMake(OSPCoordinate2D centre, float zoomLevel);

OSPCoordinateRect OSPRectForMapAreaInRect(OSPMapArea area, CGRect bounds);
