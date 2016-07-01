//
//  ViewController.m
//  视频播放
//
//  Created by qianfeng007 on 16/6/29.
//  Copyright © 2016年 top. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
{
    BOOL isPush;
}
@property (strong, nonatomic) AVPlayer *myPlayer;

/** 播放单元 */
@property (nonatomic,strong) AVPlayerItem *item;
/** 播放界面 */
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
/** 进度显示 */
@property (nonatomic,strong) UISlider *avSlider;
/** 是否准备好 */
@property (nonatomic,assign) BOOL isReadyToPlay;
/** 进度 */
@property (nonatomic,strong) NSTimer *showTimer;
/** 播放暂停按钮 */
@property (nonatomic,strong) UIButton *palyButton;
/** 暂停的时间 */
@property (nonatomic,assign) CGFloat pauseTime;
@end

@implementation ViewController
//懒加载
- (UISlider *)avSlider
{
    if (!_avSlider) {
        _avSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 100, 300, 20)];
        [self.view addSubview:_avSlider];
    }
    return _avSlider;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.avSlider addTarget:self action:@selector(avSliderAction) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    [self setupAvPlayer];
}
- (void)avSliderAction
{
    float seconds= self.avSlider.value;
    NSLog(@"seconds %f",seconds);
    CMTime startTime = CMTimeMakeWithSeconds(seconds, self.item.duration.timescale);
    [self.myPlayer pause];
    [self.myPlayer seekToTime:startTime completionHandler:^(BOOL finished) {
        if (finished) {
            [self.myPlayer play];
        }
    }];
}
- (void)setupAvPlayer
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 400, 50, 50);
    [button setTitle:@"播放" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [button addTarget:self action:@selector(playerAction:) forControlEvents:UIControlEventTouchUpInside];
    self.palyButton = button;
    
    
    //    初始化播放网址
    NSString *path = [[NSBundle mainBundle] pathForResource:@"movie.mp4" ofType:nil];
    NSLog(@"%@",path);
    NSURL *url = [NSURL fileURLWithPath:path];
    //    初始化播放单元
    self.item = [AVPlayerItem playerItemWithURL:url];
    //    初始化播放对象
    self.myPlayer = [AVPlayer playerWithPlayerItem:self.item];
    //    初始化播放器layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.myPlayer];
    self.playerLayer.frame = CGRectMake(0, 200, self.view.frame.size.width, 200);
    self.playerLayer.backgroundColor = [UIColor orangeColor].CGColor;
    [self.view.layer addSublayer:self.playerLayer];
    
    
    //    高级设置
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.view addSubview:button];

}
- (void)playerAction
{
    if (self.isReadyToPlay){
        [self.myPlayer play];
        [self setupShowTimer];
    }
}
- (void)playerAction:(UIButton *)button
{
    button.selected = !button.isSelected;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    if (self.isReadyToPlay){
        if (button.selected) {
            [self beginPlay];
        }else{
            [self.myPlayer pause];
            self.pauseTime = self.avSlider.value;
            [self.showTimer invalidate];
            self.showTimer = nil;
        }
    }else{
        
    }
}
- (void)beginPlay
{
    [self.myPlayer play];
    //            self.avSlider.value = self.pauseTime;
    [self setupShowTimer];
}
- (void)setupShowTimer
{
    self.showTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updataTimeInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.showTimer forMode:NSRunLoopCommonModes];
}
- (void)updataTimeInfo
{
//    NSTimeInterval duration = CMTimeGetSeconds(self.myPlayer.currentItem.duration);
    NSTimeInterval currentTime = CMTimeGetSeconds(self.myPlayer.currentTime);
    self.avSlider.value = currentTime;
    NSLog(@"%f",self.avSlider.value);
    if (self.avSlider.value == 1.0) {
        self.avSlider.value = 0;
        [self.showTimer invalidate];
        self.showTimer = nil;
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        //取出status的新值
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] intValue];
        
        switch (status) {
            case AVPlayerItemStatusFailed:
            {
             NSLog(@"Item有误");
                self.isReadyToPlay = YES;
            }
                break;
            case AVPlayerItemStatusReadyToPlay:
            {
                NSLog(@"准备好播放");
                self.isReadyToPlay = YES;
//                [self.myPlayer play];
                self.avSlider.maximumValue = self.item.duration.value / self.item.duration.timescale;
                NSLog(@"maxValue:  %f",self.avSlider.maximumValue);
                
            }
                case AVPlayerItemStatusUnknown:
            {
                NSLog(@"视频资源出现未知错误");
//                self.isReadyToPlay = NO;
            }
                
            default:
                break;
        }
    }
    [object removeObserver:self forKeyPath:@"status"];
}



@end
