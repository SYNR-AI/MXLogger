//
//  flutter-bridge.m
//  Logger
//
//  Created by 董家祎 on 2022/3/11.
//
//

#include <MXLogger/MXLogger.h>


#define MXLOGGER_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#define MXLOGGERR_FUNC(func) flutter_mxlogger_ ## func


MXLOGGER_EXPORT int64_t MXLOGGERR_FUNC(initialize)(const char* ns,const char* directory,const char* storage_policy,const char* file_name, const char* file_header,const char* crypt_key, const char* iv){
  
    
    NSString * _ns = [NSString stringWithUTF8String:ns];
    NSString * _directory = [NSString stringWithUTF8String:directory];
    NSString * _storagePolicy = storage_policy == nullptr ? NULL : [NSString stringWithUTF8String:storage_policy];
    NSString * _fileName = file_name == nullptr ? NULL : [NSString stringWithUTF8String:file_name];
    NSString * _fileHeader = file_header == nullptr ? NULL : [NSString stringWithUTF8String:file_header];
    NSString * _cryptKey = crypt_key == nullptr ? NULL : [NSString stringWithUTF8String:crypt_key];
    NSString * _iv = iv == nullptr ? NULL : [NSString stringWithUTF8String:iv];
    
    MXStoragePolicyType policyType = MXStoragePolicyYYYYMMDD;
    
    if([_storagePolicy isEqualToString:@"yyyy_MM_dd"]){
        policyType = MXStoragePolicyYYYYMMDD;
    }else if ([_storagePolicy isEqualToString:@"yyyy_MM_dd_HH"]){
        policyType = MXStoragePolicyYYYYMMDDHH;
    }else if ([_storagePolicy isEqualToString:@"yyyy_ww"]){
        policyType = MXStoragePolicyYYYYWW;
    }else if ([_storagePolicy isEqualToString:@"yyyy_MM"]){
        policyType = MXStoragePolicyYYYYMM;
    }
    
    MXLogger * logger = [MXLogger initializeWithNamespace:_ns diskCacheDirectory:_directory storagePolicy:policyType fileName:_fileName fileHeader:_fileHeader  cryptKey:_cryptKey iv:_iv];
        
  
    logger.shouldRemoveExpiredDataWhenEnterBackground = NO;
    
    return (int64_t)logger;
}
MXLOGGER_EXPORT void MXLOGGERR_FUNC(destroy)(const char* ns,const char* directory){
    [MXLogger destroyWithNamespace:[NSString stringWithUTF8String:ns] diskCacheDirectory:directory == nullptr ? NULL : [NSString stringWithUTF8String:directory]];
}


MXLOGGER_EXPORT void MXLOGGERR_FUNC(destroyWithLoggerKey)(const char* logger_key){
    if(logger_key == nullptr)return;
    
    [MXLogger destroyWithLoggerKey:[NSString stringWithUTF8String:logger_key]];
}




MXLOGGER_EXPORT void MXLOGGERR_FUNC(set_console_enable)(const void *handle,int enable){
    MXLogger *logger = (__bridge MXLogger *) handle;
    logger.consoleEnable = enable;
}

MXLOGGER_EXPORT void MXLOGGERR_FUNC(set_enable)(const void *handle,int enable){
    MXLogger *logger = (__bridge MXLogger *) handle;
    logger.enable = enable == 1 ? YES : NO;
}




MXLOGGER_EXPORT int MXLOGGERR_FUNC(select_logmsg)(const char * diskcache_file_path, const char* crypt_key, const char* iv,int* number, char ***array_ptr,uint32_t **size_array_ptr){
    if(diskcache_file_path == nullptr){
        return -1;
    }
    
    
    NSArray<NSDictionary*> * resultArray =   [MXLogger selectWithDiskCacheFilePath:[NSString stringWithUTF8String:diskcache_file_path] cryptKey:crypt_key == nullptr ? NULL : [NSString stringWithUTF8String:crypt_key] iv:iv == nullptr ? NULL : [NSString stringWithUTF8String:iv]];
    
    int count = (int)resultArray.count;
    
    *number = count;
    
    if(count > 0){
        auto array = (char**)malloc(count * sizeof(void *));
        auto size_array = (uint32_t *) malloc(count * sizeof(uint32_t *));
        if(!array){
            free(array);
            free(size_array);
            return -1;
        }
        *array_ptr = array;
        *size_array_ptr = size_array;
        for(int i = 0;i<count;i++){
            NSDictionary * logdictionary = resultArray[i];
            
            NSData *logData = [NSJSONSerialization dataWithJSONObject:logdictionary
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:NULL];
            NSUInteger length = logData.length;
            size_array[i] = static_cast<uint32_t>(length);
    
            array[i] = (char*)logData.bytes;
        }
    }
    
    return 0;
    
}
/// 获取日志文件列表
MXLOGGER_EXPORT int MXLOGGERR_FUNC(get_logfiles)(const void *handle,char ****array_ptr,uint32_t ***size_array_ptr){
    MXLogger *logger = (__bridge MXLogger *) handle;
    NSArray<NSDictionary<NSString*,NSString*>*>* fileArray =  [logger logFiles];
    if(fileArray.count == 0) return 0;
    auto array = (char***)malloc(fileArray.count * sizeof(void *));
    
    auto size_array = (uint32_t **) malloc(fileArray.count * sizeof(uint32_t *));
            if(!array){
                free(array);
                free(size_array);
                return 0;
            }
    *array_ptr = array;
    *size_array_ptr = size_array;
    
    
    for(int i=0; i< fileArray.count;i++){
        NSDictionary<NSString*,NSString*>* map = fileArray[i];
        
        NSString * name = [map valueForKey:@"name"];
        
        NSString * size = [map valueForKey:@"size"];
        
        NSString * last_timestamp = [map valueForKey:@"last_timestamp"];
        
        NSString * create_timestamp  =  [map valueForKey:@"create_timestamp"];
        

         char* c_name =  (char*)name.UTF8String;
         char* c_size = (char*)size.UTF8String;
         char* c_last_timestamp = (char*)last_timestamp.UTF8String;
         char* c_create_timestamp = (char*)create_timestamp.UTF8String;
        
        auto itemArray = (char**)malloc(4*sizeof(char*));
        
        itemArray[0] = (char*)malloc(strlen(c_name));
        memcpy(itemArray[0], c_name, strlen(c_name));


        itemArray[1] = (char*)malloc(strlen(c_size));
        memcpy(itemArray[1], c_size, strlen(c_size));

        itemArray[2] = (char*)malloc(strlen(c_last_timestamp));
        memcpy(itemArray[2], c_last_timestamp, strlen(c_last_timestamp));

        itemArray[3] = (char*)malloc(strlen(c_create_timestamp));
        memcpy(itemArray[3], c_create_timestamp, strlen(c_create_timestamp));

   
        
        auto item_size_array = (uint32_t *) malloc(4 * sizeof(uint32_t *));
               
        item_size_array[0] = static_cast<uint32_t>(strlen(c_name));
        item_size_array[1] = static_cast<uint32_t>(strlen(c_size));
        item_size_array[2] = static_cast<uint32_t>(strlen(c_last_timestamp));
        item_size_array[3] = static_cast<uint32_t>(strlen(c_create_timestamp));
        
        size_array[i] = item_size_array;
        array[i] = itemArray;
    }
    return (int)fileArray.count;
}

MXLOGGER_EXPORT uint32_t MXLOGGERR_FUNC(select_logfiles)(const char * directory, char ***array_ptr,uint32_t **size_array_ptr){
    if(directory == nullptr) return 0;
    
    
//    NSArray<NSDictionary<NSString*,NSString*>*>* list =  [MXLogger selectLogfilesWithDirectory:[NSString stringWithUTF8String:directory]];
//    if(list.count > 0){
//        auto array = (char**)malloc(list.count * sizeof(void *));
//        auto size_array = (uint32_t *) malloc(list.count * sizeof(uint32_t *));
//        if(!array){
//            free(array);
//            free(size_array);
//            return 0;
//        }
//        *array_ptr = array;
//        *size_array_ptr = size_array;
//
//        for(int i =0;i < list.count;i++){
//            NSDictionary<NSString*,NSString*>* map = list[i];
//            NSString * info = [NSString  stringWithFormat:@"%@,%@,%@",map[@"name"],map[@"size"],map[@"timestamp"]];
//            auto infoData = [info dataUsingEncoding:NSUTF8StringEncoding];
//            size_array[i] = static_cast<uint32_t>(infoData.length);
//            array[i] = (char*)infoData.bytes;
//        }
//        return static_cast<uint32_t>(list.count);
//    }
    
    return 0;
    
}


MXLOGGER_EXPORT void MXLOGGERR_FUNC(set_level)(const void *handle,int level){
    MXLogger *logger = (__bridge MXLogger *) handle;
    logger.level = [NSNumber numberWithInt:level].integerValue;
}

MXLOGGER_EXPORT void MXLOGGERR_FUNC(set_max_disk_age)(const void *handle,int max_age){
    MXLogger *logger = (__bridge MXLogger *) handle;
    logger.maxDiskAge = max_age;

}
MXLOGGER_EXPORT void MXLOGGERR_FUNC(set_max_disk_size)(const void *handle,uint max_size){
    MXLogger *logger = (__bridge MXLogger *) handle;
    logger.maxDiskSize = max_size;
}
MXLOGGER_EXPORT unsigned long MXLOGGERR_FUNC(get_log_size)(const void *handle){
    MXLogger *logger = (__bridge MXLogger *) handle;
    return logger.logSize;
}

MXLOGGER_EXPORT const char* MXLOGGERR_FUNC(get_loggerKey)(const void *handle){
    MXLogger *logger = (__bridge MXLogger *) handle;
    return logger.loggerKey.UTF8String;
}


MXLOGGER_EXPORT const char* MXLOGGERR_FUNC(get_diskcache_path)(const void *handle){
    MXLogger *logger = (__bridge MXLogger *) handle;
    return logger.diskCachePath.UTF8String;
}
MXLOGGER_EXPORT const char* MXLOGGERR_FUNC(get_error_desc)(const void *handle){
    MXLogger *logger = (__bridge MXLogger *) handle;
    return [logger errorDesc].UTF8String;
}


MXLOGGER_EXPORT void MXLOGGERR_FUNC(remove_before_all_data)(const void *handle){
    MXLogger *logger = (__bridge MXLogger *) handle;
    [logger removeBeforeAllData];
}

MXLOGGER_EXPORT void MXLOGGERR_FUNC(remove_expire_data)(const void *handle){
    MXLogger *logger = (__bridge MXLogger *) handle;
    [logger removeExpireData];
}
MXLOGGER_EXPORT void MXLOGGERR_FUNC(remove_all)(const void *handle){
    MXLogger *logger = (__bridge MXLogger *) handle;
    [logger removeAllData];
}
 
MXLOGGER_EXPORT int MXLOGGERR_FUNC(log_loggerKey)(const char* logger_key,const char* name, int lvl,const char* msg,const char* tag){
    if(logger_key == nullptr) return 0;
    
    MXLogger *logger = [MXLogger valueForLoggerKey:[NSString stringWithUTF8String:logger_key]];
    
    NSString * _name = name == nullptr ? NULL : [NSString stringWithUTF8String:name];
    NSString * _msg = msg == nullptr ? NULL : [NSString stringWithUTF8String:msg];
    NSString * _tag = tag == nullptr ? NULL : [NSString stringWithUTF8String:tag];
    
    return  [logger logWithLevel:lvl name:_name msg: _msg tag:_tag];
    
}


MXLOGGER_EXPORT int MXLOGGERR_FUNC(log)(const void *handle,const char* name, int lvl,const char* msg,const char* tag){
    MXLogger *logger = (__bridge MXLogger *) handle;
   
    NSString * _name = name == nullptr ? NULL : [NSString stringWithUTF8String:name];
    NSString * _msg = msg == nullptr ? NULL : [NSString stringWithUTF8String:msg];
    NSString * _tag = tag == nullptr ? NULL : [NSString stringWithUTF8String:tag];
    
    return  [logger logWithLevel:lvl name:_name msg: _msg tag:_tag];


}




@interface MXLoggerDummy : NSObject
@end

@implementation MXLoggerDummy
@end

