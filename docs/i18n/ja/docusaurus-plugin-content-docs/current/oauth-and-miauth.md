---
sidebar_position: 4
title: OAuth と MiAuth
---

# OAuth と MiAuth

Misskey には、アプリがアクセストークンを取得する方法が2つあります。

| | OAuth 2.0 | MiAuth |
|---|---|---|
| 対応サーバー | Misskey v2023.9.0 以降 | 古いサーバーも含む |
| client_id ページ | 必要（HTTPS） | 不要 |
| ブラウザの戻り先 | client_id ページに記載した `redirect_uri` | `yourscheme://`（スキームのみ） |
| 設定クラス | `MisskeyOAuthConfig` | `MisskeyMiAuthConfig` |

どちらの方式も外部ブラウザを開き、カスタム URL スキームでアプリに戻るため、どちらでも[プラットフォーム設定](./platform-setup.md)が必要です。

サーバーが OAuth に対応しているかは、`MisskeyOAuthClient().getOAuthServerInfo(host)` で確認できます。非対応のサーバーでは `null` を返します。その場合 `authenticate` と `loginWithOAuth` は `OAuthNotSupportedException` を投げるので、MiAuth に切り替えられます。

## 設定

### `MisskeyOAuthConfig`

| 引数 | 説明 |
|---|---|
| `host` | Misskey サーバーのホスト（例: `misskey.io`） |
| `clientId` | [client_id ページ](./client-id-page.md)の URL |
| `redirectUri` | client_id ページに記載した redirect URI（例: `yourscheme://oauth/callback`） |
| `scope` | 空白区切りのスコープ（例: `read:account write:notes`） |
| `callbackScheme` | アプリのカスタムスキーム。必須だが、使われるのは `redirectUri` が `http(s)` の中継ページのときだけ。それ以外は `redirectUri` のスキームを使う |

### `MisskeyMiAuthConfig`

| 引数 | 説明 |
|---|---|
| `host` | Misskey サーバーのホスト |
| `appName` | ユーザーに表示するアプリ名 |
| `callbackScheme` | アプリのカスタムスキーム。Misskey はブラウザを `yourscheme://` へリダイレクトする |
| `permissions` | 要求する権限（例: `['read:account', 'write:notes']`）。任意 |
| `iconUrl` | ユーザーに表示するアプリアイコンの URL。任意 |

## トークンを保存しない場合

`MisskeyOAuthClient` と `MisskeyMiAuthClient` は認証を実行してトークンを返します。トークンは保存しません。

### OAuth

```dart
import 'package:misskey_auth/misskey_auth.dart';

final oauthClient = MisskeyOAuthClient();
final token = await oauthClient.authenticate(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'yourscheme://oauth/callback',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
);
print(token?.accessToken);
```

### MiAuth

```dart
import 'package:misskey_auth/misskey_auth.dart';

final miClient = MisskeyMiAuthClient();
final result = await miClient.authenticate(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
    iconUrl: 'https://example.com/icon.png', // 任意
  ),
);
print(result.token);
print(result.user); // サーバーが返した場合のユーザー情報
```

## トークンを保存する場合

`MisskeyAuthManager` は認証を実行し、トークンを `TokenStore` で保存します。`MisskeyAuthManager.defaultInstance()` は `SecureTokenStore` を使います。ログインのたびに、アカウントを識別する `AccountKey` を返します。

### OAuth

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();
final key = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'yourscheme://oauth/callback',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);
final current = await auth.currentToken();
```

OAuth の認証後、`MisskeyAuthManager` は新しいトークンで `/api/i` を呼び出してアカウント ID を取得します。

### MiAuth

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();
final key = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
    iconUrl: 'https://example.com/icon.png',
  ),
  setActive: true, // 保存に加えて、このアカウントをアクティブにする
);
final current = await auth.currentToken();
```

MiAuth はトークンと一緒にユーザー情報を返すため、`MisskeyAuthManager` はその `id` をアカウント ID に使います。

## 1つのアプリで両方式に対応する

- `Info.plist` と `AndroidManifest.xml` に `yourscheme` のようなスキームを1つ登録すれば、OAuth と MiAuth で共有できます。
- MiAuth はスキームのみ（`yourscheme://`）に戻ります。MiAuth のために `yourscheme://oauth/callback` のようなパスを用意する必要はありません。
- Android では、[プラットフォーム設定](./platform-setup.md#android)のスキームのみの intent-filter を残してください。host や path で制限した filter では、MiAuth のコールバックがアプリに届きません。

## 関連リンク

- [Misskey の OAuth のドキュメント](https://misskey-hub.net/ja/docs/for-developers/api/token/oauth/)
- [Misskey の MiAuth のドキュメント](https://misskey-hub.net/ja/docs/for-developers/api/token/miauth/)
