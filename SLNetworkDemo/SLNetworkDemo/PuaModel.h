//
//  PuaModel.h
//  SLNetworkDemo
//
//  Created by SZDT00135 on 2019/12/23.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "SLRequestBase.h"

NS_ASSUME_NONNULL_BEGIN
@interface PuaList : SLRequestBase
@property (nonatomic, copy) NSDictionary *params;
@end

@interface PuaModel : SLRequestBase

@end

NS_ASSUME_NONNULL_END
