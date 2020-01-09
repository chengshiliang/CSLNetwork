//
//  SLDownLoadManager.h
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, SLDownloadQueueMode) {
    SLDownloadQueueModeFIFO, // 先入先出
    SLDownloadQueueModeFILO  // 先入后出
};

typedef NS_ENUM(NSInteger, SLDownloadState) {
    SLDownloadStateWaiting,
    SLDownloadStateRunning,
    SLDownloadStateSuspended,
    SLDownloadStateCanceled,
    SLDownloadStateCompleted,
    SLDownloadStateFailed
};

@interface SLDownloadModel : NSObject
@property (nonatomic, strong) NSOutputStream *outputStream; // write datas to the file

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, assign) SLDownloadState state;

@property (nonatomic, assign) NSInteger totalLength;

@property (nonatomic, copy) void (^stateBlock)(SLDownloadState state);

@property (nonatomic, copy) void (^progressBlock)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress);

@property (nonatomic, copy) void (^completionBlock)(BOOL isSuccess, NSString *filePath, NSError *_Nullable error);

- (void)closeOutputStream;

- (void)openOutputStream;
@end

@interface SLDownloadManager : NSObject
@property (nonatomic, copy) NSString *downloadFileDir;// 文件下载路径
@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, assign) NSInteger maxConcurrentCount;
@property (nonatomic, copy) NSString *downloadIdentifier;
@property (nonatomic, assign) SLDownloadQueueMode queueMode;
@property (nonatomic, strong) NSMutableDictionary<NSString *,void(^)(void)> *sessionCompleteHandle;
+ (instancetype)sharedManager;
- (void)download:(NSString *)urlString
           state:(void(^)(SLDownloadState state))stateBlock
        progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progressBlock
      completion:(void(^)(BOOL isSuccess, NSString *filePath, NSError *_Nullable error))completionBlock;
- (NSString *)downloadFilePathOfURL:(NSURL *)URL;
#pragma mark - Downloads
- (void)suspendDownloadOfURL:(NSURL *)URL;
- (void)suspendAllDownloads;

- (void)resumeDownloadOfURL:(NSURL *)URL;
- (void)resumeAllDownloads;

- (void)cancelDownloadOfURL:(NSURL *)URL;
- (void)cancelAllDownloads;

- (void)deleteFileOfURL:(NSURL *)URL;
- (void)deleteAllFiles;
@end

NS_ASSUME_NONNULL_END
