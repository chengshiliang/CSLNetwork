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
    [[SLNetworkConfig share] addCommonRequestHeaderWithParams:@{@"Authorization": @"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJwcm0tY3AtYmFja2VuZCIsImF1ZCI6IlJTMjU2IiwiaWF0IjoxNTc3Nzc3MjQ0LCJ1aWQiOjUsImV4cCI6MTU3ODM4MjA0NCwibmJmIjoxNTc3Nzc3MTg0fQ.llHJCKXbvzw-wkCxpl5USeph2lxggPG6NL9Kf38j6bxeISyF4b3NeStALzZF4i7JKj0rV_kAimnPn82HVW4s2rbZ8zhg73s6oG3ruXyL4pTBG-WbHo89OFTGYCzLfq4v2Gk5SkUj4MDxg6LZgfcpyoCsl3VBEh1Djt-Sc2EbLCABqSLK3U4385D-FkVGKRz3br6YpHSbW-POzpdRlWxsctteBKqxFHFJNYTgYtPl3HSXbjHpsbI9SWwCgsqE-9xhgFECxNIVxB6zUk9MtmBiIleh0Pivwp1ZmA2UMw3_V5MxCZFyqF-GCRrtDsJfXW1FKEoHBjnh6zr4tGJeGLd4jdxOrdJnuBCDaqc-uxvCvAb3zvAcoEXqqJZVVk7eeouFZK3WH0tNYxSLW8pS4ESeYhBBcic9WMcYqsB3PUvy5RGpfGFegzYw_8A0eTBXHBS39byfw3JodspN2_h_b9gbEnDjckab6r292EzOKxFKUGyVC80q0h4nZaKVr4PYZqkZELj2wt3uSnWFEAwCd7knVsSwgEPcZ9vU3Pp361crE_sKTFmiUGeM9HhkEOVPsE6bTkvEXUFODgwUCinjzAG-GFBe249KV1Svir-3muwYmWQ-QaQvxyIxIX2VJlTtZIXbBMKLNbYhZakAM6M6OFqQ4rS-LQEAPsM50f6yE8pEAas"}];
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
