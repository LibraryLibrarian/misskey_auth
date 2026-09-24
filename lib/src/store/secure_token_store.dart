import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_key.dart';
import 'stored_token.dart';
import 'token_store.dart';

/// `FlutterSecureStorage` を用いた `TokenStore` の実装
///
/// - iOS/Android のキーチェーン/Keystore に保存（平文ファイルは使用しない）
/// - 内部インデックス（`_indexKey`）でアカウント一覧を管理
/// - アクティブアカウントは `_activeKey` に JSON として永続化
///
/// 書き込み系の操作（[upsert]/[delete]/[clearAll]/[setActive]）は isolate 内で
/// 1つずつ実行し、1操作ごとの整合性を保つ。次の点は保証しない
/// - 読み取り系の操作が、実行中の書き込みの途中状態を読まないこと
/// - 複数の操作を組み合わせた処理（保存してからアクティブにする等）の不可分性
/// - 別の isolate やプロセスからの同時書き込み
class SecureTokenStore implements TokenStore {
  final FlutterSecureStorage storage;

  static const String _indexKey = 'misskey_accounts_index';
  static const String _activeKey = 'misskey_active_account';

  /// トークンを保存するキーの接頭辞（[AccountKey.storageKey] と一致させる）
  static const String _tokenKeyPrefix = 'misskey_token::';

  /// 最後に予約された書き込み操作の完了
  ///
  /// 既定の保存領域はインスタンス間で共有されるため、静的に持つ
  static Future<void> _lastWrite = Future<void>.value();

  const SecureTokenStore({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();

  @override
  /// トークンを保存または更新
  Future<void> upsert(AccountKey key, StoredToken token) {
    return _serialized(() async {
      // 途中で失敗しても、どこからも辿れないトークンが残らない順序で書く
      await _addToIndex(key);
      final Map<String, dynamic> value = token.toJson();
      await storage.write(key: key.storageKey(), value: jsonEncode(value));
    });
  }

  @override
  /// トークンを取得する。存在しない場合は `null` を返す
  Future<StoredToken?> read(AccountKey key) async {
    final raw = await storage.read(key: key.storageKey());
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return StoredToken.fromJson(map);
  }

  @override
  /// 保存済みアカウントの一覧を返す
  Future<List<AccountEntry>> list() async {
    final keys = await _readIndex();
    final List<AccountEntry> entries = [];
    for (final k in keys) {
      final token = await read(k);
      String? userName;
      DateTime? createdAt;
      if (token != null) {
        final user = token.user;
        if (user != null) {
          userName =
              (user['name'] ?? user['username'] ?? user['userName']) as String?;
        }
        createdAt = token.createdAt;
      }
      entries.add(AccountEntry(k, userName: userName, createdAt: createdAt));
    }
    return entries;
  }

  @override
  /// 指定アカウントのトークンを削除する。アクティブ一致時は解除する
  Future<void> delete(AccountKey key) {
    return _serialized(() async {
      await storage.delete(key: key.storageKey());
      await _removeFromIndex(key);
      final active = await getActive();
      if (active != null && active == key) {
        await storage.delete(key: _activeKey);
      }
    });
  }

  @override
  /// すべてのトークンと関連メタ情報（インデックス/アクティブ）を削除
  ///
  /// インデックスが壊れていても、インデックスから外れたトークンが残っていても
  /// 削除できるよう、キーの接頭辞で対象を探す。このライブラリ以外のキーは残す
  Future<void> clearAll() {
    return _serialized(() async {
      final all = await storage.readAll();
      // 削除中に元の Map が変わっても影響しないよう、先に対象を確定させる
      final tokenKeys = [
        for (final key in all.keys)
          if (key.startsWith(_tokenKeyPrefix)) key,
      ];
      for (final key in tokenKeys) {
        await storage.delete(key: key);
      }
      await storage.delete(key: _indexKey);
      await storage.delete(key: _activeKey);
    });
  }

  @override
  /// アクティブアカウントを設定する。`null` で解除
  Future<void> setActive(AccountKey? key) {
    return _serialized(() async {
      if (key == null) {
        await storage.delete(key: _activeKey);
        return;
      }
      final json = jsonEncode(key.toJson());
      await storage.write(key: _activeKey, value: json);
    });
  }

  @override
  /// 現在のアクティブアカウントを取得。未設定時は `null`
  Future<AccountKey?> getActive() async {
    final raw = await storage.read(key: _activeKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AccountKey.fromJson(map);
  }

  /// 書き込み操作を、先に予約された操作の完了後に実行する
  ///
  /// 再入はできないため、[action] の中から書き込み系の公開メソッドを呼ばないこと。
  /// 先の操作が失敗しても後続の操作は実行する
  static Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _lastWrite.then((_) => action());
    _lastWrite = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// インデックスにアカウントを追加（重複は無視）
  Future<void> _addToIndex(AccountKey key) async {
    final keys = await _readIndex();
    if (!keys.contains(key)) {
      keys.add(key);
      await _writeIndex(keys);
    }
  }

  /// インデックスからアカウントを削除
  Future<void> _removeFromIndex(AccountKey key) async {
    final keys = await _readIndex();
    keys.removeWhere((k) => k == key);
    await _writeIndex(keys);
  }

  /// インデックスを読み出す。未作成時は空配列を返す
  Future<List<AccountKey>> _readIndex() async {
    final raw = await storage.read(key: _indexKey);
    if (raw == null) return <AccountKey>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AccountKey.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// インデックスを書き込み
  Future<void> _writeIndex(List<AccountKey> keys) async {
    final json = jsonEncode(keys.map((k) => k.toJson()).toList());
    await storage.write(key: _indexKey, value: json);
  }
}
