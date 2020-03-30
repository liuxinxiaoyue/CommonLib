//
//  LXFooterRefresh.m
//  LXLaunchDemo
//
//  Created by admin on 2020/3/26.
//  Copyright © 2020 admin. All rights reserved.
//

#import "LXFooterRefresh.h"

@interface LXFooterRefresh ()

@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) UILabel *tipLabel;

/** 一个新的拖拽 */
@property (assign, nonatomic, getter=isOneNewPan) BOOL oneNewPan;
@end
@implementation LXFooterRefresh

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    if (newSuperview) { // 新的父控件
        if (self.hidden == NO) {
            self.scrollView.mj_insetB += self.mj_h;
        }
        
        // 设置位置
        self.mj_y = _scrollView.mj_contentH;
    } else { // 被移除了
        if (self.hidden == NO) {
            self.scrollView.mj_insetB -= self.mj_h;
        }
    }
}

#pragma mark - 重写父类方法
- (void)prepare {
    [super prepare];
    // 设置刷新控件高度
    self.mj_h = 45.0;
}

- (void)placeSubviews {
    [super placeSubviews];
    self.backgroundColor = [UIColor redColor];
    // 布局子空间
    _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    [self addSubview:_loadingView];
    
    NSString *str = @"上拉加载数据";
    _tipLabel = [[UILabel alloc] init];
    _tipLabel.font = [UIFont systemFontOfSize:15.0];
    _tipLabel.textColor = [UIColor grayColor];
    _tipLabel.text = str;
    [self addSubview:_tipLabel];
    
    CGSize size = [str sizeWithAttributes:@{
        NSFontAttributeName: _tipLabel.font,
    }];
    _tipLabel.mj_w = ceil(size.width);
    _tipLabel.mj_h = 25.0;
    _tipLabel.mj_y = (self.mj_h - _tipLabel.mj_h) / 2;
    
    _loadingView.mj_w = 25.0;
    _loadingView.mj_h = 25.0;
    _loadingView.mj_y = _tipLabel.mj_y;
    _loadingView.mj_x = (self.mj_w - _loadingView.mj_w - _tipLabel.mj_w - 5) / 2;
    
    _tipLabel.mj_x = _loadingView.mj_x + _loadingView.mj_w + 5;
}

- (void)scrollViewContentSizeDidChange:(NSDictionary *)change {
    [super scrollViewContentSizeDidChange:change];
    CGSize size = [change[@"new"] CGSizeValue];
    
    //
    self.mj_y = size.height > self.scrollView.mj_h ? size.height : self.scrollView.mj_h;
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    [super scrollViewContentOffsetDidChange:change];
    
    NSLog(@"inserT = %.2f, contentH = %.2f, h = %.2f", _scrollView.mj_insetT, _scrollView.mj_contentH, _scrollView.mj_h);
    if (self.state != MJRefreshStateIdle || self.mj_y == 0) return;
    
    if (_scrollView.mj_insetT + _scrollView.mj_contentH > _scrollView.mj_h) { // 内容超过一个屏幕
        // 这里的_scrollView.mj_contentH替换掉self.mj_y更为合理
        if (_scrollView.mj_offsetY >= _scrollView.mj_contentH - _scrollView.mj_h + self.mj_h + _scrollView.mj_insetB) {
            // 防止手松开时连续调用
            CGPoint old = [change[@"old"] CGPointValue];
            CGPoint new = [change[@"new"] CGPointValue];
            if (new.y <= old.y) return;
            
            // 当底部刷新控件完全出现时，才刷新
            [self beginRefreshing];
        }
    }
}

- (void)scrollViewPanStateDidChange:(NSDictionary *)change {
    [super scrollViewPanStateDidChange:change];
    
    if (self.state != MJRefreshStateIdle) return;
    
    UIGestureRecognizerState panState = _scrollView.panGestureRecognizer.state;
    if (panState == UIGestureRecognizerStateEnded) {// 手松开
        if (_scrollView.mj_insetT + _scrollView.mj_contentH <= _scrollView.mj_h) {  // 不够一个屏幕
            if (_scrollView.mj_offsetY >= - _scrollView.mj_insetT) { // 向上拽
                [self beginRefreshing];
            }
        } else { // 超出一个屏幕
            if (_scrollView.mj_offsetY >= _scrollView.mj_contentH + _scrollView.mj_insetB - _scrollView.mj_h) {
                [self beginRefreshing];
            }
        }
    } else if (panState == UIGestureRecognizerStateBegan) {
        self.oneNewPan = YES;
    }
}

- (void)beginRefreshing {
    if (!self.isOneNewPan) return;
    
    [super beginRefreshing];
    
    self.oneNewPan = NO;
}

- (void)setState:(MJRefreshState)state {
    MJRefreshCheckState
    
    if (state == MJRefreshStateRefreshing) {
        [self executeRefreshingCallback];
    } else if (state == MJRefreshStateNoMoreData || state == MJRefreshStateIdle) {
        if (MJRefreshStateRefreshing == oldState) {
            if (self.endRefreshingCompletionBlock) {
                self.endRefreshingCompletionBlock();
            }
        }
    }
}


- (void)setHidden:(BOOL)hidden {
    BOOL lastHidden = self.isHidden;
    
    [super setHidden:hidden];
    
    if (!lastHidden && hidden) {
        self.state = MJRefreshStateIdle;
        
        self.scrollView.mj_insetB -= self.mj_h;
    } else if (lastHidden && !hidden) {
        self.scrollView.mj_insetB += self.mj_h;
        
        // 设置位置
        self.mj_y = _scrollView.mj_contentH;
    }
}
@end
