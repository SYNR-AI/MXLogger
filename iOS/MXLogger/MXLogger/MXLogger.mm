//
//  MXLogger.m
//  Logger
//
//  Created by 董家祎 on 2022/3/1.
//

#import "MXLogger.h"
#include <MXLoggerCore/mxlogger.hpp>

static NSString * _defaultDiskCacheDirectory;

@interface MXLogger()
{
    mx_logger *_logger;
}
@property (nonatomic, copy, nonnull, readwrite) NSString *diskCachePath;
@end

@implementation MXLogger

-(instancetype)initWithNamespace:(nonnull NSString*)nameSpace diskCacheDirectory:(nullable NSString*) directory{
    if (self = [super init]) {
        if (!directory) {
            directory = [MXLogger defaultDiskCacheDirectory];
        }
        _logger =  mx_logger::initialize_namespace(nameSpace.UTF8String, directory.UTF8String);
    }
    return self;
}


- (void)setStoragePolicy:(NSString *)storagePolicy{
    _storagePolicy = storagePolicy;
    _logger -> set_file_policy(storagePolicy.UTF8String);
}
- (void)setFileHeader:(NSString *)fileHeader{
    _fileHeader = fileHeader;
 
    _logger -> set_file_header(fileHeader.UTF8String);
}

- (void)setFileName:(NSString *)fileName{
    _fileName = fileName;
    _logger -> set_file_name(fileName.UTF8String);
}
-(void)setEnable:(BOOL)enable{
    _enable = enable;
    _logger -> set_enable(enable);
}
-(void)setConsoleEnable:(BOOL)consoleEnable{
    _consoleEnable = consoleEnable;
    _logger -> set_console_enable(consoleEnable);
}
-(void)setFileEnable:(BOOL)fileEnable{
    _fileEnable = fileEnable;
    _logger -> set_file_enable(fileEnable);
}

-(void)info:(NSString*)name msg:(NSString*)msg tag:(NSString*)tag{
    [self log:1 name:name msg:msg tag:tag];
}
-(void)log:(NSInteger)level name:(NSString*)name msg:(NSString*)msg tag:(NSString*)tag {
    [self innerLogWithType:0 level:level name:name msg:msg tag:tag];
}

-(void)innerLogWithType:(NSInteger) type level:(NSInteger)level name:(NSString*)name msg:(NSString*)msg tag:(NSString*)tag {
    BOOL isMainThread = [NSThread isMainThread];
    
    _logger -> log([NSNumber numberWithInteger:type].intValue, [NSNumber numberWithInteger:level].intValue, name.UTF8String, msg.UTF8String, tag.UTF8String, isMainThread);
}


- (NSString *)diskCachePath{
    return [NSString stringWithUTF8String:_logger->diskcache_path()];
}


// 默认缓存目录 library
+ (nullable NSString *)userCacheDirectory {
    
    NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return libraryPath;
}

+(NSString*)defaultDiskCacheDirectory{
    if(!_defaultDiskCacheDirectory){
        _defaultDiskCacheDirectory = [[self userCacheDirectory] stringByAppendingPathComponent:@"com.mxlog.LoggerCache"];
    }
    return _defaultDiskCacheDirectory;
}

@end
