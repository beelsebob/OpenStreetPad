//
//  Zoom.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 01/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

@interface Zoom : NSObject <CPParseResult>

@property (readwrite, assign) float minimumZoom;
@property (readwrite, assign) float maximumZoom;

@end
