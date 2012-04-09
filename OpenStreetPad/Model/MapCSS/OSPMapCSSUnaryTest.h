//
//  UnaryTest.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSTest.h"

#import "OSPMapCSSTag.h"

@interface OSPMapCSSUnaryTest : OSPMapCSSTest

@property (readwrite, assign, getter=isNegated) BOOL negated;
@property (readwrite, strong) NSString *tagName;

@end
