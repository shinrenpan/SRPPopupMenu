//
//  SRPPopupMenu.m
//  SRPPopupMenu
//
//  Created by Shinren Pan on 2016/1/22.
//  Copyright © 2016年 Shinren Pan. All rights reserved.
//

#import "SRPPopupMenu.h"

NSString * const SRPPopupMenuButtonClickedNotification = @"SRPPopupMenuButtonClickedNotification";

@interface SRPPopupMenu ()

@property (nonatomic, assign) BOOL dragging;

@property (nonatomic, assign) BOOL menuOpened;

@property (nonatomic, assign) BOOL animating;

@property (nonatomic, assign, getter=mainButtonPrevCenter) CGPoint mainButtonPrevCenter;

@end


@implementation SRPPopupMenu

#pragma mark - LifeCycle
+ (instancetype)singleton
{
    static dispatch_once_t onceToken;
    static SRPPopupMenu *_singleton;
    
    dispatch_once(&onceToken, ^{
        NSString *className = NSStringFromClass([self class]);
        
        @try
        {
            UINib *nib = [UINib nibWithNibName:className bundle:nil];
            _singleton = [nib instantiateWithOwner:nil options:nil].firstObject;
            _singleton.userInteractionEnabled = YES;
        }
        @catch (NSException *exception)
        {
            NSLog(@"Please create nib file named with class name");
        }
    });
    
    return _singleton;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)awakeFromNib
{
    [self __setup];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if(_menuOpened)
    {
        [self __openMenuWithAnimated:NO];
    }
    else
    {
        [self __closeMenuWithAnimated:NO clickedButton:nil];
    }
}

#pragma mark - Properties Getter
- (CGPoint)mainButtonPrevCenter
{
    // 調整 mainButtonPrevCenter, 確保不會超出螢幕
    // 另外當螢幕旋轉時, 也一併調整
    CGFloat selfWidth        = CGRectGetWidth(self.bounds);
    CGFloat selfHeight       = CGRectGetHeight(self.bounds);
    CGFloat mainButtonWidth  = CGRectGetWidth(_mainButton.bounds);
    CGFloat mainButtonHeight = CGRectGetHeight(_mainButton.bounds);
    
    // 這裡發生情形基本上是, 直向時當 _mainButton 在右側, 轉成橫向時, _mainButton 會停留在原位置, 不會靠右
    if(_mainButtonPrevCenter.x > mainButtonWidth)
    {
        _mainButtonPrevCenter.x = selfWidth - mainButtonWidth / 2;
    }
    
    // 當 _mainButton 拖曳超過螢幕下方
    if(_mainButtonPrevCenter.y > selfHeight - mainButtonHeight / 2)
    {
        _mainButtonPrevCenter.y = selfHeight - mainButtonHeight / 2;
    }
    
    // 當 _mainButton 拖曳超過螢幕上方
    if(_mainButtonPrevCenter.y < mainButtonHeight / 2)
    {
        _mainButtonPrevCenter.y = mainButtonHeight / 2;
    }
    
    return _mainButtonPrevCenter;
}

#pragma mark - UIView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = self;
    
    // 點到 mainButton
    if(CGRectContainsPoint(_mainButton.frame, point))
    {
        return _mainButton;
    }
    
    // 選單未展開時
    if(!_menuOpened)
    {
        // return nil 代表可以穿透 SRPPopupMenu 操作下方 UIViewController
        return nil;
    }
    
    // 選單展開且可能按到 otherButtons
    else
    {
        for(UIButton *button in _otherButtons)
        {
            if(CGRectContainsPoint(button.frame, point))
            {
                view = button;
                break;
            }
        }
    }
    
    return view;
}

#pragma mark - Public
- (void)show
{
    self.hidden = NO;
    
    if(self.superview)
    {
        return;
    }
    
    UIWindow *window      = [[UIApplication sharedApplication]windows].firstObject;
    self.frame            = window.rootViewController.view.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.layer.zPosition  = NSUIntegerMax;
    
    [self bringSubviewToFront:_mainButton];
    [window.rootViewController.view addSubview:self];
}

- (void)hide
{
    self.hidden = YES;
}

#pragma mark - Private
#pragma mark Setup
- (void)__setup
{
    _mainButtonPrevCenter = _mainButton.center;
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(__deviceOrientationChanged:)
                                                name:UIDeviceOrientationDidChangeNotification
                                              object:nil];
    
    [self addGestureRecognizer:^{
        return [[UITapGestureRecognizer alloc]initWithTarget:self
                                                      action:@selector(__actionForSelfTapping:)];
    }()];
    
    [_mainButton addTarget:self action:@selector(__actionForMainButtonDragging:forEvent:)
          forControlEvents:UIControlEventTouchDragInside];
    
    [_mainButton addTarget:self action:@selector(__actionForMainButtonEndDragOrClicked:)
          forControlEvents:UIControlEventTouchUpInside];
    
    [_otherButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        [button addTarget:self action:@selector(__actionForOtherButtonsClicked:)
         forControlEvents:UIControlEventTouchUpInside];
    }];
}

#pragma mark Action for tapping in SRPPopMenu self
- (void)__actionForSelfTapping:(UITapGestureRecognizer *)gesture
{
    if(!_menuOpened)
    {
        return;
    }
    
    [self __closeMenuWithAnimated:YES clickedButton:nil];
}

#pragma mark Action for mainButton draggin.
- (void)__actionForMainButtonDragging:(UIButton *)button forEvent:(UIEvent *)event
{
    // 選單展開時, mainButton 不能拖動
    if(_menuOpened)
    {
        return;
    }
    
    _dragging      = YES;
    UITouch *touch = [[event allTouches]anyObject];
    button.center  = [touch locationInView:self];
}

#pragma mark Action for mainButton end drag or clicked
- (void)__actionForMainButtonEndDragOrClicked:(UIButton *)button
{
    // Drag 結束
    if(_dragging)
    {
        _dragging = NO;
        
        _mainButtonPrevCenter = ^{
            CGFloat x = 0.0;
            CGFloat y = _mainButton.center.y;
            
            // 拖曳在左半邊, 向左
            if(_mainButton.center.x < CGRectGetMidX(self.bounds))
            {
                x = CGRectGetMidX(_mainButton.bounds);
            }
            
            // 拖曳在右半邊, 向右
            else
            {
                x = CGRectGetMaxX(self.bounds) - CGRectGetMidX(_mainButton.bounds);
            }
            
            return CGPointMake(x, y);
        }();
        
        void (^animations)() = ^{
            _mainButton.center = self.mainButtonPrevCenter;
        };
        
        [UIView animateWithDuration:_mainButtonAnimationDuration
                              delay:0.0
             usingSpringWithDamping:_mainButtonAnimationDamping
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:animations
                         completion:nil];
    }
    
    // 選單展開且點到 mainButton
    else if(_menuOpened)
    {
        [self __closeMenuWithAnimated:YES clickedButton:nil];
    }
    
    // 選單關閉且點到 mainButton
    else
    {
        [self __openMenuWithAnimated:YES];
    }
}

#pragma mark Action for otherButtons clicked
- (void)__actionForOtherButtonsClicked:(UIButton *)button
{
    [self __closeMenuWithAnimated:YES clickedButton:button];
}

#pragma mark Menu open animation
- (void)__openMenuWithAnimated:(BOOL)animated
{
    if(_animating)
    {
        return;
    }
    
    _animating = YES;
    
    [self __menuWillOpen];
    
    void (^otherButtonsAnimations)() = ^{
        CGPoint startPoint = self.center;
        
        for(UIButton *button in _otherButtons)
        {
            button.alpha   = 1.0;
            NSUInteger tag = button.tag - 1;
            CGFloat angle  = 360.0 / _otherButtons.count;
            CGFloat degree = ((angle * tag) + _otherButtonsPosionStartAngle) * (M_PI / 180);
            CGFloat x      = startPoint.x + cosf(degree) * _othersButtonDistanceFromCenter;
            CGFloat y      = startPoint.y + sinf(degree) * _othersButtonDistanceFromCenter;
            
            button.center = CGPointMake(x, y);
        }
    };
    
    if(!animated)
    {
        _mainButton.center = self.center;
        otherButtonsAnimations();
        _animating  = NO;
        _menuOpened = YES;
        
        [self __menuDidOpen];
        
        return;
    }
    
    void (^mainButtonAnimations)() = ^{
        _mainButton.center = self.center;
    };
    
    [UIView animateWithDuration:_mainButtonAnimationDuration
                          delay:0.0
         usingSpringWithDamping:_mainButtonAnimationDamping
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:mainButtonAnimations
                     completion:nil];
    
    void (^animationsCompletion)(BOOL finished) = ^(BOOL finished) {
        _animating  = NO;
        _menuOpened = YES;
        
        [self __menuDidOpen];
    };
    
    // 先移動 mainButton 再展開 otherButtons
    // 所以 delay = _mainButtonAnimationDuration
    [UIView animateWithDuration:_otherButtonsAnimationDuration
                          delay:_mainButtonAnimationDuration
         usingSpringWithDamping:_otherButtonsAnimationDamping
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:otherButtonsAnimations
                     completion:animationsCompletion];
}

#pragma mark Menu close animation
- (void)__closeMenuWithAnimated:(BOOL)animated clickedButton:(UIButton *)button
{
    if(_animating)
    {
        return;
    }
    
    _animating = YES;
    
    [self __menuWillClose];
    
    void (^otherButtonsAnimations)() = ^{
        for(UIButton *button in _otherButtons)
        {
            button.center = self.center;
            button.alpha  = 0.0;
        }
    };
    
    if(!animated)
    {
        otherButtonsAnimations();
        
        _mainButton.center = self.mainButtonPrevCenter;
        _animating         = NO;
        _menuOpened        = NO;
        
        [self __menuDidClose];
        
        if(button)
        {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:SRPPopupMenuButtonClickedNotification object:@(button.tag)];
        }
        
        return;
    }
    
    [UIView animateWithDuration:_otherButtonsAnimationDuration
                          delay:0.0
         usingSpringWithDamping:_otherButtonsAnimationDamping
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:otherButtonsAnimations
                     completion:nil];
    
    void (^mainButtonAnimations)() = ^{
        _mainButton.center = self.mainButtonPrevCenter;
    };
    
    void (^animationsCompletion)(BOOL finished) = ^(BOOL finished) {
        _animating  = NO;
        _menuOpened = NO;
        
        [self __menuDidClose];
        
        if(button)
        {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:SRPPopupMenuButtonClickedNotification object:@(button.tag)];
        }
    };
    
    // 先關閉 otherButtons 再移動 mainButton
    // 所以 delay = _otherButtonsAnimationDuration
    [UIView animateWithDuration:_mainButtonAnimationDuration
                          delay:_otherButtonsAnimationDuration
         usingSpringWithDamping:_mainButtonAnimationDamping
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:mainButtonAnimations
                     completion:animationsCompletion];
}

#pragma mark Device orientation
- (void)__deviceOrientationChanged:(NSNotification *)sender
{
    self.frame = self.superview.bounds;
    
    [self setNeedsDisplay];
}

#pragma mark Menu will open notice
- (void)__menuWillOpen
{
    if(![self conformsToProtocol:@protocol(SRPPopupMenuProtocol)] ||
       ![self respondsToSelector:@selector(menuWillOpen)])
    {
        return;
    }
    
    [self performSelector:@selector(menuWillOpen)];
}

#pragma mark Menu opened notice
- (void)__menuDidOpen
{
    if(![self conformsToProtocol:@protocol(SRPPopupMenuProtocol)] ||
       ![self respondsToSelector:@selector(menuDidOpen)])
    {
        return;
    }
    
    [self performSelector:@selector(menuDidOpen)];
}

#pragma mark Menu will close notice
- (void)__menuWillClose
{
    if(![self conformsToProtocol:@protocol(SRPPopupMenuProtocol)] ||
       ![self respondsToSelector:@selector(menuWillClose)])
    {
        return;
    }
    
    [self performSelector:@selector(menuWillClose)];
}

#pragma mark Menu closed notice
- (void)__menuDidClose
{
    if(![self conformsToProtocol:@protocol(SRPPopupMenuProtocol)] ||
       ![self respondsToSelector:@selector(menuDidClose)])
    {
        return;
    }
    
    [self performSelector:@selector(menuDidClose)];
}

@end
