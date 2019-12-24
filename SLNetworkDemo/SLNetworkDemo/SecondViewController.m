//
//  SecondViewController.m
//  SLNetworkDemo
//
//  Created by SZDT00135 on 2019/12/23.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "SecondViewController.h"
#import "PuaModel.h"
@interface SecondViewController ()

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PuaAudit *model = [PuaAudit new];
    [model setParams:@{@"pass": @(true), @"memo": @"发发发"}];
    [[SLNetworkManager share]requestWithModel:model completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error, BOOL needHandle) {
        NSLog(@"responseObject %@", responseObject);
        NSLog(@"errorm %@", error);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
