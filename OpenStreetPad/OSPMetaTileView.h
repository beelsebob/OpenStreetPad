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

#import "OSPMapCSSStyleSheet.h"

@interface OSPMetaTileView : UIView

@property (readwrite, nonatomic, strong) OSPDataSource *dataSource;
@property (readwrite, nonatomic, assign) OSPMapArea mapArea;

@property (readwrite, strong) OSPMapCSSStyleSheet *stylesheet;

- (void)setNeedsDisplayInMapArea:(OSPCoordinateRect)area;

@end
