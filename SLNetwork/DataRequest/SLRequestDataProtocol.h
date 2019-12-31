//
//  SLRequestDataProtocol.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>
#import <SLNetwork/SLUploadFile.h>
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, SLRequestMethod) {
    SLRequestGet,
    SLRequestHead,
    SLRequestDelete,
    SLRequestPost,
    SLRequestPatch,
    SLRequestPut
};

@protocol SLRequestDataProtocol <NSObject>
- (SLRequestMethod)requestMethod;
- (NSDictionary *)requestParams;
- (NSDictionary *)requestHead;
- (NSString *)requestUrl;
- (NSString *)requestBaseUrl;
- (NSTimeInterval)requestTimeoutInterval;
- (NSTimeInterval)cacheTimeInterval;
- (BOOL)isProtectRequest;// 受保护的请求，不会清除缓存。例如首页数据
/**
 NSURLSessionTaskPriorityHigh
 NSURLSessionTaskPriorityDefault
 NSURLSessionTaskPriorityLow
 */
- (float)priority;// 网络访问优先级
- (id)jsonValidator;
- (BOOL)statusCodeValidator:(NSHTTPURLResponse *)response;
@optional
- (NSArray<SLUploadFile *> *)uploadFiles;
- (NSString *)acceptContentTypes;
- (BOOL)allowsCellularAccess;
- (AFHTTPRequestSerializer<AFURLRequestSerialization> *)requestSerializer;
- (AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializer;
- (NSMutableURLRequest *)customRequest;// 自定义请求
@end

NS_ASSUME_NONNULL_END
