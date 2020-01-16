//
//  SLUploadFile.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLUploadFile.h"
#import <CSLNetwork/SLNetworkTool.h>

@interface SLUploadFile()
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, strong) NSData *fileData;
@end

@implementation SLUploadFile
+ (instancetype)initFileName:(NSString *)name fileData:(nonnull NSData *)fileData {
    return [[self alloc]initFileName:name fileData:fileData mineType:nil];
}

- (instancetype)initFileName:(NSString *)name fileData:(nonnull NSData *)fileData mineType:(NSString *)mineType{
    if (self == [super init]) {
        if ([SLNetworkTool sl_networkEmptyString:mineType]) self.mimeType = [SLNetworkTool fileTypeFromFileName:name];
        else self.mimeType = mineType;
        if ([SLNetworkTool sl_networkEmptyString:self.mimeType]) return self;
        self.fileName = name;
        self.name = [SLNetworkTool sl_md5String:name];
        self.fileData = fileData;
    }
    return self;
}

+ (instancetype)initFileName:(NSString *)name fileData:(NSData *)fileData mineType:(NSString *)mineType {
    return [[self alloc]initFileName:name fileData:fileData mineType:mineType];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"\nfileName: %@\nmineType: %@\nname: %@",self.fileName,self.mimeType,self.name];
}
@end
