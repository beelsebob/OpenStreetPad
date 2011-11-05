//
//  EvalSpecifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Specifier.h"

#import "Eval.h"

@interface EvalSpecifier : Specifier

@property (readwrite, retain) Eval *eval;

@end
