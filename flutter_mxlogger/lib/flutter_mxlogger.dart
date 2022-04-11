
library flutter_mxx_logger;

import 'dart:async';

export 'src/flutter_mx_logger.dart';

import 'package:flutter/services.dart';

class FlutterMxlogger {
  static const MethodChannel _channel = MethodChannel('flutter_mxlogger');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}