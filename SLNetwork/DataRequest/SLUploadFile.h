//
//  SLUploadFile.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface SLUploadFile : NSObject
+ (instancetype)initFileName:(NSString *)name fileData:(NSData *)fileData;

- (NSData *)fileData;
- (NSString *)fileName;
- (NSString *)mimeType;
- (NSString *)name;
@end

NS_ASSUME_NONNULL_END
