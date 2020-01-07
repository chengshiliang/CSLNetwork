//
//  SLBatchRequestManager.h
//  AFNetworking
//
//  Created by SZDT00135 on 2019/12/20.
//

#import <Foundation/Foundation.h>
#import <CSLNetwork/SLRequestDataProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLBatchRequestManager : NSObject
@property (nonatomic, copy) NSArray *batchRequestIds;
- (void)startRequest:(void(^)(void))completeBlock;
- (void)addRequestWithModel:(id<SLRequestDataProtocol>)model
          completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle;
- (void)addRequestWithModel:(id<SLRequestDataProtocol>)model
             uploadProgress:(void(^_Nullable)(NSProgress *uploadProgress))uploadProgressBlock
          completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle;
@end

NS_ASSUME_NONNULL_END
