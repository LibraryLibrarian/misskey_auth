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
await auth.signOut(key);  // 1つのアカウントのトークンを失効させて削除
await auth.signOutAll();  // すべてのアカウントのトークンを失効させて削除
```

## サインアウト {#signing-out}

サインアウトすると、サーバー側でトークンを失効させてから、端末上のトークンを削除します。失効には Misskey 2026.9.0 以降が必要です。このバージョンから、アプリのトークンが `/api/i/revoke-token` で自分自身を失効させられるようになりました。MiAuth と OAuth のどちらのトークンでも、権限に関係なく失効させられます。

```dart
final result = await auth.signOut(key);
final revocation = result.revocation;
if (revocation == null) {
  // 失効を試みなかった。result.skipReason を参照
} else if (revocation.isInvalidated) {
  // revoked または alreadyInvalid: サーバー側ではトークンをもう使えない
} else if (revocation.status == TokenRevocationStatus.unsupported) {
  // サーバーが 2026.9.0 より古い。サーバー側ではトークンが有効なまま
} else {
  // failed: ネットワークエラー、タイムアウト、または想定外の応答
}
```

### モード

`mode` を渡すと、端末上のトークンをどう扱うかを選べます。

| `SignOutMode` | 失効 | 端末からの削除 |
|---|---|---|
| `revokeAndDelete`（既定） | する | 常に削除（失効の結果を問わない） |
| `revokeOrKeep` | する | 結果が `revoked` または `alreadyInvalid` の場合のみ |
| `localOnly` | しない | 常に削除 |

`revokeOrKeep` では、失効できなかったトークンが保存されたまま残るため、ユーザーは後で再試行できます。失効に対応していないサーバーは常に `unsupported` を返します。また、凍結されたアカウントなど、別の理由でサーバーに拒否されるアカウントは毎回失敗する可能性があります。こうしたアカウントを端末から削除するには、`SignOutMode.localOnly` で再度サインアウトしてください。

トークンが保存されていない場合や、保存データの破損などにより読み取れない場合は、どのモードでも失効を行わずに削除します。

### 結果

`signOut` は `SignOutResult` を返します。`signOutAll` はアカウントごとの `SignOutResult` を `listAccounts` の順で返します。

| フィールド | 意味 |
|---|---|
| `key` | 対象のアカウント |
| `revocation` | `TokenRevocationResult`。失効を試みなかった場合は `null` |
| `skipReason` | 失効を試みなかった理由（`localOnly`、`noStoredToken`、`unreadableToken` のいずれか）。試みた場合は `null` |
| `deleted` | 端末からトークンを削除したかどうか |

`TokenRevocationResult` は次のフィールドを持ちます。

| フィールド | 意味 |
|---|---|
| `status` | `revoked`、`alreadyInvalid`、`unsupported`、`failed` のいずれか |
| `isInvalidated` | `revoked` と `alreadyInvalid` のとき `true` |
| `statusCode` | HTTP ステータス。応答を受け取れなかった場合は `null` |
| `errorCode` | Misskey のエラーコード（例: `RATE_LIMIT_EXCEEDED`）。ある場合のみ |
| `error` | `unsupported` と `failed` の原因。通常、エラー応答や想定外の応答の場合は `TokenRevocationException`、ネットワークエラーやタイムアウトの場合は `NetworkException` |

`alreadyInvalid` は、サーバーがトークンを認識しなかったことを意味します。トークンがすでに失効しているか、アカウントが削除されています。`revoked` と同じように扱われます。

失効の失敗は結果として報告され、例外として投げられることはありません。端末上のトークンの削除で起きたエラーは、従来どおり投げられます。`signOutAll` は、まずすべてのアカウントの削除を試み、その後で最初のエラーを投げます。

`deleted` が `false` になるのは2つの場合です。`revokeOrKeep` によってトークンが残された場合と、失効の処理中に同じアカウントへ新しいトークンが保存された場合（例: ユーザーが再度サインインした）です。新しいトークンは失効させていないため、削除しません。

### タイムアウトと再試行 {#timeout-and-retries}

失効は再試行しません。`timeout` を指定しない場合、応答のないリクエストはリクエストのタイムアウトまで待ちます（[タイムアウト](#timeouts)を参照）。待ち時間を制限するには `timeout` を渡します。

```dart
await auth.signOut(key, timeout: const Duration(seconds: 5));
await auth.signOutAll(timeout: const Duration(seconds: 5));
```

`signOutAll` はすべてのアカウントを並行して失効させ、すべてのリクエストが呼び出し時点から数えた1つの期限を共有します。保存されたトークンの読み書きは、タイムアウトで打ち切られません。時間切れになったリクエストは `failed` として報告されます。それでもサーバー側ではトークンが失効している可能性があります。`revokeOrKeep` などでトークンが残っている場合は、再度失効させると `alreadyInvalid` が報告されます。

### マネージャーを使わない失効

トークンを自分で保存している場合は、`MisskeyTokenRevocationClient` を直接使います。このクラスはサーバー側でトークンを失効させるだけで、保存領域には一切触れません。

```dart
final revocation = MisskeyTokenRevocationClient();
final result = await revocation.revoke(
  host: 'misskey.io',
  accessToken: token,
  timeout: const Duration(seconds: 5),
);
if (result.isInvalidated) {
  // 自分の保存領域からトークンを削除する
}
```

`revoke` は例外を投げず、同じ `TokenRevocationResult` を返します。クライアントはトークンをリクエストボディに入れて送信します。独自の `Dio` を渡した場合は、そのインターセプターからトークンが見えるため、リクエストボディをログに出力しないでください。

## タイムアウト {#timeouts}

`MisskeyAuthManager.defaultInstance()` は既定のタイムアウト（接続 10 秒、送信と受信は各 20 秒）を使います。変更する場合は `MisskeyAuthManager` を自分で組み立てます。`MisskeyAuthManager` のタイムアウトは、それ自身が行うリクエスト（`/api/i` とトークンの失効）に適用されるため、各クライアントにも渡してください。

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

各コンストラクタは `connectTimeout`、`sendTimeout`、`receiveTimeout` を受け取ります。`dio` も受け取ります。`MisskeyOAuthClient` と `MisskeyMiAuthClient` は、渡された `Dio` にもタイムアウトの引数を適用します。`MisskeyTokenRevocationClient` はタイムアウトの引数を自身のリクエストにだけ適用し、渡された `Dio` は変更しません。`MisskeyAuthManager` は `dio` を渡された場合にタイムアウトの引数を無視します。その場合は `Dio` 側で直接設定してください。別の失効クライアントを使う場合は、`revocation` に渡します。

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

`SecureTokenStore` は `flutter_secure_storage` でトークンを保存します。保存先は iOS と macOS ではキーチェーン、Android では Keystore です。保存のオプションを変える場合は、独自に生成した `FlutterSecureStorage` を渡します。misskey_auth はこのクラスを再エクスポートしていないため、`flutter_secure_storage` を依存関係に追加して import してください。

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
