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
        NSLog(@"error %@", error);
    }];
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(20, 100, 200, 50)];
    [self.view addSubview:button];
    [button setTitle:@"上传图片" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(uploadFile) forControlEvents:UIControlEventTouchUpInside];
}

- (void)uploadFile {
    PuaUpload *model = [PuaUpload new];
    [[SLNetworkManager share]requestWithModel:model uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"uploadProgress %@\n%@", @(uploadProgress.totalUnitCount), @(uploadProgress.completedUnitCount));
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error, BOOL needHandle) {
        NSLog(@"responseObject %@", responseObject);
        NSLog(@"error %@", error);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
