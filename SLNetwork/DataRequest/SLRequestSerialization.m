//
//  SLRequestSerialization.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLRequestSerialization.h"
#import <SLNetwork/SLNetworkTool.h>
#import <SLNetwork/SLNetworkConfig.h>

@implementation SLRequestSerialization
- (NSMutableURLRequest *)generateRequestWithModel:(id<SLRequestDataProtocol>)model {
    NSString *urlString = [SLNetworkTool realUrlString:model];
    if ([SLNetworkTool sl_networkEmptyString:urlString]) return nil;
    NSArray *uploadFiles = [model uploadFiles];
    NSMutableURLRequest *request;
    if (uploadFiles && uploadFiles.count > 0) {
        request = [self.requestSerialize multipartFormRequestWithMethod:[SLNetworkTool requestMethodFromMethodType:[model requestMethod]] URLString:urlString parameters:[model requestParams] constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            
        } error:nil];
    } else {
        request = [self.requestSerialize requestWithMethod:[SLNetworkTool requestMethodFromMethodType:[model requestMethod]] URLString:urlString parameters:[model requestParams] error:nil];
    }
    NSMutableDictionary *requestHeadInfo = [NSMutableDictionary dictionary];
    [requestHeadInfo addEntriesFromDictionary:[SLNetworkConfig share].commonHeader];
    [requestHeadInfo addEntriesFromDictionary:[model requestHead]];
    for (NSString *key in requestHeadInfo.allKeys) {
        if ([SLNetworkTool sl_networkEmptyString:key]) continue;
        id value = requestHeadInfo[key];
        if (!value) continue;
        [request setValue:value forHTTPHeaderField:key];
    }
    return nil;
}

- (AFHTTPRequestSerializer *)requestSerialize {
    if (!_requestSerialize) {
        _requestSerialize = [AFHTTPRequestSerializer serializer];
    }
    return _requestSerialize;
}
@end
