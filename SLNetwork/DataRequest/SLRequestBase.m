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
- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
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
- (BOOL)isProtectRequest {
    return NO;
}
- (BOOL)needCookie {
    return NO;
}
- (BOOL)statusCodeValidator {
    NSInteger code = self.response.statusCode;
    return (code >= 200 && code <= 299);
}
- (NSURLSessionTask *)requestTask {
    return self.currentTask;
}
- (void)setRequestTask:(NSURLSessionTask *)requestTask {
    self.currentTask = requestTask;
}
- (float)priority {
    return NSURLSessionTaskPriorityDefault;
}
- (NSString *)description {
    NSMutableArray *requestParameterKeys = [self.requestParams.allKeys mutableCopy];
    if (requestParameterKeys.count > 1) {
        [requestParameterKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
    }
    NSMutableString *mString = [NSMutableString stringWithString:[NSString stringWithFormat:@"%@%@",@(self.requestMethod), self.requestUrl]];
    [requestParameterKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        [mString appendFormat:@"&%@=%@",key, self.requestParams[key]];
    }];
    return [SLNetworkTool sl_md5String:mString];
}
@end
