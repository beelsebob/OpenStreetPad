//
//  OpenStreetPadAppDelegate.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Hunted Cow Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OpenStreetPadViewController;

@interface OpenStreetPadAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) OpenStreetPadViewController *viewController;

@end
