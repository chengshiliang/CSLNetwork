//
//  SLBatchRequestManager.h
//  AFNetworking
//
//  Created by SZDT00135 on 2019/12/20.
//

#import <Foundation/Foundation.h>
#import <SLNetwork/SLRequestDataProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLBatchRequestManager : NSObject
@property (nonatomic, copy) NSArray *batchRequestIds;
@end

NS_ASSUME_NONNULL_END
