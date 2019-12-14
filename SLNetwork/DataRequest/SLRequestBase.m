//
//  SLRequestBase.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLRequestBase.h"
#import <SLNetwork/SLNetworkConfig.h>
#import <SLNetwork/SLNetworkTool.h>

@implementation SLRequestBase
- (SLRequestMethod)requestMethod {
    return SLRequestGet;
}
- (NSDictionary *)requestParams {
    return @{};
}
- (NSDictionary *)requestHead {
    return @{};
}
- (NSString *)requestUrl {
    return @"";
}
- (NSString *)requestBaseUrl {
    return [SLNetworkConfig share].baseUrl;
}
- (NSTimeInterval)requestTimeoutInterval {
    return 30;
}

- (NSArray<SLUploadFile *> *)uploadFiles {
    return @[];
}
- (BOOL)needCookie {
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@%@%@", @(self.requestMethod), self.requestUrl, [SLNetworkTool dictionaryToString:self.requestParams]];
}
@end
