//
//  SLRequestBase.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>
#import <CSLNetwork/SLRequestDataProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLRequestBase : NSObject<SLRequestDataProtocol>
+ (instancetype)initWithUrl:(NSString *)url
                     params:(id)params
                     method:(SLRequestMethod)method;
@property (nonatomic, strong) id params;
@property (nonatomic, assign) SLRequestMethod method;
@property (nonatomic, copy) NSString *url;
@end

NS_ASSUME_NONNULL_END
