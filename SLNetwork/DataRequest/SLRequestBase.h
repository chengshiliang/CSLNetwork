//
//  SLRequestBase.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>
#import <SLNetwork/SLRequestDataProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLRequestBase : NSObject<SLRequestDataProtocol>
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, assign) SLRequestMethod method;
@end

NS_ASSUME_NONNULL_END
