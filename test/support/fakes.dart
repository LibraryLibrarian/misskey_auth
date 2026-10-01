import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

/// 応答を関数で差し替える Dio アダプタ
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;

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

/// メモリ上の [TokenStore]（失敗・割り込みの注入用）
class MemoryTokenStore implements TokenStore {
  final Map<AccountKey, StoredToken> tokens = {};
  final List<AccountKey> index = [];
  AccountKey? active;

  /// 呼ばれた操作の記録（例: `read:user1`）
  final List<String> calls = [];

  /// 読み出しで例外を投げるアカウント
  final Set<AccountKey> throwOnRead = {};

  /// 削除で例外を投げるアカウント
  final Set<AccountKey> throwOnDelete = {};

  bool throwOnList = false;

  /// [list] の直前に呼ぶ（読み出しの遅延の再現用）
  Future<void> Function()? beforeList;

  /// トークンを保存した状態にする
  void seed(AccountKey key, String accessToken) {
    tokens[key] = StoredToken(accessToken: accessToken, tokenType: 'MiAuth');
    if (!index.contains(key)) index.add(key);
  }

  @override
  Future<void> upsert(AccountKey key, StoredToken token) async {
    calls.add('upsert:${key.accountId}');
    tokens[key] = token;
    if (!index.contains(key)) index.add(key);
  }

  @override
  Future<StoredToken?> read(AccountKey key) async {
    calls.add('read:${key.accountId}');
    if (throwOnRead.contains(key)) {
      throw const FormatException('corrupted');
    }
    return tokens[key];
  }

  @override
  Future<List<AccountEntry>> list() async {
    await beforeList?.call();
    calls.add('list');
    if (throwOnList) throw PlatformException(code: 'StorageError');
    return [for (final key in index) AccountEntry(key)];
  }

  @override
  Future<void> delete(AccountKey key) async {
    calls.add('delete:${key.accountId}');
    if (throwOnDelete.contains(key)) {
      throw PlatformException(code: 'StorageError');
    }
    tokens.remove(key);
    index.remove(key);
    if (active == key) active = null;
  }

  @override
  Future<void> clearAll() async {
    calls.add('clearAll');
    tokens.clear();
    index.clear();
    active = null;
  }

  @override
  Future<void> setActive(AccountKey? key) async => active = key;

  @override
  Future<AccountKey?> getActive() async => active;
}
