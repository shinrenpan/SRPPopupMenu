// DemoMenu.m
//
// Created By Shinren Pan <shinnren.pan@gmail.com> on 2016/1/22.
// Copyright (c) 2016年 Shinren Pan. All rights reserved.

#import "DemoMenu.h"


@implementation DemoMenu

#pragma mark - NSObject
- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.otherButtonsAnimationDuration  = .5f;
    self.otherButtonsAnimationDamping   = .4f;
    self.otherButtonsPosionStartAngle   = -90.0f;
    self.othersButtonDistanceFromCenter = 120.0f;
    self.mainButtonAnimationDuration    = .5f;
    self.mainButtonAnimationDamping     = .6f;
}

#pragma mark - SRPPopupMenuProtocol
- (void)menuWillOpen
{
    _effectView.hidden = NO;
}

- (void)menuDidOpen
{
    
}

- (void)menuWillClose
{
    
}

- (void)menuDidClose
{
    _effectView.hidden = YES;
}

@end
