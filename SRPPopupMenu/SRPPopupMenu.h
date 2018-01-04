//
//  Copyright (c) 2017年 shinren.pan@gmail.com All rights reserved.
//
//  Version: 1.0.1.20180104
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Button clicked notification.
 */
extern NSString * const SRPPopupMenuButtonClickedNotification;

/**
 *  SRPPopupMenu protocol.
 */
@protocol SRPPopupMenuProtocol <NSObject>
@optional


///-----------------------------------------------------------------------------
/// @name Optional methods
///-----------------------------------------------------------------------------

/**
 *  Menu will open
 */
- (void)menuWillOpen;

/**
 *  Menu opened
 */
- (void)menuDidOpen;

/**
 *  Menu will close
 */
- (void)menuWillClose;

/**
 *  Menu closed
 */
- (void)menuDidClose;

@end


/**
 *  A dragable, easy customizable, popup menu.
 */
@interface SRPPopupMenu : UIView


///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 *  Main button.
 */
@property (nonatomic, weak) IBOutlet UIButton * _Nullable mainButton;

/**
 *  Action buttons.
 */
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray * _Nullable actionButtons;

/**
 *  Main button animation duration time, default is 0.5
 */
@property (nonatomic, assign) IBInspectable CGFloat mainButtonAnimationDuration;

/**
 *  Main button animation damping effect, default is 0.6
 */
@property (nonatomic, assign) IBInspectable CGFloat mainButtonAnimationDamping;

/**
 *  Action buttons animation duration time, default is 0.5
 */
@property (nonatomic, assign) IBInspectable CGFloat actionButtonsAnimationDuration;

/**
 *  Action buttons animation damping effect, default is 0.4
 */
@property (nonatomic, assign) IBInspectable CGFloat actionButtonsAnimationDamping;

/**
 *  Action buttons start position start angle, default = -90 (Top)
 */
@property (nonatomic, assign) IBInspectable CGFloat actionButtonsPosionStartAngle;

/**
 *  Action buttons distance from center, default = 120.0
 */
@property (nonatomic, assign) IBInspectable CGFloat actionButtonsDistanceFromCenter;


///-----------------------------------------------------------------------------
/// @name Class methods
///-----------------------------------------------------------------------------

/**
 *  Show menu.
 */
+ (void)show;

/**
 *  Hide menu.
 */
+ (void)hide;

@end

NS_ASSUME_NONNULL_END
