//
//  OpenStreetPadAppDelegate.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSPMainViewController;

@interface OSPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) OSPMainViewController *viewController;

@end
