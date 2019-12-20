//
//  SLNetworkCache.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/18.
//

#import "SLNetworkCache.h"
#import <SLNetwork/SLNetworkConfig.h>
#import <SLNetwork/SLNetworkTool.h>

static int cacheTimeInterval = 60*60*24;
@interface SLNetworkCache ()<NSCoding>
@property (strong, nonatomic) id data;
@property (nonatomic) NSTimeInterval cacheTime;
@property (nonatomic) NSUInteger validTimeInterval;
@end

@implementation SLNetworkCache
+ (instancetype)cacheWithData:(id)data {
    return [self cacheWithData:data validTimeInterval:cacheTimeInterval];
}

+ (instancetype)cacheWithData:(id)data validTimeInterval:(NSUInteger)interterval {
    SLNetworkCache *cache = [SLNetworkCache new];
    cache.data = data;
    cache.cacheTime = [[NSDate date] timeIntervalSince1970];
    cache.validTimeInterval = interterval > 0 ? interterval : cacheTimeInterval;
    return cache;
}

- (BOOL)isValid {
    if (self.data) {
        return [[NSDate date] timeIntervalSince1970] - self.cacheTime < self.validTimeInterval;
    }
    return NO;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        if (aDecoder) {
            _validTimeInterval = [aDecoder decodeIntegerForKey:@"validTimeInterval"];
            _cacheTime = [aDecoder decodeDoubleForKey:@"cacheTime"];
            _data = [aDecoder decodeObjectForKey:@"data"];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_data forKey:@"data"];
    [aCoder encodeDouble:_cacheTime forKey:@"cacheTime"];
    [aCoder encodeInteger:_validTimeInterval forKey:@"validTimeInterval"];
}
@end

@interface SLNetworkCacheManager ()
@property (copy, nonatomic) NSString *cachePath;
@property (strong, nonatomic) dispatch_queue_t networkQueue;
@property (strong, nonatomic) NSCache *cache;
@property (strong, nonatomic) NSMutableSet *protectCacheKeys;// 保证不易删除的缓存key集合
@property (assign, nonatomic) long long maxDiskSize;
@end

@implementation SLNetworkCacheManager
static SLNetworkCacheManager *sharedManager;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[super allocWithZone:NULL] init];
        sharedManager.cache = [NSCache new];
        sharedManager.cache.totalCostLimit = 1024 * 1024 * 5;
        sharedManager.maxDiskSize = [SLNetworkConfig share].diskCacheSize > 0 ? [SLNetworkConfig share].diskCacheSize : 1024 * 1024 * 20;
        sharedManager.protectCacheKeys = [NSMutableSet set];
        sharedManager.networkQueue = dispatch_queue_create("com.sl.network", DISPATCH_QUEUE_CONCURRENT);
        
        NSFileManager *filemanager = [NSFileManager defaultManager];
        NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        sharedManager.cachePath = [path stringByAppendingPathComponent:@"slnetwork"];
        BOOL isDir;
        if (![filemanager fileExistsAtPath:sharedManager.cachePath isDirectory:&isDir]){
            [sharedManager creatCacheFile];
        }else{
            if (!isDir) {
                NSError *error = nil;
                [filemanager removeItemAtPath:sharedManager.cachePath error:&error];
                [sharedManager creatCacheFile];
            }
        }
        [[NSNotificationCenter defaultCenter] addObserver:sharedManager selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedManager selector:@selector(backgroundCleanDisk) name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
    return sharedManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedManager];
}

- (void)creatCacheFile{
    NSError *error = nil;
    BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:sharedManager.cachePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (created) {
        NSURL *url = [NSURL fileURLWithPath:sharedManager.cachePath];
        [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];//避免缓存数据 被备份到iclouds
    }
}

-(void)addProtectCacheKey:(NSString*)key {
    if([SLNetworkTool sl_networkEmptyString:key]) return;
    dispatch_sync(sharedManager.networkQueue, ^{
        [sharedManager.protectCacheKeys addObject:key];
    });
}

- (void)setObjcet:(SLNetworkCache *)object forKey:(NSString *)key {
    if (!object) return;
    if([SLNetworkTool sl_networkEmptyString:key]) return;
    dispatch_sync(sharedManager.networkQueue, ^{
        [sharedManager.cache setObject:object forKey:key];
        dispatch_async(sharedManager.networkQueue, ^{
            NSString *filePath = [sharedManager.cachePath stringByAppendingPathComponent:key];
            [NSKeyedArchiver archiveRootObject:object toFile:filePath];
        });
    });
}

- (void)removeCacheForKey:(NSString *)key {
    if([SLNetworkTool sl_networkEmptyString:key]) return;
    dispatch_sync(sharedManager.networkQueue, ^{
        [sharedManager.cache removeObjectForKey:key];
        dispatch_async(sharedManager.networkQueue, ^{
            NSString *filePath = [sharedManager.cachePath stringByAppendingPathComponent:key];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:filePath] error:nil];
            }
        });
    });
}

- (SLNetworkCache *)cacheForKey:(NSString *)key {
    if([SLNetworkTool sl_networkEmptyString:key]) return nil;
    __block SLNetworkCache *cache;
    dispatch_sync(sharedManager.networkQueue, ^{
        cache = [sharedManager.cache objectForKey:key];
        if (!cache) {
            NSString *filePath = [sharedManager.cachePath stringByAppendingPathComponent:key];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSError *attributesRetrievalError = nil;
                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                                                            error:&attributesRetrievalError];
                if (!attributes) {
                    cache = nil;
                } else {
                    cache = (SLNetworkCache *)[NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
                    NSTimeInterval seconds = -[[attributes fileModificationDate] timeIntervalSinceNow];
                    if (seconds > cache.cacheTime) {
                        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:filePath] error:nil];
                        cache = nil;
                    } else {
                        [sharedManager.cache setObject:cache forKey:key];
                    }
                }
            }
        }
    });
    return cache;
}

-(void)removeAllObjects{
    [sharedManager.cache removeAllObjects];
}

- (void)backgroundCleanDisk{
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    [sharedManager cleanDiskWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)cleanDiskWithCompletionBlock:(void (^)(void))completionBlock {
    dispatch_async(sharedManager.networkQueue, ^{
        NSURL *diskCacheURL = [NSURL fileURLWithPath:sharedManager.cachePath isDirectory:YES];
        NSArray *resourceKeys = @[NSURLLocalizedNameKey,NSURLNameKey,NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtURL:diskCacheURL
                                                  includingPropertiesForKeys:resourceKeys
                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                errorHandler:NULL];
        
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-cacheTimeInterval];
        NSMutableDictionary *cacheFiles = [NSMutableDictionary dictionary];
        NSUInteger currentCacheSize = 0;
        
        // 遍历缓存文件夹中的所有文件，有2 个目的
        //  1. 删除过期的文件
        //  2. 删除比较的旧的文件 使得当前文件的大小 小于最大文件的大小
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
            // 跳过文件夹
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) continue;
            
            // 跳过指定不能删除的文件 比如首页列表数据
            if ([sharedManager.protectCacheKeys containsObject:fileURL.lastPathComponent])  continue;
            
            // 删除过期文件
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
            
            // Store a reference to this file and account for its total size.
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += [totalAllocatedSize unsignedIntegerValue];
            [cacheFiles setObject:resourceValues forKey:fileURL];
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [fileManager removeItemAtURL:fileURL error:nil];
        }
        
        // 如果删除过期的文件后，缓存的总大小还大于maxsize 的话则删除比较快老的缓存文件
        if (sharedManager.maxDiskSize > 0 && currentCacheSize > sharedManager.maxDiskSize) {
            // 这个过程主要清除到最大缓存的一半大小
            const long long desiredCacheSize = sharedManager.maxDiskSize / 2;
            
            // 按照最后的修改时间来排序，旧的文件排在前面
            NSArray *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                            usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                            }];
            //删除文件到一半的大小
            for (NSURL *fileURL in sortedFiles) {
                if ([fileManager removeItemAtURL:fileURL error:nil]) {
                    NSDictionary *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= [totalAllocatedSize unsignedIntegerValue];
                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:sharedManager name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:sharedManager name:UIApplicationDidEnterBackgroundNotification object:nil];
}
@end
