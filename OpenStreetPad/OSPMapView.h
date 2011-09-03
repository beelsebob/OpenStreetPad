//
//  OSPMapView.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OSPMapArea.h"

@interface OSPMapView : UIScrollView <UIScrollViewDelegate>

@property (readwrite, assign) OSPMapArea mapArea;

- (id)initWithFrame:(CGRect)frame serverURL:(NSURL *)serverURL mapBounds:(OSPMapArea)mapArea;

@end
