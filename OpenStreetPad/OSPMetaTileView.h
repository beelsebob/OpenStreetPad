//
//  OSPMetaTileView.h
//  OpenStreetPad
//
//  Created by Tom Davie on 04/09/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OSPMapServer.h"

#import "OSPMapArea.h"

@interface OSPMetaTileView : UIView

@property (readwrite, nonatomic, strong) OSPMapServer *server;
@property (readwrite, nonatomic, assign) OSPMapArea mapArea;

- (void)setNeedsDisplayInMapArea:(OSPCoordinateRect)area;

@end
