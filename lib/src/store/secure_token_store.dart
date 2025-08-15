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
class SecureTokenStore implements TokenStore {
  final FlutterSecureStorage storage;

  static const String _indexKey = 'misskey_accounts_index';
  static const String _activeKey = 'misskey_active_account';

  const SecureTokenStore({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();

  @override

  /// トークンを保存または更新
  Future<void> upsert(AccountKey key, StoredToken token) async {
    final Map<String, dynamic> value = token.toJson();
    await storage.write(key: key.storageKey(), value: jsonEncode(value));
    await _addToIndex(key);
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
  Future<void> delete(AccountKey key) async {
    await storage.delete(key: key.storageKey());
    await _removeFromIndex(key);
    final active = await getActive();
    if (active != null && active == key) {
      await setActive(null);
    }
  }

  @override

  /// すべてのトークンと関連メタ情報（インデックス/アクティブ）を削除
  Future<void> clearAll() async {
    final keys = await _readIndex();
    for (final k in keys) {
      await storage.delete(key: k.storageKey());
    }
    await storage.delete(key: _indexKey);
    await storage.delete(key: _activeKey);
  }

  @override

  /// アクティブアカウントを設定する。`null` で解除
  Future<void> setActive(AccountKey? key) async {
    if (key == null) {
      await storage.delete(key: _activeKey);
      return;
    }
    final json = jsonEncode(key.toJson());
    await storage.write(key: _activeKey, value: json);
  }

  @override

  /// 現在のアクティブアカウントを取得。未設定時は `null`
  Future<AccountKey?> getActive() async {
    final raw = await storage.read(key: _activeKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AccountKey.fromJson(map);
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
