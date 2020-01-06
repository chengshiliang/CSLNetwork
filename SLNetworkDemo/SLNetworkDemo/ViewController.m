//
//  ViewController.m
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "ViewController.h"
#import "PuaModel.h"
#import "SecondViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PuaList *model = [PuaList new];
    model.params = @{@"mail": @"shiliangcheng@hk01.com", @"page": @(1)};
    [[SLNetworkManager share]requestWithModel:model completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error, BOOL needHandle) {
        NSLog(@"responseObject %@", responseObject);
        NSLog(@"error %@", error);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (NSString *url in @[@"https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4",
    @"http://tb-video.bdstatic.com/tieba-smallvideo-transcode/3612804_e50cb68f52adb3c4c3f6135c0edcc7b0_3.mp4",
    @"http://tb-video.bdstatic.com/tieba-smallvideo-transcode/20985849_722f981a5ce0fc6d2a5a4f40cb0327a5_3.mp4",
    @"http://tb-video.bdstatic.com/tieba-smallvideo-transcode/27089192_abcedcf00b503195b7d09f2c91814ef2_3.mp4",
    @"http://tb-video.bdstatic.com/videocp/16514218_b3883a9f1e041a181bda58804e0a5192.mp4"]) {
        [[SLDownloadManager sharedManager]download:url
                                             state:^(SLDownloadState state) {
            NSLog(@"state %ld", state);
        }
                                          progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
            NSLog(@"progress %.2lf", receivedSize*1.0/expectedSize);
        }
                                        completion:^(BOOL isSuccess, NSString * _Nonnull filePath, NSError * _Nullable error) {
            
        }];
    }
    
    return;
    SecondViewController *vc = [SecondViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
