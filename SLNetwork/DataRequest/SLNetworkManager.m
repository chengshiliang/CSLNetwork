//
//  SLNetworkManager.m
//  AFNetworking
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLNetworkManager.h"
#import <SLNetwork/SLRequestSerialization.h>
#import <SLNetwork/SLNetworkTool.h>
#import <SLNetwork/SLNetworkConfig.h>
#import <SLNetwork/SLNetworkCache.h>

@interface SLNetworkManager()
@property (nonatomic, assign) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) SLRequestSerialization *requestSerialization;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURLSessionTask *> *requestInfo;
@end

@implementation SLNetworkManager
static SLNetworkManager *sharedInstance;
+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        sharedInstance.semaphore = dispatch_semaphore_create(1);
        sharedInstance.requestSerialization = [[SLRequestSerialization alloc]init];
    });
    return sharedInstance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self share];
}
- (instancetype)init {
    if (self = [super init]) {
        sharedInstance.requestInfo = [NSMutableDictionary dictionary];
        sharedInstance.sessionManager = [AFHTTPSessionManager manager];
        sharedInstance.sessionManager.securityPolicy.validatesDomainName = NO;
        sharedInstance.sessionManager.securityPolicy.allowInvalidCertificates = YES;
        sharedInstance.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:sharedInstance.sessionManager.responseSerializer.acceptableContentTypes];
        [acceptableContentTypes addObject:@"text/html"];
        [acceptableContentTypes addObject:@"text/plain"];
        sharedInstance.sessionManager.responseSerializer.acceptableContentTypes = [acceptableContentTypes copy];
    }
    return self;
}

- (NSNumber *)requestWithModel:(id<SLRequestDataProtocol>)model
             completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    return [sharedInstance requestWithModel:model
                             uploadProgress:nil
                          completionHandler:completionHandle];
}

- (NSNumber *)requestWithModel:(id<SLRequestDataProtocol>)model
                uploadProgress:(void(^)(NSProgress *uploadProgress))uploadProgressBlock
             completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    if (!model || ![model conformsToProtocol:@protocol(SLRequestDataProtocol)]) return @-1;
    if ([model cacheTimeInterval]>0) {
        NSString *cacheKey = [model description];
        SLNetworkCache *cache = [[SLNetworkCacheManager sharedManager] cacheForKey:cacheKey];
        if (!cache || !cache.isValid) {
            [[SLNetworkCacheManager sharedManager] removeCacheForKey:cacheKey];
        } else {
            if ([[SLNetworkConfig share]handleResponseDataWithReponse:nil
                                                       responseObject:cache.data
                                                                error:nil]) return @-1;
            !completionHandle ?:completionHandle(nil, cache.data, nil);
            return @-1;
        }
    }
    AFHTTPRequestSerializer *requestSerialize = [model requestSerializer];
    if (!requestSerialize) {
        requestSerialize = [AFHTTPRequestSerializer serializer];
    }
    sharedInstance.sessionManager.requestSerializer = requestSerialize;
    AFHTTPResponseSerializer *responseSerializer = [model responseSerializer];
    if (responseSerializer) {
        sharedInstance.sessionManager.responseSerializer = responseSerializer;
    }
    NSMutableURLRequest *request = [model customRequest];
    if (!request) {
        request = [sharedInstance.requestSerialization generateRequestWithModel:model requestSerialize:requestSerialize];
    }
    if (!request) return @-1;
    __weak typeof (sharedInstance)weakSelf = sharedInstance;
    NSURLSessionDataTask *task;
    NSMutableArray *taskIdentifier = [NSMutableArray arrayWithObject:@(-1)];
    if ([SLNetworkTool isUploadRequest:[model uploadFiles]]) {
        task = [sharedInstance.sessionManager uploadTaskWithStreamedRequest:request
                                                                   progress:uploadProgressBlock
                                                          completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            __strong typeof (weakSelf)strongSelf = weakSelf;
            [strongSelf handleReponseResultWithModel:model
                                             reponse:response
                                      responseObject:responseObject
                                      taskIdentifier:taskIdentifier.firstObject
                                               error:error
                                   completionHandler:completionHandle];
        }];
    } else {
        task = [sharedInstance.sessionManager dataTaskWithRequest:request
                                                   uploadProgress:nil
                                                 downloadProgress:nil
                                                completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            __strong typeof (weakSelf)strongSelf = weakSelf;
            [strongSelf handleReponseResultWithModel:model
                                             reponse:response
                                      responseObject:responseObject
                                      taskIdentifier:taskIdentifier.firstObject
                                               error:error
                                   completionHandler:completionHandle];
        }];
    }
    task.priority = [model priority];
    taskIdentifier[0] = @(task.taskIdentifier);
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    [sharedInstance.requestInfo setObject:task forKey:taskIdentifier[0]];
    dispatch_semaphore_signal(sharedInstance.semaphore);
    [task resume];
    return @(task.taskIdentifier);
}

- (void)handleReponseResultWithModel:(id<SLRequestDataProtocol>)model
                             reponse:(NSURLResponse *)response
                      responseObject:(id)responseObject
                      taskIdentifier:(NSNumber *)taskIdentifier
                               error:(NSError *)error
                   completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    [sharedInstance.requestInfo removeObjectForKey:taskIdentifier];
    if ([[SLNetworkConfig share]handleResponseDataWithReponse:response
                                               responseObject:responseObject
                                                        error:error]) {
        dispatch_semaphore_signal(sharedInstance.semaphore);
        return;
    }
    if (!error && [model cacheTimeInterval]>0) {
        NSString *cacheKey = [model description];
        SLNetworkCache *cache = [SLNetworkCache cacheWithData:responseObject validTimeInterval:[model cacheTimeInterval]];
        [[SLNetworkCacheManager sharedManager] setObjcet:cache forKey:cacheKey];
    }
    !completionHandle ?: completionHandle(response, responseObject, error);
    dispatch_semaphore_signal(sharedInstance.semaphore);
}

- (void)cancelAllTask {
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    for (NSURLSessionTask *task in sharedInstance.requestInfo.allValues) {
        [task cancel];
    }
    [sharedInstance.requestInfo removeAllObjects];
    dispatch_semaphore_signal(sharedInstance.semaphore);
}

- (void)cancelTaskWithtaskIdentifier:(NSNumber *)taskIdentifier {
    if ([taskIdentifier intValue] < 0) return;
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    if ([sharedInstance.requestInfo.allKeys containsObject:taskIdentifier]) {
        NSURLSessionTask *task = sharedInstance.requestInfo[taskIdentifier];
        if (task) [task cancel];
        [sharedInstance.requestInfo removeObjectForKey:taskIdentifier];
    }
    dispatch_semaphore_signal(sharedInstance.semaphore);
}

- (NSDictionary<NSNumber *,NSURLSessionTask *> *)requestTasks {
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    NSDictionary *dic = [sharedInstance.requestInfo copy];
    dispatch_semaphore_signal(sharedInstance.semaphore);
    return dic;
}
@end
