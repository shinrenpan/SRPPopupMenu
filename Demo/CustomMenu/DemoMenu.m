//
//  Copyright (c) 2017年 shinren.pan@gmail.com All rights reserved.
//

#import "DemoMenu.h"

@interface DemoMenu ()

@property (nonatomic, weak) IBOutlet UIVisualEffectView *effectView;

@end


@implementation DemoMenu

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
