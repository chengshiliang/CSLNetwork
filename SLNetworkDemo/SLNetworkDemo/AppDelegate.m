//
//  AppDelegate.m
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SLNetworkConfig share].responseBlock = ^BOOL(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 401) {
                NSLog(@"需要登录，跳转到登录页进行处理");
                [[SLNetworkManager share]cancelAllTask];
                return YES;
            }
        }
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseParams = (NSDictionary *)responseObject;
            NSInteger code = [responseParams[@"code"] integerValue];
            NSString *message = responseParams[@"message"];
            if (code == 53000 || code == 43007) {
                NSLog(@"需要登录，跳转到登录页进行处理");
                return YES;
            } else if (code != 0) {
                NSLog(@"请求错误 %@", message);
                return YES;
            } else {
                return NO;
            }
        }
        return NO;
    };
    [[SLNetworkConfig share] setBaseUrl:@"https://dev-prm-cp-backend.hktester.com/api/v1"];
    [[SLNetworkConfig share] addCommonRequestHeaderWithParams:@{@"Authorization": @"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJwcm0tY3AtYmFja2VuZCIsImF1ZCI6IlJTMjU2IiwiaWF0IjoxNTc3MDczMTIwLCJ1aWQiOjUsImV4cCI6MTU3NzY3NzkyMCwibmJmIjoxNTc3MDczMDYwfQ.Z3fhxR7YHQG9S9lR6JH6Sly7jKw4nShue4PEem8Bhbf2J1n7NFp7pWWYxax6H0kPk1Hc56_63kkHc6TqDc6b4Kaiwhj38swMcdo6XSSPXN-0dogffEo1X0bvZBK14LhBikk8Kb6_2OsCAxrsje81mIl2YMyytHU1vOzVlcWayKZ0zv1VrCXBcBT7eJKfcycVJvHD0Jv4PZv70_yPO3MMhXrtPKW1bCGBPhZSuNTSdFw_vWr5yMxs48HuTbbrwTylpmhEhCgNSvLdND3RJiOesHuXrSh5Xlm1U0XxE91a6YUyjGmTk-RjS5OpZZomaRuZcxCl5Io03khGsxBDRWWislzTBb9gmVCwKLRhvjOhbWA8SNpSiNq6XuoMyuYC35GU7gJNCotyM6orOdcA-_JhtWIIp4gR64yRxavkBWloPsGdQOYKwu8DutSKYQ1_nE9-GMDiGZI-wdswInvrBknNh_C9gQo1pbvQlmjbgx3_CZmnSpdCPt9rFc2m9lYMi7BlLRbv_4iajie-I127P-FHsERYB2_s-mS84JynQnCnGxTJJMa-hRX9hYpf99Ku8Ab0-B5VVsQGaIWFDC-cwyX6_BaYd_BsmMkrQxUEbHiSfYDBCfD032WnMb9DG7GTfTON5gczykwFwoXMS2RZ9p3WUM2-cOam8VS-_yZJtHDkUTA"}];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
