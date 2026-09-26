import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 応答を関数で差し替える Dio アダプタ
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}

/// JSON 応答を組み立てる
ResponseBody jsonBody(Object body, [int status = 200]) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

const _webAuthChannel = MethodChannel('flutter_web_auth_2');

/// flutter_web_auth_2 のブラウザ起動を差し替える
///
/// [callback] は起動 URL を受け取り、アプリへ戻る callback URL を返す
void mockWebAuth(String Function(Uri launchUrl) callback) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_webAuthChannel, (call) async {
        final url = Uri.parse(call.arguments['url'] as String);
        return callback(url);
      });
}

/// [mockWebAuth] の差し替えを解除する
void resetWebAuth() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_webAuthChannel, null);
}
