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
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) SLRequestSerialization *requestSerialization;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURLSessionTask *> *requestInfo;
@end

@implementation SLNetworkManager
static SLNetworkManager *sharedInstance;
static NSString *SLNetworkStatusCodeError = @"SLNetworkStatusCodeError";
static NSString *SLNetworkResponseValidateError = @"SLNetworkResponseValidateError";
+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self == [super init]) {
        self.semaphore = dispatch_semaphore_create(1);
        self.requestSerialization = [[SLRequestSerialization alloc]init];
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
             completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle {
    return [sharedInstance requestWithModel:model
                             uploadProgress:nil
                          completionHandler:completionHandle];
}

- (NSNumber *)requestWithModel:(id<SLRequestDataProtocol>)model
                uploadProgress:(void(^)(NSProgress *uploadProgress))uploadProgressBlock
             completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle {
    if (!model || ![model conformsToProtocol:@protocol(SLRequestDataProtocol)]) return @-1;
    if ([model cacheTimeInterval]>0) {
        NSString *cacheKey = [model description];
        SLNetworkCache *cache = [[SLNetworkCacheManager sharedManager] cacheForKey:cacheKey];
        if (!cache || !cache.isValid) {
            [[SLNetworkCacheManager sharedManager] removeCacheForKey:cacheKey];
        } else {
            if ([[SLNetworkConfig share]handleResponseDataWithReponse:nil
                                                       responseObject:cache.data
                                                                error:nil]) {
                !completionHandle ?:completionHandle(nil, cache.data, nil, NO);
                return @-1;
            }
            !completionHandle ?:completionHandle(nil, cache.data, nil, YES);
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
                   completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle {
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    [sharedInstance.requestInfo removeObjectForKey:taskIdentifier];
    NSError *validateError = nil;
    if (![sharedInstance validateResult:model response:(NSHTTPURLResponse *)response responseObject:responseObject error:&validateError]) {
        dispatch_semaphore_signal(sharedInstance.semaphore);
        !completionHandle ?: completionHandle(nil, nil, validateError, NO);
        return;
    }
    if ([[SLNetworkConfig share]handleResponseDataWithReponse:response
                                               responseObject:responseObject
                                                        error:error]) {
        dispatch_semaphore_signal(sharedInstance.semaphore);
        !completionHandle ?: completionHandle(response, responseObject, error, NO);
        return;
    }
    if (!error && [model cacheTimeInterval]>0) {
        NSString *cacheKey = [model description];
        SLNetworkCache *cache = [SLNetworkCache cacheWithData:responseObject validTimeInterval:[model cacheTimeInterval]];
        [[SLNetworkCacheManager sharedManager] setObjcet:cache forKey:cacheKey];
    }
    dispatch_semaphore_signal(sharedInstance.semaphore);
    !completionHandle ?: completionHandle(response, responseObject, error, YES);
}

- (BOOL)validateResult:(id<SLRequestDataProtocol>)model response:(NSHTTPURLResponse *)response responseObject:(id)responseObject error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [model statusCodeValidator:response];
    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:SLNetworkStatusCodeError code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Invalid status code"}];
        }
        return result;
    }
    id validator = [model jsonValidator];
    if (responseObject && validator) {
        result = [SLNetworkTool validateJSON:responseObject withValidator:validator];
        if (!result) {
            if (error) {
                *error = [NSError errorWithDomain:SLNetworkResponseValidateError code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
            }
            return result;
        }
    }
    return YES;
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
