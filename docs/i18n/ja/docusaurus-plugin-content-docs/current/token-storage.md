---
sidebar_position: 5
title: トークンの保存
---

# トークンの保存

`MisskeyAuthManager` は複数アカウントのトークンを保存し、どれがアクティブかを管理します。保存は `TokenStore` インターフェースを通して行い、既定の実装は `SecureTokenStore` です。

## アカウントの管理

```dart
final auth = MisskeyAuthManager.defaultInstance();

// トークン
final current = await auth.currentToken();  // アクティブなアカウント。なければ null
final specific = await auth.tokenOf(key);   // 指定したアカウント。なければ null

// アカウント
final accounts = await auth.listAccounts();
await auth.setActive(key);
final active = await auth.getActive();
await auth.clearActive();

// サインアウト
await auth.signOut(key);  // 1つのアカウントのトークンを削除
await auth.signOutAll();  // すべてのアカウントのトークンを削除
```

サインアウトは端末上のトークンを削除するだけです。サーバー側でトークンを失効させることはありません。

## タイムアウト

`MisskeyAuthManager.defaultInstance()` は既定のタイムアウト（接続 10 秒、送信と受信は各 20 秒）を使います。変更する場合は `MisskeyAuthManager` を自分で組み立てます。`MisskeyAuthManager` のタイムアウトは、それ自身が行う `/api/i` のリクエストにだけ適用されるため、各クライアントにも渡してください。

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

各コンストラクタは `connectTimeout`、`sendTimeout`、`receiveTimeout` を受け取ります。`dio` も受け取ります。クライアントは渡された `Dio` にもタイムアウトの引数を適用しますが、`MisskeyAuthManager` は `dio` を渡された場合にタイムアウトの引数を無視します。その場合は `Dio` 側で直接設定してください。

## モデル

```dart
class AccountKey {
  final String host;       // 例: 'misskey.io'
  final String accountId;  // そのサーバーでのユーザー ID
}

class StoredToken {
  final String accessToken;
  final String tokenType;  // 'MiAuth' または 'OAuth'
  final String? scope;     // OAuth のみ
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
}

class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;
}
```

ユーザー ID は1つのサーバー内でしか一意でないため、`AccountKey` はホストとユーザー ID を組み合わせます。ホストは設定に渡した文字列のまま保存されるので、同じサーバーには常に同じ表記（例: 小文字の `misskey.io`）を使ってください。既存の `AccountKey` にトークンを保存すると、古いトークンを置き換えます。

## `TokenStore`

別の場所にトークンを保存する場合は、`TokenStore` を実装して `MisskeyAuthManager` に渡します。

```dart
abstract class TokenStore {
  Future<void> upsert(AccountKey key, StoredToken token);
  Future<StoredToken?> read(AccountKey key);
  Future<List<AccountEntry>> list();
  Future<void> delete(AccountKey key);
  Future<void> clearAll();
  Future<void> setActive(AccountKey? key);
  Future<AccountKey?> getActive();
}
```

## `SecureTokenStore`

`SecureTokenStore` は `flutter_secure_storage` でトークンを保存します。保存先は iOS ではキーチェーン、Android では Keystore です。保存のオプションを変える場合は、独自に生成した `FlutterSecureStorage` を渡します。misskey_auth はこのクラスを再エクスポートしていないため、`flutter_secure_storage` を依存関係に追加して import してください。

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const store = SecureTokenStore(
  storage: FlutterSecureStorage(/* 任意のオプション */),
);
```

### 同時実行

- 書き込み操作（`upsert`、`delete`、`clearAll`、`setActive`）は、同じ isolate 内では、インスタンスが異なっても1つずつ実行されます。同時に書き込んでも、インデックスからアカウントが失われることはありません。
- 読み取りはブロックされません。また、`upsert` の後に `setActive` を行うような一連の操作は不可分ではありません。
- 別の isolate やプロセスからの書き込みとの間では排他制御を行いません。

### `clearAll` が削除するもの

`clearAll` は、ストアのインデックスに載っているアカウント、インデックス自体、アクティブなアカウントの設定を削除します。保存領域全体の列挙は行いません。Android では、1件の復号に失敗しただけで `readAll` が保存領域全体を消去することがあるためです。そのため、以前のバージョンでインデックスに載らずに残ったトークンは削除されません。

### 共有される保存領域 {#shared-storage}

既定の `SecureTokenStore` は既定の保存領域を使います。アプリ内の別のコードも同じ領域を使っている可能性があります。`flutter_secure_storage` 11 では `resetOnError` が既定で有効なため、保存領域のエラーからの復旧時に、同じ領域の別の値も削除されることがあります。同じ保存領域に別のデータを置いている場合は、設定を確認してください。[flutter_secure_storage の変更履歴](https://pub.dev/packages/flutter_secure_storage/changelog)も参照してください。
