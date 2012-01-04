//
//  OSPMapCSSStyledObject.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 20/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPAPIObject.h"

@interface OSPMapCSSStyledObject : NSObject

@property (readwrite,weak) OSPAPIObject *object;
@property (readwrite,copy) NSDictionary *style;

+ (id)object:(OSPAPIObject *)o withStyle:(NSDictionary *)style;
- (id)initWithObject:(OSPAPIObject *)o style:(NSDictionary *)style;

@end
