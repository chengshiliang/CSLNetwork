//
//  ViewController.m
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "ViewController.h"
#import "PuaModel.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PuaList *model = [PuaList new];
    model.params = @{};
    [[SLNetworkManager share]requestWithModel:model completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error, BOOL needHandle) {
        NSLog(@"responseObject %@", responseObject);
        NSLog(@"response %@", response);
        NSLog(@"error %@", error);
    }];
}


@end
