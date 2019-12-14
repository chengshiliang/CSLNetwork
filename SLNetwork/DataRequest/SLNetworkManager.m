//
//  SLNetworkManager.m
//  AFNetworking
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLNetworkManager.h"


@interface SLNetworkManager()
@property (nonatomic, assign) dispatch_semaphore_t semaphore;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURLSessionTask *> *requestInfo;
@property (nonatomic, assign) NSInteger totalTaskCount;
@property (nonatomic, assign) NSInteger errorTaskCount;
@end

@implementation SLNetworkManager
static SLNetworkManager *sharedInstance;
+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        sharedInstance.semaphore = dispatch_semaphore_create(1);
    });
    return sharedInstance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self share];
}
- (instancetype)init {
    if (self = [super init]) {
        self.requestInfo = [NSMutableDictionary dictionary];
        self.sessionManager = [AFHTTPSessionManager manager];
        self.sessionManager.securityPolicy.validatesDomainName = NO;
        self.sessionManager.securityPolicy.allowInvalidCertificates = YES;
        self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:self.sessionManager.responseSerializer.acceptableContentTypes];
        [acceptableContentTypes addObject:@"text/html"];
        [acceptableContentTypes addObject:@"text/plain"];
        self.sessionManager.responseSerializer.acceptableContentTypes = [acceptableContentTypes copy];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivedSwitchSeriveNotification:) name:@"didReceivedSwitchSeriveNotification" object:nil];
    }
    return self;
}

- (void)requestWithModel:(id<SLRequestDataProtocol>)model {
    
}
@end
