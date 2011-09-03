//
//  OSPMapView.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "OSPMapArea.h"

@interface OSPMapView : UIView

@property (readwrite, assign) OSPMapArea mapArea;

- (id)initWithFrame:(CGRect)frame serverURL:(NSURL *)serverURL mapBounds:(OSPMapArea)mapArea;

@end
