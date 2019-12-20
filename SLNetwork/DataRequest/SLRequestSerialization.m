//
//  SLRequestSerialization.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLRequestSerialization.h"
#import <SLNetwork/SLNetworkTool.h>
#import <SLNetwork/SLNetworkConfig.h>
#import <SLNetwork/SLUploadFile.h>
#import <AFNetworking/AFURLRequestSerialization.h>

@interface SLRequestSerialization()
@end

@implementation SLRequestSerialization
- (NSMutableURLRequest *)generateRequestWithModel:(id<SLRequestDataProtocol>)model requestSerialize:(AFHTTPRequestSerializer<AFURLRequestSerialization> *)requestSerialize{ 
    NSString *urlString = [SLNetworkTool realUrlString:model];
    if ([SLNetworkTool sl_networkEmptyString:urlString]) return nil;
    NSArray<SLUploadFile *> *uploadFiles = [model uploadFiles];
    NSMutableURLRequest *request;
    if ([SLNetworkTool isUploadRequest:uploadFiles]) {
        request = [requestSerialize multipartFormRequestWithMethod:[SLNetworkTool requestMethodFromMethodType:[model requestMethod]] URLString:urlString parameters:[model requestParams] constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            [uploadFiles enumerateObjectsUsingBlock:^(SLUploadFile *file, NSUInteger idx, BOOL *stop) {
                [formData appendPartWithFileData:file.fileData name:file.name fileName:file.fileName mimeType:file.mimeType];
            }];
        } error:nil];
    } else {
        request = [requestSerialize requestWithMethod:[SLNetworkTool requestMethodFromMethodType:[model requestMethod]] URLString:urlString parameters:[model requestParams] error:nil];
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
    return request;
}
@end
