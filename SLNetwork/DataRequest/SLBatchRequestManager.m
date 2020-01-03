//
//  SLBatchRequestManager.m
//  AFNetworking
//
//  Created by SZDT00135 on 2019/12/20.
//

#import "SLBatchRequestManager.h"
#import <SLNetwork/SLNetworkManager.h>

@interface SLBatchRequestAgent : NSObject
+ (instancetype)share;
@property (nonatomic, strong) NSMutableArray *agents;
@end

@implementation SLBatchRequestAgent

static SLBatchRequestAgent *sharedInstance;
+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.agents = [NSMutableArray array];
    });
    return sharedInstance;
}

- (void)addBatchRequest:(SLBatchRequestManager *)manager {
    [sharedInstance.agents addObject:manager];
}

- (void)removeBatchRequest:(SLBatchRequestManager *)manager {
    if ([sharedInstance.agents containsObject:manager]) {
        [sharedInstance.agents removeObject:manager];
    }
}

@end

@interface SLBatchRequestModel : NSObject
@property (nonatomic, strong) NSNumber *taskId;
@property (nonatomic, strong) id<SLRequestDataProtocol> model;
@property (nonatomic, copy) void(^uploadProgressBlock)(NSProgress *uploadProgress);
@property (nonatomic, copy) void(^completionHandle)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle);
@end

@implementation SLBatchRequestModel
- (NSNumber *)taskId {
    if (!_taskId) {
        return @-1;
    }
    return _taskId;
}
@end

@interface SLBatchRequestManager()
@property (nonatomic, strong) NSMutableArray *batchRequests;
@property (nonatomic, strong) dispatch_group_t group;
@end

@implementation SLBatchRequestManager
- (instancetype)init {
    if (self == [super init]) {
        self.batchRequests = [NSMutableArray array];
        self.group = dispatch_group_create();
    }
    return self;
}

- (void)addRequestWithModel:(id<SLRequestDataProtocol>)model
          completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle {
    [self addRequestWithModel:model
               uploadProgress:nil
            completionHandler:completionHandle];
}

- (void)addRequestWithModel:(id<SLRequestDataProtocol>)model
             uploadProgress:(void(^)(NSProgress *uploadProgress))uploadProgressBlock
          completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle {
    if (!model || ![model conformsToProtocol:@protocol(SLRequestDataProtocol)]) return;
    SLBatchRequestModel *requestModel = [SLBatchRequestModel new];
    requestModel.model = model;
    requestModel.uploadProgressBlock = [uploadProgressBlock copy];
    requestModel.completionHandle = [completionHandle copy];
    [self.batchRequests addObject:requestModel];
}

- (void)startRequest:(void(^)())completeBlock {
    [[SLBatchRequestAgent share]addBatchRequest:self];
    for (SLBatchRequestModel *requestModel in self.batchRequests) {
        dispatch_group_enter(self.group);
        __weak typeof (self)weakSelf = self;
        NSNumber *taskId = [[SLNetworkManager share]requestWithModel:requestModel.model
                                                      uploadProgress:requestModel.uploadProgressBlock
                                                   completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error, BOOL needHandle) {
            __strong typeof (weakSelf)strongSelf = weakSelf;
            !requestModel.completionHandle ?: requestModel.completionHandle(response, responseObject, error, needHandle);
            dispatch_group_leave(strongSelf.group);
        }];
        requestModel.taskId = taskId;
    }
    __weak typeof (self)weakSelf = self;
    dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
        __strong typeof (weakSelf)strongSelf = weakSelf;
        [[SLBatchRequestAgent share]removeBatchRequest:strongSelf];
        !completeBlock?:completeBlock();
    });
}

- (NSArray *)batchRequestIds {
    NSMutableArray *arrayM = [NSMutableArray arrayWithCapacity:self.batchRequests.count];
    for (SLBatchRequestModel *requestModel in self.batchRequests) {
        [arrayM addObject:requestModel.taskId];
    }
    return [arrayM copy];
}
@end
