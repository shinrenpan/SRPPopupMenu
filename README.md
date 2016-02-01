[![LICENSE](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Donate](https://img.shields.io/badge/PayPal-Donate-yellow.svg?style=flat-square)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=LC58N7VZUST5N)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)


# SRPPopupMenu

[中文說明](README/README_TW.md)

A dragable, easy customizable, popup menu.

<iframe src="https://appetize.io/embed/u3ppurce2xgyup7r58q9hpxjp0?device=iphone6&scale=75&autoplay=false&orientation=portrait&deviceColor=black" width="312px" height="653px" frameborder="0" scrolling="no">
</iframe>


# Useage
You should use your own menu, but not SRPPopupMenu.

Follow the step to create your custom menu or reference the [DemoMenu][3] class.


## Step1
Create your custom menu subclass SRPPopupMenu.

Override the method `awakeFromNib` and setting the animation properties.

> **Don't forget to call `[super awakeFromNib]`.**

```ObjC
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
```


## Step2
Create a xib file named as your custom menu class name.

Disable the AutoLayout and Size-Class.

![](README/1.png)


Drag a button to be MainButton, and connect to IBOutlet.

![](README/2.png)


Drag some buttons to be otherButtons, and conncet to IBCollections.

> **Important: you must to set the button tag, start 1 to N.**

![](README/3.png)


Now you can use your custom menu.

```Objc
// Show the menu
[[YourMenu singleton]show];

// Hide the menu
[[YourMenu singleton]hide];
```


# Handle button clicked
The SRPPopupMenu using NSNotification to handle button clicked,

```ObjC
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
    NSNumber *tag = sender.object;
    NSLog(@"%@", tag);
}
```


# Handle menu open / close
If you want to handle the menu open / close, you must implementing the SRPPopupMenuProtocol methods.

Also see [DemoMenu][3] class.

```ObjC
// Menu will open
- (void)menuWillOpen

// Menu opened
- (void)menuDidOpen

// Menu will close
- (void)menuWillClose

// Menu closed
- (void)menuDidClose
```






[3]: Demo/DemoMenu.m "DemoMenu"