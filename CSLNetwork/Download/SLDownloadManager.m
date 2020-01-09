//
//  SLDownloadManager.m
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "SLDownloadManager.h"
#import <CSLNetwork/SLNetworkTool.h>
#import <CSLNetwork/NSURLSession+CorrectedResumeData.h>

@implementation SLDownloadModel

@end

@interface SLDownloadManager()<NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary *downloadModelInfo;
@property (nonatomic, strong) NSMutableArray *downloadingModels;
@property (nonatomic, strong) NSMutableArray *waitingModels;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@end

@implementation SLDownloadManager
static SLDownloadManager *downloadManager;
- (NSMutableDictionary *)downloadModelInfo {
    
    if (!_downloadModelInfo) {
        _downloadModelInfo = [NSMutableDictionary dictionary];
    }
    return _downloadModelInfo;
}

- (NSMutableArray *)downloadingModels {
    if (!_downloadingModels) {
        _downloadingModels = [NSMutableArray array];
    }
    return _downloadingModels;
}

- (NSMutableArray *)waitingModels {
    if (!_waitingModels) {
        _waitingModels = [NSMutableArray array];
    }
    return _waitingModels;
}

+ (instancetype)sharedManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[self alloc] init];
        NSURLSessionConfiguration *backConfiguration =[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:downloadManager.downloadIdentifier];
        [backConfiguration setNetworkServiceType:NSURLNetworkServiceTypeBackground];
        downloadManager.session = [NSURLSession sessionWithConfiguration:backConfiguration
                                                                delegate:downloadManager
                                                           delegateQueue:[[NSOperationQueue alloc] init]];
        downloadManager.maxConcurrentCount = -1;
        downloadManager.lock = [NSLock new];
        downloadManager.downloadQueue = dispatch_queue_create("com.sl.download", DISPATCH_QUEUE_CONCURRENT);
        downloadManager.sessionCompleteHandle = [NSMutableDictionary dictionary];
    });
    return downloadManager;
}

- (instancetype)init{
    if (self = [super init]) {
        self.downloadIdentifier = @"SLDownloadTaskIdentifier";
    }
    return self;
}

- (void)setDownloadIdentifier:(NSString *)downloadIdentifier {
    if ([SLNetworkTool sl_networkEmptyString:downloadIdentifier]) return;
    _downloadIdentifier = downloadIdentifier;
}

- (BOOL)hasSpaceDownloadQueue {
    if (downloadManager.maxConcurrentCount <= 0) return YES;
    if (downloadManager.downloadingModels.count >= downloadManager.maxConcurrentCount) return NO;
    return YES;
}

- (void)download:(NSURL *)url
           state:(void(^)(SLDownloadState state))stateBlock
        progress:(void(^)(int64_t receivedSize, int64_t expectedSize, CGFloat progress))progressBlock
      completion:(void(^)(BOOL isSuccess, NSString *filePath, NSError *_Nullable error))completionBlock {
    if (!url) return;
    NSString *downloadFilePath = [downloadManager downloadFilePathOfURL:url];
    NSUInteger receivedSize = [downloadManager downloadedLengthOfURL:url];
    if ([downloadManager doneDownloadOfURL:url]) {
        if (stateBlock) stateBlock(SLDownloadStateCompleted);
        if (completionBlock) completionBlock(YES,downloadFilePath,nil);
        if (progressBlock) progressBlock(receivedSize,receivedSize,1);
        return;
    }
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    if (downloadModel) {
        if (downloadModel.stateBlock) downloadModel.stateBlock(downloadModel.state);
        if (downloadModel.progressBlock) {
            int64_t expectedSize = downloadModel.totalLength;
            if (expectedSize == 0) return;
            CGFloat progress = 1.0 * receivedSize / expectedSize;
            downloadModel.progressBlock(receivedSize, expectedSize, progress);
        }
        [downloadManager downloadWithModel:downloadModel];
        return;
    }
    [downloadManager.lock lock];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *dataTask = [downloadManager.session downloadTaskWithRequest:request];
    dataTask.taskDescription = fileName;
    downloadModel = [[SLDownloadModel alloc] init];
    downloadModel.stateBlock = stateBlock;
    downloadModel.progressBlock = progressBlock;
    downloadModel.completionBlock = completionBlock;
    downloadModel.dataTask = dataTask;
    downloadModel.url = url;
    downloadManager.downloadModelInfo[fileName] = downloadModel;
    [downloadManager.lock unlock];
    [downloadManager downloadWithModel:downloadModel];
}

- (void)downloadNext {
    if (downloadManager.maxConcurrentCount <= 0) return;
    if (downloadManager.waitingModels.count == 0) return;
    [downloadManager.lock lock];
    SLDownloadModel *downloadModel = downloadManager.waitingModels.firstObject;
    [downloadManager.waitingModels removeObjectAtIndex:0];
    [downloadManager downloadWithModel:downloadModel];
    [downloadManager.lock unlock];
}

- (NSString*)fileNameOfURL:(NSURL *)url {
    if (!url) return @"";
    return [url lastPathComponent];
}

- (void)downloadWithModel:(SLDownloadModel *)downloadModel {
    [downloadManager.lock lock];
    if ([downloadManager hasSpaceDownloadQueue]) {
        [downloadManager.downloadingModels addObject:downloadModel];
        if (downloadModel.resumeData) {
            NSString *fileName = [downloadManager fileNameOfURL:downloadModel.url];
            NSURLSessionDownloadTask *dataTask;
            CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
            if (version >= 10.0 && version < 10.2) {
                dataTask = [downloadManager.session downloadTaskWithCorrectResumeData:downloadModel.resumeData];
            } else {
                dataTask = [downloadManager.session downloadTaskWithResumeData:downloadModel.resumeData];
            }
            dataTask.taskDescription = fileName;
            downloadModel.dataTask = dataTask;
        }
        [downloadModel.dataTask resume];
        downloadModel.state = SLDownloadStateRunning;
    } else {
        [downloadManager.waitingModels insertObject:downloadModel atIndex:0];
        downloadModel.state = SLDownloadStateWaiting;
    }
    [downloadManager.lock unlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.stateBlock) {
            downloadModel.stateBlock(downloadModel.state);
        }
    });
}

- (NSString *)downloadFileDir {
    if (!_downloadFileDir) {
        _downloadFileDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        _downloadFileDir = [_downloadFileDir stringByAppendingPathComponent:@"sldownloadfile"];
    }
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:_downloadFileDir isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:_downloadFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return _downloadFileDir;
}

- (NSString *)downloadFileLengthPath {
    return [[downloadManager downloadFileDir]stringByAppendingPathComponent:@"SLDownloadTotalLength.plist"];
}

- (NSString *)downloadFilePathOfString:(NSString *)urlString {
    return [[downloadManager downloadFileDir]stringByAppendingPathComponent:urlString];
}

- (NSString *)downloadFilePathOfURL:(NSURL *)url {
    return [[downloadManager downloadFileDir]stringByAppendingPathComponent:[downloadManager fileNameOfURL:url]];
}

- (NSInteger)downloadedLengthOfURL:(NSURL *)url {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[downloadManager downloadFilePathOfURL:url] error:nil];
    if (!fileAttributes) {
        return 0;
    }
    return [fileAttributes[NSFileSize] integerValue];
}

- (NSInteger)totalLength:(NSURL *)url {
    NSString *fileName = [downloadManager fileNameOfURL:url];
    NSDictionary *filesTotalLenthInfo = [NSDictionary dictionaryWithContentsOfFile:[downloadManager downloadFileLengthPath]];
    if (!filesTotalLenthInfo || !filesTotalLenthInfo[fileName]) {
        return 0;
    }
    return [filesTotalLenthInfo[fileName] integerValue];
}

- (BOOL)doneDownloadOfURL:(NSURL *)url {
    NSInteger totalLength = [downloadManager totalLength:url];
    if (totalLength != 0) {
        if (totalLength == [downloadManager downloadedLengthOfURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (void)suspendDownloadOfURL:(NSURL *)url {
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [downloadManager.lock lock];
    downloadModel.state = SLDownloadStateSuspended;
    if (downloadModel.stateBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.stateBlock(SLDownloadStateSuspended);
        });
    }
    if ([downloadManager.downloadingModels containsObject:downloadModel]) {
        __weak typeof(downloadModel)weakModel = downloadModel;
        [downloadModel.dataTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            __strong typeof(downloadModel)strongModel = weakModel;
            strongModel.resumeData = resumeData;
        }];
        [downloadManager.downloadingModels removeObject:downloadModel];
        [downloadManager.waitingModels addObject:downloadModel];
    }
    [downloadManager.lock unlock];
    [downloadManager downloadNext];
}
- (void)suspendAllDownloads {
    if (downloadManager.downloadModelInfo.count <= 0) return;
    [downloadManager.lock lock];
    for (int i = 0; i<downloadManager.waitingModels.count; i++) {
        SLDownloadModel *downloadModel = downloadManager.waitingModels[i];
        downloadModel.state = SLDownloadStateSuspended;
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
    }
    [downloadManager.waitingModels removeAllObjects];
    for (int i = 0; i<downloadManager.downloadingModels.count; i++) {
        SLDownloadModel *downloadModel = downloadManager.downloadingModels[i];
        __weak typeof(downloadModel)weakModel = downloadModel;
        [downloadModel.dataTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            __strong typeof(downloadModel)strongModel = weakModel;
            strongModel.resumeData = resumeData;
        }];
        downloadModel.state = SLDownloadStateSuspended;
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
        [downloadManager.waitingModels addObject:downloadModel];
    }
    [downloadManager.downloadingModels removeAllObjects];
    [downloadManager.lock unlock];
}

- (void)resumeDownloadOfURL:(NSURL *)url {
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [downloadManager downloadWithModel:downloadModel];
}
- (void)resumeAllDownloads {
    if (downloadManager.downloadModelInfo.count <= 0) return;
    NSArray *downloadModels = downloadManager.downloadModelInfo.allValues;
    for (int i = 0; i<downloadModels.count; i++) {
        SLDownloadModel *downloadModel = downloadModels[i];
        [downloadManager downloadWithModel:downloadModel];
    }
}

- (void)cancelDownloadOfURL:(NSURL *)url {
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [downloadManager.lock lock];
    __weak typeof(downloadModel)weakModel = downloadModel;
    [downloadModel.dataTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        __strong typeof(downloadModel)strongModel = weakModel;
        strongModel.resumeData = resumeData;
    }];
    downloadModel.state = SLDownloadStateSuspended;
    if (downloadModel.stateBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.stateBlock(SLDownloadStateSuspended);
        });
    }
    if ([downloadManager.downloadingModels containsObject:downloadModel]) {
        [downloadManager.downloadingModels removeObject:downloadModel];
        [downloadManager.waitingModels addObject:downloadModel];
    }
    [downloadManager.lock unlock];
    [downloadManager downloadNext];
}
- (void)cancelAllDownloads {
    if (downloadManager.downloadModelInfo.count <= 0) return;
    [downloadManager.lock lock];
    NSArray *downloadModels = downloadManager.downloadModelInfo.allValues;
    for (int i = 0; i<downloadModels.count; i++) {
        SLDownloadModel *downloadModel = downloadModels[i];
        __weak typeof(downloadModel)weakModel = downloadModel;
        [downloadModel.dataTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            __strong typeof(downloadModel)strongModel = weakModel;
            strongModel.resumeData = resumeData;
        }];
        downloadModel.state = SLDownloadStateSuspended;
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
        if ([downloadManager.downloadingModels containsObject:downloadModel]) {
            [downloadManager.downloadingModels removeObject:downloadModel];
            [downloadManager.waitingModels addObject:downloadModel];
        }
    }
    [downloadManager.lock unlock];
}

- (void)deleteFile:(NSString *)fileName {
    if ([SLNetworkTool sl_networkEmptyString:fileName]) return;
    dispatch_async(downloadManager.downloadQueue, ^{
        NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:[downloadManager downloadFileLengthPath]];
        [filesTotalLength removeObjectForKey:fileName];
        [filesTotalLength writeToFile:[downloadManager downloadFileLengthPath] atomically:YES];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *downloadFilePath = [downloadManager downloadFilePathOfString:fileName];
        if ([fileManager fileExistsAtPath:downloadFilePath]) {
            [fileManager removeItemAtPath:downloadFilePath error:nil];
        }
    });
}
- (void)deleteFileOfURL:(NSURL *)url {
    if (!url) return;
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [downloadManager.downloadModelInfo removeObjectForKey:fileName];
    if ([downloadManager.waitingModels containsObject:downloadModel]) {
        [downloadManager.waitingModels removeObject:downloadModel];
    }
    if ([downloadManager.downloadingModels containsObject:downloadModel]) {
        [downloadManager.downloadingModels removeObject:downloadModel];
    }
    [downloadManager deleteFile:[downloadManager fileNameOfURL:url]];
    [downloadManager cancelDownloadOfURL:url];
}
- (void)deleteAllFiles {
    [downloadManager cancelAllDownloads];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    dispatch_async(downloadManager.downloadQueue, ^{
        NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:[downloadManager downloadFileDir] error:nil];
        for (NSString *fileName in fileNames) {
            NSString *filePath = [downloadManager downloadFilePathOfString:fileName];;
            [fileManager removeItemAtPath:filePath error:nil];
        }
    });
    [downloadManager.downloadModelInfo removeAllObjects];
    [downloadManager.waitingModels removeAllObjects];
    [downloadManager.downloadingModels removeAllObjects];
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[downloadTask.taskDescription];
    if (!downloadModel) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.progressBlock) {
            if (totalBytesExpectedToWrite == 0) return;
            CGFloat progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
            downloadModel.progressBlock(totalBytesWritten, totalBytesExpectedToWrite, progress);
        }
    });
    if (downloadModel.totalLength > 0) return;
    dispatch_async(downloadManager.downloadQueue, ^{
        downloadModel.totalLength = totalBytesExpectedToWrite;
        NSURL *url = downloadModel.url;
        NSString *fileName = [downloadManager fileNameOfURL:url];
        NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:[downloadManager downloadFileLengthPath]] ?: [NSMutableDictionary dictionary];
        filesTotalLength[fileName] = @(totalBytesExpectedToWrite);
        [filesTotalLength writeToFile:[downloadManager downloadFileLengthPath] atomically:YES];
    });
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[downloadTask.taskDescription];
    if (!downloadModel) return;
    NSString *filePath = [downloadManager downloadFilePathOfURL:downloadModel.url];
    [[NSFileManager defaultManager]moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error && error.code == -999) {
        return;
    }
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[task.taskDescription];
    if (!downloadModel) return;
    NSURL *url = downloadModel.url;
    NSString *fullPath = [downloadManager downloadFilePathOfURL:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([downloadManager doneDownloadOfURL:url]) {
            downloadModel.state = SLDownloadStateCompleted;
            [downloadManager.downloadModelInfo removeObjectForKey:task.taskDescription];
            [downloadManager.downloadingModels removeObject:downloadModel];
            if (downloadModel.stateBlock) downloadModel.stateBlock(SLDownloadStateCompleted);
            if (downloadModel.completionBlock) downloadModel.completionBlock(YES, fullPath, nil);
        } else {
            downloadModel.state = SLDownloadStateFailed;
            if (downloadModel.stateBlock) downloadModel.stateBlock(SLDownloadStateFailed);
            if (downloadModel.completionBlock) downloadModel.completionBlock(NO, fullPath, error);
        }
        [downloadManager downloadNext];
    });
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSString *identifier = session.configuration.identifier;
    if ([SLNetworkTool sl_networkEmptyString:identifier]) return;
    void(^handle)(void) = [[[SLDownloadManager sharedManager] sessionCompleteHandle] objectForKey:identifier];
    if (handle) {
        [[SLDownloadManager sharedManager].sessionCompleteHandle removeObjectForKey:identifier];
        handle();
    }
}
@end
