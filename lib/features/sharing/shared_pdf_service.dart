import 'dart:async';

import 'package:flutter/services.dart';

class SharedPdfService {
  SharedPdfService._();

  static const _channel = MethodChannel('com.example.campusPrintKun/sharing');
  static final _controller = StreamController<String>.broadcast();

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedPdfReceived') {
        _controller.add(call.arguments as String);
      }
    });
  }

  /// アプリ起動時に共有された PDF パスを返す（なければ null）。
  /// iOS 側は取得後にクリアするため、2 回目の呼び出しは null を返す。
  static Future<String?> getInitialSharedPdf() async {
    try {
      return await _channel.invokeMethod<String>('getInitialSharedPdf');
    } catch (_) {
      return null;
    }
  }

  /// アプリ起動中に共有された PDF のファイルパスを流す。
  static Stream<String> get onSharedPdf => _controller.stream;
}
