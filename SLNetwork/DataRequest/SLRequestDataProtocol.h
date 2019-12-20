//
//  SLRequestDataProtocol.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>
#import <SLNetwork/SLUploadFile.h>

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
@optional
- (NSArray<SLUploadFile *> *)uploadFiles;
- (BOOL)needCookie;
@end

NS_ASSUME_NONNULL_END
