//
//  mxlog.cpp
//  MXLoggerCore
//
//  Created by 董家祎 on 2022/4/13.
//

#include "mxlogger.hpp"

#include <mutex>
#include <unordered_map>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>

#include "sink/mmap_sink.hpp"
#include "mxlogger_helper.hpp"
#include "log_msg.hpp"
#include "debug_log.hpp"
#include "mxlogger_console.hpp"

namespace mxlogger{

std::unordered_map<std::string, mxlogger *> *global_instanceDic_ =  new std::unordered_map<std::string, mxlogger *>;


 std::string mxlogger::md5(const char* ns,const char* directory){
     
     std::string diskcache_path = get_diskcache_path_(ns,directory);
     std::string logger_key =  mxlogger_helper::mx_md5(diskcache_path);

     return logger_key;
}



std::string mxlogger::get_diskcache_path_(const char* ns,const char* directory){
    if (directory == nullptr) {
        return "";
    }
    if (ns == nullptr) {
        ns = "default";
    }
    std::string  directory_s = std::string{directory};
    
    std::string ns_s = std::string{ns};
    
    std::string diskcache_path = directory_s + "/" + ns_s + "/";
    return diskcache_path;
}

mxlogger *mxlogger::global_for_loggerKey(const char* logger_key){

    if(logger_key == nullptr) return nullptr;

    auto itr = global_instanceDic_ -> find(logger_key);
    if (itr != global_instanceDic_ -> end()) {
        mxlogger * logger = itr -> second;
        return logger;
    }
    return nullptr;
}

mxlogger *mxlogger::initialize_namespace(const char* ns,
                                         const char* directory,
                                         const char* storage_policy,
                                         const char* file_name,
                                         const char* file_header,
                                         const char* cryptKey,
                                         const char* iv){

    std::string diskcache_path = get_diskcache_path_(ns,directory);
    if (diskcache_path.data() == nullptr) {
        return nullptr;
    }
    
    std::string logger_key =  mxlogger_helper::mx_md5(diskcache_path);
    
    auto itr = global_instanceDic_ -> find(logger_key);
    if (itr != global_instanceDic_ -> end()) {
        mxlogger * logger = itr -> second;
        return logger;
    }
    
    auto logger = new mxlogger(diskcache_path.c_str(),storage_policy,file_name,file_header,cryptKey,iv);
    logger -> logger_key_ = logger_key;
    (*global_instanceDic_)[logger_key] = logger;
    MXLoggerInfo("mxlogger Initialization succeeded.  storage_policy:%s file_name:%s is_crypt:%s",storage_policy,file_name == nullptr ? "mxlog" : file_name,cryptKey!=nullptr ? "true" : "false");
    
    return logger;
}

void mxlogger::delete_namespace(const char* logger_key){
    delete_namespace_(logger_key);
}

void mxlogger::delete_namespace(const char* ns,const char* directory){
 
    std::string diskcache_path = get_diskcache_path_(ns,directory);
   
    if (strcmp(diskcache_path.c_str(), "") == 0) {
        return;
    }
    std::string logger_key =  mxlogger_helper::mx_md5(diskcache_path);
    delete_namespace_(logger_key.c_str());
}

//释放指定的logger对象
void mxlogger::delete_namespace_(const char* logger_key){
    auto itr = global_instanceDic_ -> find(logger_key);
    if (itr != global_instanceDic_ -> end()) {
        mxlogger * logger = itr -> second;
        delete logger;
        global_instanceDic_->erase(itr);
    }
}
void mxlogger::destroy(){
    
    for (auto &pair : *global_instanceDic_) {
        mxlogger *logger = pair.second;
        delete logger;
        pair.second = nullptr;
    }
    global_instanceDic_->clear();
    
}



mxlogger::mxlogger(const char *diskcache_path,const char* storage_policy,const char* file_name, const char* file_header,const char* cryptKey, const char* iv) : diskcache_path_(diskcache_path){
    std::string filename_ = file_name == nullptr ? "log" : file_name;
    
    mmap_sink_ = std::make_shared<sinks::mmap_sink>(diskcache_path,filename_, mxlogger_helper::policy_(storage_policy));
   

    
    mmap_sink_ -> init_aescfb(cryptKey, iv);
    
    mmap_sink_ -> add_file_heder(file_header);
    
    enable_ = true;
    enable_console_ = false;
  
   
    
}

    

mxlogger::~mxlogger(){
    MXLoggerInfo("mxlogger delloc logger_key:%s",logger_key_.c_str());
}

const char* mxlogger::diskcache_path() const{
    return diskcache_path_.c_str();
}

const char*  mxlogger::logger_key() const{
    return logger_key_.c_str();
}
void mxlogger::set_enable(bool enable){
    
    enable_ = enable;
}
void mxlogger::set_enable_console(bool enable){
    enable_console_ = enable;
}


// 设置日志文件最大字节数(byte)
void mxlogger::set_file_max_size(const  long max_size){
    mmap_sink_ -> set_max_disk_size(max_size);
   
    
}

// 设置日志文件最大存储时长(s)
void mxlogger::set_file_max_age(const  long max_age){
    mmap_sink_ -> set_max_disk_age(max_age);
  
}

// 清理过期文件
void mxlogger::remove_expire_data(){
    std::lock_guard<std::mutex> lock(logger_mutex);
    mmap_sink_ -> remove_expire_data();
   
}

//删除所有日志文件
void mxlogger::remove_all(){
    std::lock_guard<std::mutex> lock(logger_mutex);
    mmap_sink_ -> remove_all();
}
// 删除除当前写入文件之外的所有日志文件
void mxlogger::remove_before_all(){
    std::lock_guard<std::mutex> lock(logger_mutex);
    mmap_sink_ -> remove_before_all();
}

// 缓存日志文件大小(byte)
long  mxlogger::dir_size(){
   
    return mmap_sink_->dir_size();
}


void mxlogger::set_log_level(int level){
    mmap_sink_ -> set_level(mxlogger_helper::level_(level));
}

void mxlogger::flush(){
    std::lock_guard<std::mutex> lock(logger_mutex);
    mmap_sink_ -> flush();
}


void mxlogger::log(int level,const char* name, const char* msg,const char* tag,bool is_main_thread){
    if (enable_ == false) {
        return;
    }
    
    std::lock_guard<std::mutex> lock(logger_mutex);
    
    if (name == nullptr || strcmp(name, "") == 0) {
        name = "mxlogger";
    }
   
    level::level_enum lvl = mxlogger_helper::level_(level);

    details::log_msg log_msg(lvl,name,tag,msg,is_main_thread);
    
    
    mmap_sink_ -> log(log_msg);
   
    if (enable_console_ == true) {
        
        mxlogger_console::print(log_msg);

    }
    
   
}

}
