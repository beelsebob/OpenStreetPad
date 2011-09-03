//
//  OSPMaths.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 13/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPMaths.h"

double normalisedRadians(double angle)
{
    const double a = fmod(angle, 2.0 * M_PI);
    return a < -M_PI ? 2.0 * M_PI + a : a > M_PI ? a - 2.0 * M_PI : a;
}
