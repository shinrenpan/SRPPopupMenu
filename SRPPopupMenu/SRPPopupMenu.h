//
//  SRPPopupMenu.h
//  SRPPopupMenu
//
//  Created by Shinren Pan on 2016/1/22.
//  Copyright © 2016年 Shinren Pan. All rights reserved.
//

#import <UIKit/UIKit.h>

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
@property (nonatomic, weak) IBOutlet UIButton *mainButton;

/**
 *  Other buttons.
 */
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *otherButtons;

/**
 *  Other buttons animation duration time.
 */
@property (nonatomic, assign) CGFloat otherButtonsAnimationDuration;

/**
 *  Other buttons animation damping effect.
 */
@property (nonatomic, assign) CGFloat otherButtonsAnimationDamping;

/**
 *  Other buttons start position start angle.
 */
@property (nonatomic, assign) CGFloat otherButtonsPosionStartAngle;

/**
 *  Other buttons distance from center.
 */
@property (nonatomic, assign) CGFloat othersButtonDistanceFromCenter;

/**
 *  Main button animation duration time.
 */
@property (nonatomic, assign) CGFloat mainButtonAnimationDuration;

/**
 *  Main button animation damping effect.
 */
@property (nonatomic, assign) CGFloat mainButtonAnimationDamping;


///-----------------------------------------------------------------------------
/// @name Class methods
///-----------------------------------------------------------------------------

/**
 *  Return a singleton object subclass SRPPopupMenu.
 *
 *  @return Return a singleton object subclass SRPPopupMenu.
 */
+ (instancetype)singleton;


///-----------------------------------------------------------------------------
/// @name Public methods
///-----------------------------------------------------------------------------

/**
 *  Show menu.
 */
- (void)show;

/**
 *  Hide menu.
 */
- (void)hide;

@end
