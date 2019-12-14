//
//  SLRequestSerialization.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>
#import <SLNetwork/SLRequestDataProtocol.h>


NS_ASSUME_NONNULL_BEGIN

@interface SLRequestSerialization : NSObject
- (NSMutableURLRequest *)generateRequestWithModel:(id<SLRequestDataProtocol>)model;
@end

NS_ASSUME_NONNULL_END
