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
        self.requestInfo = [NSMutableDictionary dictionary];
        self.sessionManager = [AFHTTPSessionManager manager];
        self.sessionManager.securityPolicy.validatesDomainName = NO;
        self.sessionManager.securityPolicy.allowInvalidCertificates = YES;
        self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:self.sessionManager.responseSerializer.acceptableContentTypes];
        [acceptableContentTypes addObject:@"text/html"];
        [acceptableContentTypes addObject:@"text/plain"];
        self.sessionManager.responseSerializer.acceptableContentTypes = [acceptableContentTypes copy];
    }
    return self;
}

- (NSNumber *)requestWithModel:(id<SLRequestDataProtocol>)model
             completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    return [self requestWithModel:model uploadProgress:nil completionHandler:completionHandle];
}

- (NSNumber *)requestWithModel:(id<SLRequestDataProtocol>)model
                uploadProgress:(void(^)(NSProgress *uploadProgress))uploadProgressBlock
             completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
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
    NSMutableURLRequest *request = [sharedInstance.requestSerialization generateRequestWithModel:model];
    if (!request) return @-1;
    __weak typeof (self)weakSelf = self;
    NSURLSessionDataTask *task;
    NSMutableArray *taskIdentifier = [NSMutableArray arrayWithObject:@(-1)];
    if ([SLNetworkTool isUploadRequest:[model uploadFiles]]) {
        task = [self.sessionManager uploadTaskWithStreamedRequest:request
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
        task = [self.sessionManager dataTaskWithRequest:request
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
    taskIdentifier[0] = @(task.taskIdentifier);
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    [self.requestInfo setObject:task forKey:taskIdentifier[0]];
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
    [self.requestInfo removeObjectForKey:taskIdentifier];
    dispatch_semaphore_signal(sharedInstance.semaphore);
    if ([[SLNetworkConfig share]handleResponseDataWithReponse:response
                                               responseObject:responseObject
                                                        error:error]) return;
    if (!error && [model cacheTimeInterval]>0) {
        NSString *cacheKey = [model description];
        SLNetworkCache *cache = [SLNetworkCache cacheWithData:responseObject validTimeInterval:[model cacheTimeInterval]];
        [[SLNetworkCacheManager sharedManager] setObjcet:cache forKey:cacheKey];
    }
    !completionHandle ?: completionHandle(response, responseObject, error);
}

- (void)cancelAllTask {
    for (NSURLSessionTask *task in self.requestInfo.allValues) {
        [task cancel];
    }
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    [self.requestInfo removeAllObjects];
    dispatch_semaphore_signal(sharedInstance.semaphore);
}

- (void)cancelTaskWithtaskIdentifier:(NSNumber *)taskIdentifier {
    if ([taskIdentifier intValue] < 0) return;
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    if ([self.requestInfo.allKeys containsObject:taskIdentifier]) {
        NSURLSessionTask *task = self.requestInfo[taskIdentifier];
        if (task) [task cancel];
        [self.requestInfo removeObjectForKey:taskIdentifier];
    }
    dispatch_semaphore_signal(sharedInstance.semaphore);
}

- (NSDictionary<NSNumber *,NSURLSessionTask *> *)requestTasks {
    return [self.requestInfo copy];
}
@end
