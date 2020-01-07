//
//  SLRequestBase.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLRequestBase.h"
#import <CSLNetwork/SLNetworkConfig.h>
#import <CSLNetwork/SLNetworkTool.h>

@implementation SLRequestBase
+ (instancetype)initWithUrl:(NSString *)url
                     params:(id)params
                     method:(SLRequestMethod)method {
    return [[self alloc]initWithUrl:url
                             params:params
                             method:method];
}

- (instancetype)initWithUrl:(NSString *)url
                     params:(id)params
                     method:(SLRequestMethod)method {
    if (self == [super init]) {
        self.url = url;
        self.params = params;
        self.method = method;
    }
    return self;
}
- (SLRequestMethod)requestMethod {
    return self.method;
}
- (id)requestParams {
    return self.params;
}
- (NSDictionary *)requestHead {
    return @{};
}
- (NSTimeInterval)cacheTimeInterval {
    return 0;
}
- (NSString *)requestUrl {
    return self.url;
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
- (NSString *)acceptContentTypes {
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
    NSMutableArray *requestParameterKeys = [NSMutableArray array];
    if (self.requestParams && [self.requestParams isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)self.requestParams;
        requestParameterKeys = [(NSDictionary *)dictionary.allKeys mutableCopy];
    }
    NSMutableString *mString = [NSMutableString stringWithString:[NSString stringWithFormat:@"%@%@",@(self.requestMethod), self.requestUrl]];
    if (!self.requestParams) return [SLNetworkTool sl_md5String:mString];
    if (requestParameterKeys.count > 1) {
        [requestParameterKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
        [requestParameterKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            [mString appendFormat:@"&%@=%@",key, self.requestParams[key]];
        }];
    } else {
        id params = self.requestParams;
        if ([params isKindOfClass:[NSArray class]] || [params isKindOfClass:[NSSet class]]) {
            [params enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
                [mString appendFormat:@"&%@=%@",key, self.requestParams[key]];
            }];
        } else {
            [mString appendFormat:@"%@", params];
        }
    }
    return [SLNetworkTool sl_md5String:mString];
}
@end
