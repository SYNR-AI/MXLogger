library flutter_mxlogger;

import 'dart:ffi';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
export 'flutter_mxlogger.dart';
import 'package:archive/archive.dart';

typedef LoggerFunction = Void Function(
    Pointer<Int8>, Pointer<Int8>, Pointer<Int8>);

typedef FlutterLogFunction = void Function(
    Pointer<Int8>, Pointer<Int8>, Pointer<Int8>);

class MXLoggerObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //
    // if(state == AppLifecycleState.paused && MXLogger._shouldRemoveExpiredDataWhenEnterBackground == true){
    //   MXLogger.removeExpireData();
    // }
  }
}

class MXLogger {
  Pointer<Void> _handle = nullptr;

  static const MethodChannel _channel = MethodChannel('flutter_mxlogger');

  late MXLoggerObserver _observer;

  bool _enable = false;

  bool _shouldRemoveExpiredDataWhenEnterBackground = true;
  bool? _isTracking;

  bool _isEnable() {
    return _enable == true;
  }

  static Future<MXLogger> initialize(
      {bool enable = false,
      required String nameSpace,
      String? directory}) async {
    MXLogger mxLogger = MXLogger();

    mxLogger._enable = enable;

    mxLogger._observer = MXLoggerObserver();

    WidgetsBinding.instance!.addObserver(mxLogger._observer);

    Map<dynamic, dynamic> result = await _channel.invokeMethod(
        "initialize", {"nameSpace": nameSpace, "directory": directory});
    String ns = result["nameSpace"];
    String dr = result["directory"];

    Pointer<Utf8> nsPtr = ns.toNativeUtf8();
    Pointer<Utf8> drPtr = dr.toNativeUtf8();
    mxLogger._handle = _initialize(nsPtr, drPtr);
    calloc.free(nsPtr);
    calloc.free(drPtr);
    return mxLogger;
  }

  /// 程序进入后台的时候是否去清理过期文件 默认为YES
  void shouldRemoveExpiredDataWhenEnterBackground(bool should) {
    _shouldRemoveExpiredDataWhenEnterBackground = should;
  }

  Future<String?> compressLogFile() async {
    if (_isEnable() == false) return null;
    String? diskPath = getdDiskcachePath();
    if (diskPath == null) return null;
    Directory directory = Directory(diskPath);

    ZipFileEncoder encoder = ZipFileEncoder();
    List<String> directorList = directory.path.split("/");
    directorList.removeAt(directorList.length - 1);
    String zipPath = directorList.join("/");
    encoder.zipDirectory(directory, filename: zipPath + ".zip");

    return encoder.zipPath;
  }

  Future<bool> removeZip(String zipPath) async {
    if (_isEnable() == false) return false;
    String? diskPath = getdDiskcachePath();
    if (diskPath == null) return false;

    Directory directory = Directory(zipPath);
    await directory.delete();
    return true;
  }

  /// 设置写入日志文件等级
  ///    0:debug
  ///     1:info
  ///     2:warn
  ///     3:error
  ///     4:fatal
  void setFileLevel(int lvl) {
    if (_isEnable() == false) return;
    _setFileLevel(lvl);
  }

  void setConsoleLevel(int lvl) {
    if (_isEnable() == false) return;
    _setConsoleLevel(lvl);
  }

  /// 设置文件名
  void setFileName(String fileName) {
    if (_isEnable() == false) return;
    Pointer<Utf8> fileNamePtr = fileName.toNativeUtf8();
    _setFileName(fileNamePtr);
    calloc.free(fileNamePtr);
  }

  /// 设置是否禁用日志写入功能
  void setFileEnable(bool enable) {
    if (_isEnable() == false) return;
    _setFileEnable(enable == true ? 1 : 0);
  }

  /// 设置是否禁用控制台输出功能
  void setConsoleEnable(bool enable) {
    if (_isEnable() == false) return;
    _setConsoleEnable(enable == true ? 1 : 0);
  }

  /// 设置文件头
  void setFileHeader(String header) {
    if (_isEnable() == false) return;
    Pointer<Utf8> headerPtr = header.toNativeUtf8();
    _setFileHeader(headerPtr);
    calloc.free(headerPtr);
  }

  /// 设置日志文件存储最大时长(s) 默认为0 不限制   60 * 60 *24 *7 即一个星期
  void setMaxdiskAge(int age) {
    if (_isEnable() == false) return;
    _setMaxdiskAge(age);
  }

  /// 设置日志文件存储最大字节数(byte) 默认为0 不限制 1024 * 1024 * 10; 即10M
  void setMaxdiskSize(int size) {
    if (_isEnable() == false) return;
    _setMaxdiskSize(size);
  }

  /// 删除过期文件
  void removeExpireData() {
    if (_isEnable() == false) return;
    _removeExpireData();
  }

  /// 删除所有日志文件
  void removeAll() {
    if (_isEnable() == false) return;
    _removeAll();
  }

  void setEnable(bool enable) {
    _enable = enable;
  }

  ///
  /// 日志文件存储策略
  /// yyyy_MM_dd 每天存储一个日志文件
  /// yyyy_ww    每周存储一个日志文件
  /// yyyy_MM  每个月存储一个日志文件
  /// yyyy_MM_dd_HH 每小时存储一个日志文件

  /// 默认值: yyyy_MM_dd
  ///
  void setStoragePolicy(String policy) {
    if (_isEnable() == false) return;
    Pointer<Utf8> policyPtr = policy.toNativeUtf8();
    _setStoragePolicy(policyPtr);
    calloc.free(policyPtr);
  }

  /// 获取存储的日志大小 (byte)
  int logSize() {
    if (_isEnable() == false) return 0;
    return _getLogSize();
  }

  /// 写入文件格式化  默认 [%d][%t][%p]%m
  void setFilePattern(String pattern) {
    if (_isEnable() == false) return;
    Pointer<Utf8> patternPtr = pattern.toNativeUtf8();
    _setFilePattern(patternPtr);
    calloc.free(patternPtr);
  }

  void setConsolePattern(String pattern) {
    if (_isEnable() == false) return;
    Pointer<Utf8> patternPtr = pattern.toNativeUtf8();
    _setConsolePattern(patternPtr);
    calloc.free(patternPtr);
  }

  /// 设置写入日志文件同步还是异步
  void setAsync(bool isAsync) {
    if (_isEnable() == false) return;
    _setAsync(isAsync == true ? 1 : 0);
  }

  /// 是否正在debuging
  bool isDebugTraceing() {
    if (_isEnable() == false) return true;
    if (_isTracking != null) return _isTracking!;

    bool isTracking = _isDebugTracking() == 1 ? true : false;
    _isTracking = isTracking;
    return isTracking;
  }

  String? getdDiskcachePath() {
    if (_isEnable() == false) return null;
    Pointer<Int8> result = _getdDiskcachePath();
    if (result == nullptr) {
      return null;
    }
    String path = result.cast<Utf8>().toDartString();
    return path;
  }

  void debug(String msg, {String? name, String? tag}) {
    log(0, msg, name: name, tag: tag);
  }

  void info(String msg, {String? name, String? tag}) {
    log(1, msg, name: name, tag: tag);
  }

  void warn(String msg, {String? name, String? tag}) {
    log(2, msg, name: name, tag: tag);
  }

  void error(String msg, {String? name, String? tag}) {
    log(3, msg, name: name, tag: tag);
  }

  void fatal(String msg, {String? name, String? tag}) {
    log(4, msg, name: name, tag: tag);
  }

  /// 写入日志文件默认为异步，可以通过 setAsync 或者设置  isAsync == false 为同步
  void log(int lvl, String msg, {String? name, String? tag}) {
    if (_isEnable() == false) return;

    Pointer<Utf8> namePtr = name != null ? name.toNativeUtf8() : nullptr;
    Pointer<Utf8> tagPtr = tag != null ? tag.toNativeUtf8() : nullptr;
    Pointer<Utf8> msgPtr = tag != null ? msg.toNativeUtf8() : nullptr;

    _log(_handle, namePtr, lvl, msgPtr, tagPtr);

    calloc.free(namePtr);
    calloc.free(tagPtr);
    calloc.free(msgPtr);
  }
}

final DynamicLibrary _nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libmxlogger.so")
    : DynamicLibrary.process();

String _mxlogger_function(String funcName) {
  return "flutter_mxlogger_" + funcName;
}

///初始化logger
final Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>) _initialize =
    _nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Utf8>,
                    Pointer<Utf8>)>>(_mxlogger_function("initialize"))
        .asFunction();

final void Function(
        Pointer<Void>, Pointer<Utf8>, int, Pointer<Utf8>, Pointer<Utf8>) _log =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Utf8>, Int32,
                    Pointer<Utf8>, Pointer<Utf8>)>>(_mxlogger_function("log"))
        .asFunction();

final void Function(Pointer<Utf8>, int, Pointer<Utf8>, Pointer<Utf8>)
    _asyncLogFile = _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Utf8>, Int32, Pointer<Utf8>,
                    Pointer<Utf8>)>>(_mxlogger_function("async_log_file"))
        .asFunction();

final void Function(int) _setAsync = _nativeLib
    .lookup<NativeFunction<Void Function(Int32)>>(
        _mxlogger_function("set_is_async"))
    .asFunction();

final void Function(Pointer<Utf8>, int, Pointer<Utf8>, Pointer<Utf8>)
    _syncLogFile = _nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Utf8>, Int32, Pointer<Utf8>,
                    Pointer<Utf8>)>>(_mxlogger_function("sync_log_file"))
        .asFunction();

final void Function(int) _setFileLevel = _nativeLib
    .lookup<NativeFunction<Void Function(Int32)>>(
        _mxlogger_function("set_file_level"))
    .asFunction();

final void Function(int) _setConsoleLevel = _nativeLib
    .lookup<NativeFunction<Void Function(Int32)>>(
        _mxlogger_function("set_console_level"))
    .asFunction();

final void Function(int) _setFileEnable = _nativeLib
    .lookup<NativeFunction<Void Function(Int32)>>(
        _mxlogger_function("set_file_enable"))
    .asFunction();

final void Function(int) _setConsoleEnable = _nativeLib
    .lookup<NativeFunction<Void Function(Int32)>>(
        _mxlogger_function("set_console_enable"))
    .asFunction();

final void Function(Pointer<Utf8>) _setFileHeader = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
        _mxlogger_function("set_file_header"))
    .asFunction();

final void Function(Pointer<Utf8>) _setFileName = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
        _mxlogger_function("set_file_name"))
    .asFunction();

final Pointer<Int8> Function() _getdDiskcachePath = _nativeLib
    .lookup<NativeFunction<Pointer<Int8> Function()>>(
        _mxlogger_function("get_diskcache_path"))
    .asFunction();

final void Function(int) _setMaxdiskAge = _nativeLib
    .lookup<NativeFunction<Void Function(Int32)>>(
        _mxlogger_function("set_max_disk_age"))
    .asFunction();

final void Function(int) _setMaxdiskSize = _nativeLib
    .lookup<NativeFunction<Void Function(Uint64)>>(
        _mxlogger_function("set_max_disk_size"))
    .asFunction();

final void Function(Pointer<Utf8>) _setStoragePolicy = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
        _mxlogger_function("set_storage_policy"))
    .asFunction();

final void Function(Pointer<Utf8>) _setFilePattern = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
        _mxlogger_function("set_file_pattern"))
    .asFunction();

final void Function(Pointer<Utf8>) _setConsolePattern = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
        _mxlogger_function("set_console_pattern"))
    .asFunction();

final void Function() _removeExpireData = _nativeLib
    .lookup<NativeFunction<Void Function()>>(
        _mxlogger_function("remove_expire_data"))
    .asFunction();

final void Function() _removeAll = _nativeLib
    .lookup<NativeFunction<Void Function()>>(_mxlogger_function("remove_all"))
    .asFunction();

final int Function() _getLogSize = _nativeLib
    .lookup<NativeFunction<Uint64 Function()>>(
        _mxlogger_function("get_log_size"))
    .asFunction();

final int Function() _isDebugTracking = _nativeLib
    .lookup<NativeFunction<Int32 Function()>>(
        _mxlogger_function("is_debug_tracking"))
    .asFunction();
