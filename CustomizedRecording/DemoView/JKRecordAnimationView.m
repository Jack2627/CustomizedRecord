//
//  JKRecordAnimationView.m
//  CustomizedRecording
//
//  Created by Jack Xue on 2022/9/23.
//

#import "JKRecordAnimationView.h"

static const CGFloat kBaseWidth = 10.0;
static const CGFloat kSepOffset = 2.0;

@implementation JKRecordAnimationView{
    CALayer *_animLayer;
    CAShapeLayer *_baseLayer;
    BOOL _rec;
}

@synthesize recLineWidth = _recLineWidth;

- (instancetype)initWithFrame:(CGRect)frame
{
    CGFloat width = CGRectGetWidth(frame);
    CGFloat height = CGRectGetHeight(frame);
    if (width != height) {
        width = MIN(width, height);
        height = width;
        frame.size.width = width;
        frame.size.height = height;
    }
    self = [super initWithFrame:frame];
    if (self) {
        _rec = NO;
        
        _baseLayer = [[CAShapeLayer alloc] init];
        _baseLayer.lineWidth = kBaseWidth;
        _baseLayer.strokeColor = [UIColor whiteColor].CGColor;
        _baseLayer.fillColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:_baseLayer];
        
        _animLayer = [[CALayer alloc] init];
        _animLayer.backgroundColor = [UIColor redColor].CGColor;
        [self.layer addSublayer:_animLayer];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTap)];
        [self addGestureRecognizer:tap];
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)dealloc{
    NSLog(@"jkdebug dealloc animView");
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    
    if (width != height) {
        width = MIN(width, height);
        height = width;
        CGRect rect = self.frame;
        rect.size.width = width;
        rect.size.height = height;
        self.frame = rect;
        return;
    }
    
    CGFloat R = (CGRectGetWidth(self.bounds) - self.recLineWidth * 2);
    CGFloat rad = (CGRectGetWidth(self.bounds) - self.recLineWidth) / 2;
    if (_rec) {
        
        CGFloat r = R / 2;
        CGFloat l = hypot(r, r);
        CGFloat offset = (R - l)/2;
        _animLayer.frame = CGRectMake(self.recLineWidth + offset, self.recLineWidth + offset, l, l);

        _animLayer.cornerRadius = 10;
    }else{
        CGFloat animSize = R - self.sep * 2;
        _animLayer.frame = CGRectMake(self.recLineWidth + self.sep, self.recLineWidth + self.sep, animSize, animSize);
        
        _animLayer.cornerRadius = animSize / 2;
    }
    
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(width/2, height/2) radius:rad startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    _baseLayer.path = path.CGPath;
}

#pragma mark - Private
- (void)actionTap{
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordViewDidTap:)]) {
        [self.delegate recordViewDidTap:self];
    }
    //震动
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyleLight)];
        [feedback prepare];
        [feedback impactOccurred];
        feedback = nil;
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - Public
- (void)updateAnimation:(BOOL)rec{
    if (rec == _rec) {
        return;
    }
    _rec = rec;
    [self setNeedsLayout];
}

#pragma mark - Lazy
- (CGFloat)recLineWidth{
    if (_recLineWidth <= 0) {
        _recLineWidth = kBaseWidth;
    }
    return _recLineWidth;
}

- (void)setRecLineWidth:(CGFloat)recLineWidth{
    if (recLineWidth > 0) {
        _recLineWidth = recLineWidth;
        _baseLayer.lineWidth = recLineWidth;
    }
}

- (CGFloat)sep{
    if (_sep < 0) {
        _sep = kSepOffset;
    }
    return _sep;
}

@end
