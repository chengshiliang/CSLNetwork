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
    SecondViewController *vc = [SecondViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
