//
//  MessageTypingView.m
//  Telegram P-Edition
//
//  Created by Dmitry Kondratyev on 1/30/14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "MessageTypingView.h"
#import "NSAttributedString+Hyperlink.h"
#import "TMAttributedString.h"
#import "TMTypingManager.h"
#import "TGAnimationBlockDelegate.h"
#import "TGTimerTarget.h"
@interface MessageTypingView() {
    NSArray *_typingDots;
    NSTimer *_typingDotTimer;
    int _typingDotState;
    bool _typingAnimation;
    bool _animationsAreSuspended;
}

@property (nonatomic, strong) TL_conversation *currentDialog;
@property (nonatomic, strong) NSMutableAttributedString *attributedString;
@property (nonatomic, strong) TMTextField *textField;
@property (nonatomic, strong) BTRImageView *imageView;


@property (nonatomic,strong) TMView *typingView;

@property (nonatomic) int endString;
@property (nonatomic) int haveDots;
@property (nonatomic) int needDots;
@end


@implementation MessageTypingView

const NSTimeInterval typingIntervalFirst = 0.16;
const NSTimeInterval typingIntervalSecond = 0.14;


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.typingView = [[TMView alloc] initWithFrame:NSMakeRect(63-30, 10, 30, 16)];
        
        self.typingView.wantsLayer = YES;
        
        [self addSubview:self.typingView];
        
        self.attributedString = [[NSMutableAttributedString alloc] init];
        self.textField = [[TMTextField alloc] initWithFrame:NSMakeRect(77, 10, 0, 0)];
        [self.textField setBordered:NO];
        [self.textField setEditable:NO];
        [self.textField setEnabled:NO];
        [self.textField setSelectable:NO];
        
        [[self.textField cell] setTruncatesLastVisibleLine:YES];
//        
//        static BTRImage *typingGif;
//        if(typingGif == nil) {
//            typingGif = [BTRImage animatedImage:@"typingGIF"];
//        }
//        
//        self.imageView = [[BTRImageView alloc] initWithFrame:NSMakeRect(0, 0, typingGif.size.width, typingGif.size.height)];
//        [self.imageView setImage:typingGif];
//        [self.imageView setFrameOrigin:NSMakePoint(36, 14)];
//        [self.imageView setHidden:YES];
//        [self addSubview:self.imageView];
//        

        [self addSubview:self.textField];
        
        self.backgroundColor = NSColorFromRGB(0xffffff);
        
    }
    return self;
}

- (void) setDialog:(TL_conversation *) dialog {
    self.currentDialog = dialog;
    [Notification removeObserver:self];
    [Notification addObserver:self selector:@selector(typingRedrawNotification:) name:[Notification notificationNameByDialog:dialog action:@"typing"]];
    
    
    [self redrawByArray:[[[TMTypingManager sharedManager] typeObjectForDialog:dialog] writeArray]];
}

- (void) typingRedrawNotification:(NSNotification *)notification {
    NSArray *users = (NSArray *)([notification.userInfo objectForKey:@"users"]);
    
    [self redrawByArray:users];
}

- (void) redrawByArray:(NSArray *)users {
    [[self.attributedString mutableString] setString:@""];
    
    
    
    NSString *string = nil;
    if(users.count) {
      //  [self.imageView setHidden:NO];
      //  [self.imageView startGifAnimation];

         [self _beginTypingAnimation:YES];
        if(users.count == 1) {
            TGUser *user = [[UsersManager sharedManager] find:[[users objectAtIndex:0] integerValue]];
            if(user)
                string =[NSString stringWithFormat:NSLocalizedString(@"Typing.IsTyping", nil),user.fullName];
        } else {
            NSMutableArray *usersStrings = [[NSMutableArray alloc] init];
            for(NSNumber *uid in users) {
                TGUser *user = [[UsersManager sharedManager] find:[uid integerValue]];
                if(user) {
                    [usersStrings addObject:user.fullName];
                }
            }
            
            string = [NSString stringWithFormat:NSLocalizedString(@"Typing.AreTyping", nil), [usersStrings componentsJoinedByString:@", "]];
        }
        
        [self.attributedString appendString:string withColor:[NSColor grayColor]];
    } else {
      //  [self.imageView stopGifAnimation];
       // [self.imageView setHidden:YES];

        [self _endTypingAnimation:YES];
        
        self.needDots = 0;
    }
    
    [self.textField setFont:[NSFont fontWithName:@"HelveticaNeue" size:12]];
    self.textField.attributedStringValue = self.attributedString;
    self.endString = (int) self.attributedString.length;
    [self.textField sizeToFit];
    
    int maxWidth = NSWidth(self.frame)-NSMinX(self.textField.frame) - 20;
    
    [self.textField setFrameSize:NSMakeSize(maxWidth, NSHeight(self.textField.frame))];
    
    self.haveDots = 0;
}

-(BOOL)isActive {
    return self.textField.attributedStringValue.length != 0;
}

- (void) fire {
    
    self.needDots++;
    if(self.needDots > 3)
        self.needDots = 0;
    
    
    [[self.attributedString mutableString] setString:[[self.attributedString mutableString] substringToIndex:self.endString]];
    
    
    
    self.haveDots = 0;
    while(self.haveDots < self.needDots) {
        [self.attributedString appendString:@"."];
        self.haveDots++;
    }
    
    
    [self.textField setAttributedStringValue:self.attributedString];
    [self.textField sizeToFit];
}


- (CALayer *)_createTypingDot:(bool)large
{
    
    CALayer *layer = [[CALayer alloc] init];
    layer.frame = CGRectMake(0, 0, large ? 8 : 4, large ? 8 : 4);
    
    layer.cornerRadius = NSWidth(layer.frame)/2;
    
    layer.backgroundColor = NSColorFromRGB(0xcccccc).CGColor;
    
    layer.actions = @{@"content": [NSNull null], @"position": [NSNull null]};
    layer.opacity = large ? 0.0f : 1.0f;
    return layer;
    
}

- (NSArray *)typingDots
{
    if (_typingDots == nil)
    {
        _typingDots = @[[self _createTypingDot:false], [self _createTypingDot:false], [self _createTypingDot:false],
                        [self _createTypingDot:true], [self _createTypingDot:true], [self _createTypingDot:true]];
    }
    
    return _typingDots;
}

- (CAAnimation *)_animationFromOpacity:(CGFloat)fromOpacity to:(CGFloat)toOpacity duration:(NSTimeInterval)duration
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(fromOpacity);
    animation.toValue = @(toOpacity);
    animation.duration = duration;
    animation.removedOnCompletion = true;
    
    return animation;
}

- (void)_beginTypingAnimation:(bool)animated
{
    if (_typingAnimation)
        return;
    
    
    for (CALayer *layer in [self typingDots])
    {
        CAAnimation *animation = [layer animationForKey:@"opacity"];
        if ([animation.delegate isKindOfClass:[TGAnimationBlockDelegate class]])
            ((TGAnimationBlockDelegate *)animation.delegate).removeLayerOnCompletion = false;
        [layer removeAllAnimations];
        
        [self.typingView.layer addSublayer:layer];
    }
    [self setNeedsDisplay:YES];
    
    if (!_animationsAreSuspended)
    {
        _typingDotState = 0;
        [self _typingAnimationEvent];
        _typingDotTimer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(_typingAnimationEvent) interval:typingIntervalFirst repeat:true];
        [[NSRunLoop mainRunLoop] addTimer:_typingDotTimer forMode:NSRunLoopCommonModes];
        
        if (animated)
        {
            [self typingDots];
            for (int i = 0; i < 3; i++)
            {
                CALayer *layer = _typingDots[i];
                [layer addAnimation:[self _animationFromOpacity:0.0f to:1.0f duration:0.12] forKey:@"opacity"];
            }
        }
    }
    
    _typingAnimation = true;
}

- (void)_endTypingAnimation:(bool)animated
{
    if (!_typingAnimation)
        return;
    
    if (animated)
    {
        for (CALayer *layer in [self typingDots])
        {
            CAAnimation *animation = [self _animationFromOpacity:layer.opacity to:0.0f duration:0.12];
            TGAnimationBlockDelegate *delegate = [[TGAnimationBlockDelegate alloc] initWithLayer:layer];
            delegate.removeLayerOnCompletion = true;
            animation.delegate = delegate;
            [layer addAnimation:animation forKey:@"opacity"];
        }
    }
    else
    {
        for (CALayer *layer in [self typingDots])
        {
            [layer removeFromSuperlayer];
        }
    }
    
    [_typingDotTimer invalidate];
    _typingDotTimer = nil;
    
    _typingAnimation = false;
}

- (void)suspendAnimations
{
    _animationsAreSuspended = true;
    
    if (_typingAnimation)
    {
        [_typingDotTimer invalidate];
        _typingDotTimer = nil;
    }
}

- (void)resumeAnimations
{
    _animationsAreSuspended = false;
    
    if (_typingAnimation)
    {
        [_typingDotTimer invalidate];
        _typingDotTimer = nil;
        
        [self _typingAnimationEvent];
        _typingDotTimer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(_typingAnimationEvent) interval:typingIntervalFirst repeat:true];
        [[NSRunLoop mainRunLoop] addTimer:_typingDotTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)_typingAnimationEvent
{
    if (_typingDots.count == 0)
        return;
    
    int focusIndex = (_typingDotState++) % (_typingDots.count / 2);
    for (int index = 0; index < 3; index++)
    {
        CALayer *layer = _typingDots[3 + index];
        if (index == focusIndex)
        {
            CAAnimation *animation = [self _animationFromOpacity:0.0f to:1.0f duration:typingIntervalSecond];
            animation.autoreverses = true;
            [layer addAnimation:animation forKey:@"opacity"];
        }
    }
}

-(void)drawRect:(NSRect)dirtyRect {
    if (_typingAnimation)
    {
        CGPoint dotPosition = CGPointMake(6, 7);
        int index = -1;
        for (CALayer *layer in _typingDots)
        {
            index++;
            layer.position = CGPointMake(dotPosition.x + 8.0f * (index % 3), dotPosition.y);
        }
    }
}


@end
