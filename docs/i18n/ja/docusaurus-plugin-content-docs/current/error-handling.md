---
sidebar_position: 6
title: エラーハンドリング
---

# エラーハンドリング

認証の API は `MisskeyAuthException` のサブクラスを投げます。個別に扱いたい型を catch し、残りは `MisskeyAuthException` で受けてください。

```dart
try {
  await auth.loginWithOAuth(config);
} on UserCancelledException {
  // ユーザーがブラウザを閉じた。通常は報告不要
} on OAuthNotSupportedException {
  // サーバーが OAuth に非対応。MiAuth を試す
} on NetworkException catch (e) {
  // タイムアウト、接続なし、TLS エラーなど
  log('Network error', error: e.originalException);
} on MisskeyAuthException catch (e) {
  log('Authentication failed: ${e.message} ${e.details ?? ''}');
}
```

各例外は次のプロパティを持ちます。

- `message`: 短い説明
- `details`: 追加の情報（ある場合）
- `originalException`: 元になった例外（ある場合）

`message` と `details` はログ向けです。日本語のメッセージも含まれます。ユーザーには、例外の型に応じてアプリ側で用意した文言を表示してください。

## 例外の一覧

### 共通

| 例外 | 投げられる条件 |
|---|---|
| `UserCancelledException` | ユーザーがブラウザを閉じた、または認証をキャンセルした。[プラットフォーム設定](./platform-setup.md)も参照 |
| `CallbackSchemeErrorException` | コールバックの URL スキームが未設定または不一致だとプラットフォームが報告した |
| `AuthorizationLaunchException` | ブラウザを開けなかった、またはプラットフォームがその他のエラーを報告した |
| `NetworkException` | 応答を得られずにリクエストが失敗した（タイムアウト、接続なし、TLS エラーなど） |
| `ResponseParseException` | 応答が想定した JSON ではなかった、または必須のフィールドがなかった |
| `MisskeyAuthException` | 想定外のエラー。この表と以下の表にあるすべての例外の基底クラス |

### OAuth

| 例外 | 投げられる条件 |
|---|---|
| `OAuthNotSupportedException` | サーバーが OAuth に非対応（`/.well-known/oauth-authorization-server` が 404 または 501 を返した） |
| `ServerInfoException` | サーバー情報を取得できなかった、`issuer` が接続先と一致しなかった、またはエンドポイントが HTTPS の URL ではなかった |
| `StateMismatchException` | コールバックの `state` がない、またはリクエストと一致しない |
| `AuthorizationServerErrorException` | コールバックに `error` が含まれていた（例: ユーザーがアクセスを拒否したときの `access_denied`）。`details` に `error` と `error_description` が入る |
| `AuthorizationCodeMissingException` | コールバックに認可コードがない、または複数ある |
| `TokenExchangeException` | トークンエンドポイントがエラーを返した。メッセージに HTTP ステータスとサーバーからのエラーが入る |

### MiAuth

| 例外 | 投げられる条件 |
|---|---|
| `MiAuthDeniedException` | チェック API が `ok: false` を返した。ユーザーが拒否した可能性があるが、Misskey は未知のセッションや取得済みのセッションにもこの値を返す |
| `MiAuthSessionInvalidException` | コールバックが別のセッションのものだった、またはチェック API が 404 か 410 を返した |
| `MiAuthCheckFailedException` | チェック API がその他のエラーステータスを返した |

### 現在のバージョンでは投げられない例外

`InvalidAuthConfigException`、`SecureStorageException`、`MiAuthNotSupportedException` は定義されていますが、現在のバージョンでは投げられません。

## 保存領域のエラー

`SecureTokenStore` は `flutter_secure_storage` のエラーを包みません。エラーはそのパッケージが投げたまま（通常は `PlatformException`）呼び出し側に届きます。トークンを読み書きする `MisskeyAuthManager` の呼び出しでは、これらも扱ってください。認証後にトークンを保存する `loginWithOAuth` と `loginWithMiAuth` も含みます。

## 再試行

- OAuth のサーバー情報の取得と `/api/i` の呼び出しは、タイムアウト、接続エラー、HTTP 429・500・502・503・504 のときに、合計3回まで試行します。
- トークンの交換と MiAuth のチェック API は再試行しません。認可コードと MiAuth のセッションは一度しか使えず、応答が失われてもサーバー側では処理が済んでいる可能性があるためです。最初から認証をやり直してください。

## 認証後にログインが失敗した場合

`loginWithOAuth` はトークンを取得した後に `/api/i` を呼び出します。この呼び出しが失敗すると、トークンを保存せずに例外を投げます。端末上のトークンを削除したり失ったりしても、サーバー側では失効しません。サーバーが発行したトークンは有効なままです。ユーザーは再度サインインできます。
