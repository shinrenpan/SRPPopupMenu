//
//  Copyright (c) 2017年 shinren.pan@gmail.com All rights reserved.
//

#import "SRPPopupMenu.h"

NSString * const SRPPopupMenuButtonClickedNotification = @"SRPPopupMenuButtonClickedNotification";

@interface SRPPopupMenu ()

@property (nonatomic, assign) BOOL dragging;

@property (nonatomic, assign) BOOL menuOpened;

@property (nonatomic, assign) BOOL animating;

@property (nonatomic, assign, getter=mainButtonPrevCenter) CGPoint mainButtonPrevCenter;

@property (nonatomic, readonly, class) SRPPopupMenu *singleton;

@end


@implementation SRPPopupMenu

#pragma mark - LifeCycle
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        self.mainButtonAnimationDuration     = .5f;
        self.mainButtonAnimationDamping      = .6f;
        self.actionButtonsAnimationDuration  = .5f;
        self.actionButtonsAnimationDamping   = .4f;
        self.actionButtonsPosionStartAngle   = -90.0f;
        self.actionButtonsDistanceFromCenter = 120.0f;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
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
        for(UIButton *button in _actionButtons)
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

#pragma mark - Class method
+ (void)show
{
    self.singleton.hidden = NO;
    
    if(self.singleton.superview)
    {
        return;
    }
    
    UIWindow *window = [[UIApplication sharedApplication]windows].firstObject;
    self.singleton.frame = window.rootViewController.view.bounds;
    self.singleton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.singleton.layer.zPosition = NSUIntegerMax;
    
    [self.singleton bringSubviewToFront:self.singleton.mainButton];
    [window.rootViewController.view addSubview:self.singleton];
}

+ (void)hide
{
    self.singleton.hidden = YES;
}

#pragma mark - Private
- (void)__setup
{
    _mainButtonPrevCenter = _mainButton.center;
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(__deviceOrientationChanged:)
                                                name:UIDeviceOrientationDidChangeNotification
                                              object:nil];
    
    [self addGestureRecognizer:^{
        return [[UITapGestureRecognizer alloc]initWithTarget:self
                                                      action:@selector(__tapSelf:)];
    }()];
    
    [_mainButton addGestureRecognizer:^{
        return [[UIPanGestureRecognizer alloc]initWithTarget:self
                                                      action:@selector(__mainButtonDragging:)];
    }()];
    
    [_mainButton addTarget:self
                    action:@selector(__mainButtonClicked:)
          forControlEvents:UIControlEventTouchUpInside];
    
    [_actionButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        [button addTarget:self
                   action:@selector(__actionButtonsClicked:)
         forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (void)__tapSelf:(UITapGestureRecognizer *)gesture
{
    if(!_menuOpened)
    {
        return;
    }
    
    [self __closeMenuWithAnimated:YES clickedButton:nil];
}

- (void)__mainButtonDragging:(UIPanGestureRecognizer *)sender
{
    // 選單展開時, mainButton 不能拖動
    if(_menuOpened)
    {
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateChanged)
    {
        _mainButton.center = [sender locationInView:self];
    }
    else
    {
        _mainButtonPrevCenter = ^{
            CGFloat x = 0.0;
            CGFloat y = _mainButton.center.y;
            
            // 拖曳結束在左半邊, 向左
            if(_mainButton.center.x < CGRectGetMidX(self.bounds))
            {
                x = CGRectGetMidX(_mainButton.bounds);
            }
            
            // 拖曳結束右半邊, 向右
            else
            {
                x = CGRectGetMaxX(self.bounds) - CGRectGetMidX(_mainButton.bounds);
            }
            
            return CGPointMake(x, y);
        }();
        
        void (^animations)(void) = ^{
            _mainButton.center = self.mainButtonPrevCenter;
        };
        
        void (^completion)(BOOL) = ^(BOOL finished){
            self.dragging = NO;
        };
        
        [UIView animateWithDuration:_mainButtonAnimationDuration
                              delay:0.0
             usingSpringWithDamping:_mainButtonAnimationDamping
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:animations
                         completion:completion];
    }
}

- (void)__mainButtonClicked:(UIButton *)button
{
    // 選單展開且點到 mainButton
    if(_menuOpened)
    {
        [self __closeMenuWithAnimated:YES clickedButton:nil];
    }
    
    // 選單關閉且點到 mainButton
    else
    {
        [self __openMenuWithAnimated:YES];
    }
}

- (void)__actionButtonsClicked:(UIButton *)button
{
    [self __closeMenuWithAnimated:YES clickedButton:button];
}

- (void)__openMenuWithAnimated:(BOOL)animated
{
    if(_animating)
    {
        return;
    }
    
    [self __menuWillOpen];
    
    void (^mainButtonAnimations)(void) = ^{
        _mainButton.center = self.center;
    };
    
    void (^actionButtonsAnimations)(void) = ^{
        CGPoint startPoint = self.center;
        
        for(UIButton *button in _actionButtons)
        {
            button.alpha   = 1.0;
            NSUInteger tag = button.tag - 1;
            CGFloat angle  = 360.0 / _actionButtons.count;
            CGFloat degree = ((angle * tag) + _actionButtonsPosionStartAngle) * (M_PI / 180);
            CGFloat x      = startPoint.x + cosf(degree) * _actionButtonsDistanceFromCenter;
            CGFloat y      = startPoint.y + sinf(degree) * _actionButtonsDistanceFromCenter;
            
            button.center = CGPointMake(x, y);
        }
    };
    
    void (^animationsCompletion)(BOOL) = ^(BOOL finished) {
        [self __menuDidOpen];
    };
    
    if (animated)
    {
        [UIView animateWithDuration:_mainButtonAnimationDuration
                              delay:0.0
             usingSpringWithDamping:_mainButtonAnimationDamping
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:mainButtonAnimations
                         completion:nil];
        
        // 先移動 mainButton 再展開 otherButtons
        // 所以 delay = _mainButtonAnimationDuration
        [UIView animateWithDuration:_actionButtonsAnimationDuration
                              delay:_mainButtonAnimationDuration
             usingSpringWithDamping:_actionButtonsAnimationDamping
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:actionButtonsAnimations
                         completion:animationsCompletion];
    }
    else
    {
        mainButtonAnimations();
        actionButtonsAnimations();
        animationsCompletion(true);
    }
}

- (void)__menuWillOpen
{
    _animating = YES;
    
    if(![self conformsToProtocol:@protocol(SRPPopupMenuProtocol)] ||
       ![self respondsToSelector:@selector(menuWillOpen)])
    {
        return;
    }
    
    [self performSelector:@selector(menuWillOpen)];
}

- (void)__menuDidOpen
{
    _animating  = NO;
    _menuOpened = YES;
    
    if(![self conformsToProtocol:@protocol(SRPPopupMenuProtocol)] ||
       ![self respondsToSelector:@selector(menuDidOpen)])
    {
        return;
    }
    
    [self performSelector:@selector(menuDidOpen)];
}

- (void)__closeMenuWithAnimated:(BOOL)animated clickedButton:(UIButton *)button
{
    if(_animating)
    {
        return;
    }
    
    [self __menuWillClose];
    
    void (^mainButtonAnimations)(void) = ^{
        _mainButton.center = self.mainButtonPrevCenter;
    };
    
    void (^actionButtonsAnimations)(void) = ^{
        for(UIButton *button in _actionButtons)
        {
            button.center = self.center;
            button.alpha  = 0.0;
        }
    };
    
    void (^animationsCompletion)(BOOL) = ^(BOOL finished) {
        [self __menuDidClose];
        
        if(button)
        {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:SRPPopupMenuButtonClickedNotification object:button];
        }
    };
    
    if (animated)
    {
        [UIView animateWithDuration:_actionButtonsAnimationDuration
                              delay:0.0
             usingSpringWithDamping:_actionButtonsAnimationDamping
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:actionButtonsAnimations
                         completion:nil];
        
        // 先關閉 otherButtons 再移動 mainButton
        // 所以 delay = _otherButtonsAnimationDuration
        [UIView animateWithDuration:_mainButtonAnimationDuration
                              delay:_actionButtonsAnimationDuration
             usingSpringWithDamping:_mainButtonAnimationDamping
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:mainButtonAnimations
                         completion:animationsCompletion];
    }
    else
    {
        actionButtonsAnimations();
        mainButtonAnimations();
        animationsCompletion(NO);
    }
}

- (void)__menuWillClose
{
    _animating = YES;
    
    if(![self conformsToProtocol:@protocol(SRPPopupMenuProtocol)] ||
       ![self respondsToSelector:@selector(menuWillClose)])
    {
        return;
    }
    
    [self performSelector:@selector(menuWillClose)];
}

- (void)__menuDidClose
{
    _animating  = NO;
    _menuOpened = NO;
    
    if(![self conformsToProtocol:@protocol(SRPPopupMenuProtocol)] ||
       ![self respondsToSelector:@selector(menuDidClose)])
    {
        return;
    }
    
    [self performSelector:@selector(menuDidClose)];
}

- (void)__deviceOrientationChanged:(NSNotification *)sender
{
    self.frame = self.superview.bounds;
    
    [self setNeedsDisplay];
}

@end
