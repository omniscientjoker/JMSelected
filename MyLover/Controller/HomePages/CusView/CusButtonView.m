//
//  CusButtonView.m
//  MyLover
//
//  Created by joker on 15/12/11.
//  Copyright © 2015年 joker. All rights reserved.
//

#import "CusButtonView.h"


#define CHTumblrMenuViewTag 1999
#define CHTumblrMenuViewImageHeight 90
#define CHTumblrMenuViewTitleHeight 20
#define CHTumblrMenuViewVerticalPadding 10
#define CHTumblrMenuViewHorizontalMargin 10
#define CHTumblrMenuViewRriseAnimationID @"CHTumblrMenuViewRriseAnimationID"
#define CHTumblrMenuViewDismissAnimationID @"CHTumblrMenuViewDismissAnimationID"
#define CHTumblrMenuViewAnimationTime 0.36
#define CHTumblrMenuViewAnimationInterval (CHTumblrMenuViewAnimationTime / 5)

@interface CusItemButton : UIControl<UIApplicationDelegate>
- (id)initWithTitle:(NSString*)title andIcon:(UIImage*)icon andSelectedBlock:(CusButtonViewSelectedBlock)block;
@property(nonatomic,copy)CusButtonViewSelectedBlock  selectedBlock;@end

@implementation CusItemButton
{
    UIImageView *iconView_;
    UILabel *titleLabel_;
}
- (id)initWithTitle:(NSString*)title andIcon:(UIImage*)icon andSelectedBlock:(CusButtonViewSelectedBlock)block
{
    self = [super init];
    if (self) {
        iconView_ = [UIImageView new];
        iconView_.image = icon;
        titleLabel_ = [UILabel new];
        titleLabel_.textAlignment = NSTextAlignmentCenter;
        titleLabel_.backgroundColor = [UIColor clearColor];
        titleLabel_.textColor = [UIColor whiteColor];
        titleLabel_.text = title;
        _selectedBlock = block;
        [self addSubview:iconView_];
        [self addSubview:titleLabel_];
    }
    return self;
}
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    iconView_.frame = CGRectMake(0, 0, CHTumblrMenuViewImageHeight, CHTumblrMenuViewImageHeight);
    titleLabel_.frame = CGRectMake(0, CHTumblrMenuViewImageHeight, CHTumblrMenuViewImageHeight, CHTumblrMenuViewTitleHeight);
}
@end

@implementation CusButtonView
{
    UIImageView *backgroundView_;
    NSMutableArray *buttons_;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
        ges.delegate = self;
        [self addGestureRecognizer:ges];
        self.backgroundColor = [UIColor clearColor];
        backgroundView_ = [[UIImageView alloc] initWithFrame:self.bounds];
        backgroundView_.image = [[UIImage imageNamed:@"modal_background.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:6];
        backgroundView_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:backgroundView_];
        buttons_ = [[NSMutableArray alloc] initWithCapacity:6];
    }
    return self;
}

- (void)addMenuItemWithTitle:(NSString*)title andIcon:(UIImage*)icon andSelectedBlock:(CusButtonViewSelectedBlock)block
{
    CusItemButton *button = [[CusItemButton alloc] initWithTitle:title andIcon:icon andSelectedBlock:block];
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    [buttons_ addObject:button];
}
- (CGRect)frameForButtonAtIndex:(NSUInteger)index
{
    NSUInteger columnCount = 3;
    NSUInteger columnIndex =  index % columnCount;
    NSUInteger rowCount = buttons_.count / columnCount + (buttons_.count%columnCount>0?1:0);
    NSUInteger rowIndex = index / columnCount;
    CGFloat itemHeight = (CHTumblrMenuViewImageHeight + CHTumblrMenuViewTitleHeight) * rowCount + (rowCount > 1?(rowCount - 1) * CHTumblrMenuViewHorizontalMargin:0);
    CGFloat offsetY = (self.bounds.size.height - itemHeight) / 2.0;
    CGFloat verticalPadding = (self.bounds.size.width - CHTumblrMenuViewHorizontalMargin * 2 - CHTumblrMenuViewImageHeight * 3) / 2.0;
    CGFloat offsetX = CHTumblrMenuViewHorizontalMargin;
    offsetX += (CHTumblrMenuViewImageHeight+ verticalPadding) * columnIndex;
    offsetY += (CHTumblrMenuViewImageHeight + CHTumblrMenuViewTitleHeight + CHTumblrMenuViewVerticalPadding) * rowIndex;
    return CGRectMake(offsetX, offsetY, CHTumblrMenuViewImageHeight, (CHTumblrMenuViewImageHeight+CHTumblrMenuViewTitleHeight));

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    for (NSUInteger i = 0; i < buttons_.count; i++)
    {
        CusItemButton *button = buttons_[i];
        button.frame = [self frameForButtonAtIndex:i];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[CusItemButton class]]){
        return NO;
    }
    CGPoint location = [gestureRecognizer locationInView:self];
    for (UIView* subview in buttons_)
    {
        if (CGRectContainsPoint(subview.frame, location))
        {
            return NO;
        }
    }
    return YES;
}

- (void)dismiss:(id)sender
{
    [self dropAnimation];
    double delayInSeconds = CHTumblrMenuViewAnimationTime  + CHTumblrMenuViewAnimationInterval * (buttons_.count + 1);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
    {
        [self removeFromSuperview];
        if (sender)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DismissedMenuSuccessed" object:nil];
        }
    });
}


- (void)buttonTapped:(CusItemButton*)btn
{
    [self dismiss:nil];
    double delayInSeconds = CHTumblrMenuViewAnimationTime  + CHTumblrMenuViewAnimationInterval * (buttons_.count + 1);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        btn.selectedBlock();
    });
}


- (void)riseAnimation
{
    NSUInteger columnCount = 3;
    NSUInteger rowCount = buttons_.count / columnCount + (buttons_.count%columnCount>0?1:0);
    for (NSUInteger index = 0; index < buttons_.count; index++)
    {
        CusItemButton *button = buttons_[index];
        button.layer.opacity = 0;
        CGRect frame = [self frameForButtonAtIndex:index];
        NSUInteger rowIndex = index / columnCount;
        NSUInteger columnIndex = index % columnCount;
        CGPoint fromPosition = CGPointMake(frame.origin.x + CHTumblrMenuViewImageHeight / 2.0,frame.origin.y +  (rowCount - rowIndex + 2)*200 + (CHTumblrMenuViewImageHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        CGPoint toPosition = CGPointMake(frame.origin.x + CHTumblrMenuViewImageHeight / 2.0,frame.origin.y + (CHTumblrMenuViewImageHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        double delayInSeconds = rowIndex * columnCount * CHTumblrMenuViewAnimationInterval;
        if (!columnIndex){
            delayInSeconds += CHTumblrMenuViewAnimationInterval;
        }else if(columnIndex == 2){
            delayInSeconds += CHTumblrMenuViewAnimationInterval * 2;
        }
        CABasicAnimation *positionAnimation;
        positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:fromPosition];
        positionAnimation.toValue = [NSValue valueWithCGPoint:toPosition];
        positionAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.45f :1.2f :0.75f :1.0f];
        positionAnimation.duration = CHTumblrMenuViewAnimationTime;
        positionAnimation.beginTime = [button.layer convertTime:CACurrentMediaTime() fromLayer:nil] + delayInSeconds;
        [positionAnimation setValue:[NSNumber numberWithUnsignedInteger:index] forKey:CHTumblrMenuViewRriseAnimationID];
        positionAnimation.delegate = self;
        [button.layer addAnimation:positionAnimation forKey:@"riseAnimation"];
    }
}

- (void)dropAnimation
{
    NSUInteger columnCount = 3;
    for (NSUInteger index = 0; index < buttons_.count; index++)
    {
        CusItemButton *button = buttons_[index];
        CGRect frame = [self frameForButtonAtIndex:index];
        NSUInteger rowIndex = index / columnCount;
        NSUInteger columnIndex = index % columnCount;
        CGPoint toPosition = CGPointMake(frame.origin.x + CHTumblrMenuViewImageHeight / 2.0,frame.origin.y -  (rowIndex + 2)*200 + (CHTumblrMenuViewImageHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        CGPoint fromPosition = CGPointMake(frame.origin.x + CHTumblrMenuViewImageHeight / 2.0,frame.origin.y + (CHTumblrMenuViewImageHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        double delayInSeconds = rowIndex * columnCount * CHTumblrMenuViewAnimationInterval;
        if (!columnIndex)
        {
            delayInSeconds += CHTumblrMenuViewAnimationInterval;
        }
        else if(columnIndex == 2)
        {
            delayInSeconds += CHTumblrMenuViewAnimationInterval * 2;
        }
        CABasicAnimation *positionAnimation;
        positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:fromPosition];
        positionAnimation.toValue = [NSValue valueWithCGPoint:toPosition];
        positionAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.3 :0.5f :1.0f :1.0f];
        positionAnimation.duration = CHTumblrMenuViewAnimationTime;
        positionAnimation.beginTime = [button.layer convertTime:CACurrentMediaTime() fromLayer:nil] + delayInSeconds;
        [positionAnimation setValue:[NSNumber numberWithUnsignedInteger:index] forKey:CHTumblrMenuViewDismissAnimationID];
        positionAnimation.delegate = self;
        [button.layer addAnimation:positionAnimation forKey:@"riseAnimation"];
    }
}

- (void)animationDidStart:(CAAnimation *)anim
{
    NSUInteger columnCount = 3;
    if([anim valueForKey:CHTumblrMenuViewRriseAnimationID])
    {
        NSUInteger index = [[anim valueForKey:CHTumblrMenuViewRriseAnimationID] unsignedIntegerValue];
        UIView *view = buttons_[index];
        CGRect frame = [self frameForButtonAtIndex:index];
        CGPoint toPosition = CGPointMake(frame.origin.x + CHTumblrMenuViewImageHeight / 2.0,frame.origin.y + (CHTumblrMenuViewImageHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        CGFloat toAlpha = 1.0;
        view.layer.position = toPosition;
        view.layer.opacity = toAlpha;

    }
    else if([anim valueForKey:CHTumblrMenuViewDismissAnimationID])
    {
        NSUInteger index = [[anim valueForKey:CHTumblrMenuViewDismissAnimationID] unsignedIntegerValue];
        NSUInteger rowIndex = index / columnCount;
        UIView *view = buttons_[index];
        CGRect frame = [self frameForButtonAtIndex:index];
        CGPoint toPosition = CGPointMake(frame.origin.x + CHTumblrMenuViewImageHeight / 2.0,frame.origin.y -  (rowIndex + 2)*200 + (CHTumblrMenuViewImageHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        view.layer.position = toPosition;
    }
}
- (void)show
{
    UIViewController *appRootViewController;
    UIWindow *window;
    window = [UIApplication sharedApplication].keyWindow;
    appRootViewController = window.rootViewController;
    UIViewController *topViewController = appRootViewController;
    while (topViewController.presentedViewController != nil)
    {
        topViewController = topViewController.presentedViewController;
    }
    if ([topViewController.view viewWithTag:CHTumblrMenuViewTag])
    {
        [[topViewController.view viewWithTag:CHTumblrMenuViewTag] removeFromSuperview];
    }
    self.frame = topViewController.view.bounds;
    [topViewController.view addSubview:self];
    [self riseAnimation];
}
@end
