//
//  UnaryTest.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Test.h"

#import "Tag.h"

@interface UnaryTest : Test

@property (readwrite, assign, getter=isNegated) BOOL negated;
@property (readwrite, strong) Tag *tag;

@end
