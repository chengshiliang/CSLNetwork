//
//  SLDownloadModel.h
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SLDownloadState) {
    SLDownloadStateWaiting,
    SLDownloadStateRunning,
    SLDownloadStateSuspended,
    SLDownloadStateCanceled,
    SLDownloadStateCompleted,
    SLDownloadStateFailed
};
NS_ASSUME_NONNULL_BEGIN

@interface SLDownloadModel : NSObject
@property (nonatomic, strong) NSOutputStream *outputStream; // write datas to the file

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, assign) NSInteger totalLength;

@property (nonatomic, copy) void (^stateBlock)(SLDownloadState state);

@property (nonatomic, copy) void (^progressBlock)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress);

@property (nonatomic, copy) void (^completionBlock)(BOOL isSuccess, NSString *filePath, NSError *_Nullable error);

- (void)closeOutputStream;

- (void)openOutputStream;
@end

NS_ASSUME_NONNULL_END
