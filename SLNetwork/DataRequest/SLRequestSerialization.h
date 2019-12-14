//
//  SLRequestSerialization.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>
#import <SLNetwork/SLRequestDataProtocol.h>
#import <AFNetworking/AFURLRequestSerialization.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLRequestSerialization : NSObject
@property (nonatomic, strong) AFHTTPRequestSerializer *requestSerialize;
@end

NS_ASSUME_NONNULL_END
