//
//  AppDelegate.m
//  Demo
//
//  Created by Shinren Pan on 2016/1/22.
//  Copyright © 2016年 Shinren Pan. All rights reserved.
//

#import "DemoMenu.h"
#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[DemoMenu singleton]show];
    
    return YES;
}

@end
