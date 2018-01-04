//
//  Copyright (c) 2017年 shinren.pan@gmail.com All rights reserved.
//

#import "DemoMenu.h"
#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UILabel *label;

@end


@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(__menuButtonClickedNotification:)
                                                name:SRPPopupMenuButtonClickedNotification
                                              object:nil];
    
    
}

- (void)__menuButtonClickedNotification:(NSNotification *)sender
{
    UIButton *button = sender.object;
    _label.text = [NSString stringWithFormat:@"You clicked at %@", button.titleLabel.text];
}

@end
