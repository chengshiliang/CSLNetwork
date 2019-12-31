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
    return self.method;
}
- (NSDictionary *)requestParams {
    return self.params;
}
- (NSDictionary *)requestHead {
    return @{};
}
- (NSTimeInterval)cacheTimeInterval {
    return 0;
}
- (NSString *)requestUrl {
    return @"";
}
- (NSString *)requestBaseUrl {
    return [SLNetworkConfig share].baseUrl;
}
- (NSTimeInterval)requestTimeoutInterval {
    return [SLNetworkConfig share].requestTimeoutInteval;
}

- (NSArray<SLUploadFile *> *)uploadFiles {
    return @[];
}
- (BOOL)isProtectRequest {
    return NO;
}
- (float)priority {
    return NSURLSessionTaskPriorityDefault;
}
- (AFHTTPRequestSerializer<AFURLRequestSerialization> *)requestSerializer {
    return nil;
}
- (AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializer {
    return nil;
}
- (NSMutableURLRequest *)customRequest {
    return nil;
}
- (BOOL)allowsCellularAccess {
    return YES;
}
- (id)jsonValidator {
    return nil;
}
- (BOOL)statusCodeValidator:(NSHTTPURLResponse *)response {
    NSInteger statusCode = response.statusCode;
    return (statusCode >= 200 && statusCode <= 299);
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
