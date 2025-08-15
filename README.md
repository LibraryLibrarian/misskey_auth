# Misskey Auth

<p align="center">
  <img src="https://raw.githubusercontent.com/librarylibrarian/misskey_auth/main/assets/demo_thumb.gif" alt="Demo" width="200" />
</p>

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

**Language**: [🇺🇸 English](#english) | [🇯🇵 日本語](#japanese)

---

## English

A Flutter library for Misskey OAuth authentication with MiAuth support and multi-account token management.

### Features

- OAuth 2.0 authentication for Misskey servers (v2023.9.0+)
- MiAuth authentication for older servers
- External browser authentication (no embedded WebViews)
- Secure token storage using `flutter_secure_storage`
- Cross-platform support (iOS/Android)
- PKCE (Proof Key for Code Exchange) implementation
- Custom URL scheme handling for authentication callbacks
- Multi-account token storage and account switching
- High-level `MisskeyAuthManager` to run flows and persist tokens

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  misskey_auth: ^0.1.3-beta
```

### Quick Start

#### 1. Set up your client_id page

Misskey's OAuth 2.0 follows the IndieAuth specification. You need:

- `client_id` must be a valid URL (e.g., `https://yoursite/yourapp/`)
- The HTML hosted at `client_id` must include the following `<link>`:
  ```html
  <link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">
  ```
- The `redirect_uri` in authorization requests must exactly match the URL in the `<link>` tag (protocol, case, trailing slash, etc.)

##### Example HTML page

```html
<!DOCTYPE html>
<html>
<head>
  <title>My App</title>
  <link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">
</head>
<body>
  <div class="h-app">
    <a href="https://yoursite/yourapp/" class="u-url p-name">Your Misskey App</a>
  </div>
</body>
</html>
```

##### Example redirect page

```html
<!DOCTYPE html>
<html>
<body>
    <script>
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');
        const state = urlParams.get('state');
        const appUrl = `yourscheme://oauth/callback?code=${encodeURIComponent(code)}&state=${encodeURIComponent(state || '')}`;
        window.location.href = appUrl;
    </script>
</body>
</html>
```

#### 2. Basic Authentication (Recommended: via MisskeyAuthManager)

```dart
import 'package:misskey_auth/misskey_auth.dart';

// Create manager with default dependencies
final auth = MisskeyAuthManager.defaultInstance();

// OAuth
final oauthKey = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'https://yourpage/yourapp/redirect.html',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);

// MiAuth
final miKey = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
    iconUrl: 'https://example.com/icon.png',
  ),
  setActive: true,
);

// Tokens
final current = await auth.currentToken();
final specific = await auth.tokenOf(oauthKey);

// Accounts
final accounts = await auth.listAccounts();
await auth.setActive(miKey);
await auth.signOut(oauthKey);
await auth.signOutAll();
```

#### 3. Platform Configuration

##### iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourscheme</string>
        </array>
    </dict>
</array>
```

##### Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity android:name="com.linusu.flutter_web_auth.CallbackActivity" android:exported="true">
    <intent-filter android:label="flutter_web_auth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="yourscheme" />
    </intent-filter>
</activity>
```

#### Differences in MiAuth and OAuth Configuration (Key Points for App Integration)
- This configuration (registration of the URL scheme) is done on the "app side." It is not included in the library's Manifest.
- Both methods require a "custom URL scheme" to return from an external browser to the app.
- The difference lies in how to specify "where to return from the browser."
- OAuth: Since it needs to return to an HTTPS `redirect_uri` from the authorization server, `redirect.html` placed there ultimately redirects back to `yourscheme://...` for the app.
- MiAuth: The `callback` query of the authentication start URL specifies `yourscheme://...` from the beginning (no need for `https`).

##### Example of MiAuth (no persistence)

```dart
import 'package:misskey_auth/misskey_auth.dart';

final miClient = MisskeyMiAuthClient(); // does not save tokens
final miConfig = MisskeyMiAuthConfig(
  host: 'misskey.io',
  appName: 'Your App',
  callbackScheme: 'yourscheme',          // Scheme registered on the app side
  permissions: ['read:account', 'write:notes'],
  iconUrl: 'https://example.com/icon.png', // Optional
);
final miRes = await miClient.authenticate(miConfig); // returns token only
```

##### Example of MiAuth (with persistence via MisskeyAuthManager)

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
  setActive: true, // also mark as active account
);
// Token is saved via SecureTokenStore; you can read it later:
final current = await auth.currentToken();
```

##### Example of OAuth (no persistence)

```dart
import 'package:misskey_auth/misskey_auth.dart';

final oauthClient = MisskeyOAuthClient(); // does not save tokens
final oauthConfig = MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yourpage/yourapp/',
  redirectUri: 'https://yourpage/yourapp/redirect.html',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',          // Scheme registered on the app side
);
final token = await oauthClient.authenticate(oauthConfig); // returns token only
```

##### Example of OAuth (with persistence via MisskeyAuthManager)

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();
final key = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'https://yourpage/yourapp/redirect.html',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);
// Token is saved via SecureTokenStore; you can read it later:
final current = await auth.currentToken();
```

##### How to Support Both Methods in the Same App
- By registering the same `scheme` (e.g., `yourscheme`) in iOS's `Info.plist` and Android's `AndroidManifest.xml`, it can be shared between OAuth and MiAuth.
- If you implement the OAuth `redirect.html` to redirect to `yourscheme://oauth/callback?...`, you can reuse the same path expression (`yourscheme://oauth/callback`) for MiAuth's `callback`.
- For Android, matching only on the `scheme` is sufficient as shown below (the `host` and `path` are optional).

```xml
<activity android:name="com.linusu.flutter_web_auth.CallbackActivity" android:exported="true">
    <intent-filter android:label="flutter_web_auth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="yourscheme" />
    </intent-filter>
    <!-- Add this only if you want to restrict by host/path -->
    <!-- <intent-filter> ... <data android:scheme="yourscheme" android:host="oauth" android:path="/callback"/> ... </intent-filter> -->
  </activity>
```

### API Reference

#### MisskeyOAuthConfig

Configuration class for Misskey OAuth authentication.

```dart
class MisskeyOAuthConfig {
  final String host;           // Misskey server host (e.g., 'misskey.io')
  final String clientId;       // Your client_id page URL
  final String redirectUri;    // Your redirect page URL
  final String scope;          // Requested scopes (e.g., 'read:account write:notes')
  final String callbackScheme; // Your app's custom URL scheme
}
```

#### MisskeyOAuthClient

Main client for handling Misskey OAuth authentication.

```dart
class MisskeyOAuthClient {
  /// Authenticate with Misskey server (no persistence)
  Future<OAuthTokenResponse?> authenticate(MisskeyOAuthConfig config);
  
  /// Get OAuth server information
  Future<OAuthServerInfo?> getOAuthServerInfo(String host);
}
```

#### MisskeyMiAuthClient

Main client for handling Misskey MiAuth authentication.

```dart
class MisskeyMiAuthClient {
  /// Authenticate with Misskey server using MiAuth (no persistence)
  Future<MiAuthTokenResponse> authenticate(MisskeyMiAuthConfig config);
}

#### MisskeyAuthManager

High-level API to run OAuth/MiAuth and persist tokens via `TokenStore`.
The default `defaultInstance()` uses `SecureTokenStore`.

```dart
class MisskeyAuthManager {
  static MisskeyAuthManager defaultInstance();

  Future<AccountKey> loginWithOAuth(MisskeyOAuthConfig config, { bool setActive = true });
  Future<AccountKey> loginWithMiAuth(MisskeyMiAuthConfig config, { bool setActive = true });

  Future<StoredToken?> currentToken();
  Future<StoredToken?> tokenOf(AccountKey key);

  Future<void> setActive(AccountKey key);
  Future<AccountKey?> getActive();
  Future<void> clearActive();

  Future<List<AccountEntry>> listAccounts();
  Future<void> signOut(AccountKey key);
  Future<void> signOutAll();
}
```

#### TokenStore / SecureTokenStore

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

#### Models (excerpt)

```dart
class StoredToken {
  final String accessToken;
  final String tokenType; // 'MiAuth' | 'OAuth'
  final String? scope;
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
}

class AccountKey {
  final String host;
  final String accountId;
}

class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;
}
```
```

### Error Handling

The library provides comprehensive error handling with custom exception classes for different scenarios. For detailed information about each exception class and their usage, please refer to the documentation on pub.dev.

The library includes exception classes for:
- Authentication configuration errors
- Network and connectivity issues
- OAuth and MiAuth specific errors
- User cancellation and authorization failures
- Secure storage operations
- Response parsing errors

### Common Errors

- `Invalid redirect_uri`: The `redirect_uri` in the authorization request doesn't exactly match the one in the `client_id` page's `<link rel="redirect_uri">` tag
  - Check domain case, trailing slashes, and HTTPS usage

### License

This project is licensed under the 3-Clause BSD License - see the [LICENSE](LICENSE) file for details.

### Related Links

- [Misskey OAuth Documentation](https://misskey-hub.net/en/docs/for-developers/api/token/oauth/)
- [Misskey MiAuth Documentation](https://misskey-hub.net/en/docs/for-developers/api/token/miauth/)
- [pub.dev Package](https://pub.dev/packages/misskey_auth)

---

## Japanese

MisskeyのOAuth認証・MiAuth認証に加え、マルチアカウントのトークン管理を提供するFlutterライブラリ。

### 内容

- MisskeyサーバーのOAuth 2.0認証対応（v2023.9.0以降）
- 古いサーバー向けMiAuth認証
- 埋め込みWebViewを使用しない認証
- `flutter_secure_storage` を使用したセキュアなトークン保存
- クロスプラットフォーム対応（iOS/Android）
- PKCE（Proof Key for Code Exchange）実装
- 認証コールバック用カスタムURLスキーム対応
- マルチアカウントのトークン保存とアカウント切替
- 認証と保存を仲介する高レベルAPI `MisskeyAuthManager`

### インストール

`pubspec.yaml`ファイルに以下を追加してください：

```yaml
dependencies:
  misskey_auth: ^0.1.3-beta
```

### クイックスタート

#### かんたん例（MisskeyAuthManager）

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// 認証後にトークンを自動保存
final key = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'https://yourpage/yourapp/redirect.html',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);
```

#### 1. client_idページの設定

MisskeyのOAuth 2.0はIndieAuth仕様に準拠しています。以下が必要です：

- `client_id`は有効なURLであること（例: `https://yoursite/yourapp/`）
- `client_id`でホストしているHTMLに、以下の`<link>`を含めること：
  ```html
  <link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">
  ```
- 認可リクエストの`redirect_uri`が、上記`<link>`のURLと完全一致すること（プロトコル、大文字小文字、末尾スラッシュまで一致）

##### HTMLページ例

```html
<!DOCTYPE html>
<html>
<head>
  <title>My App</title>
  <link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">
</head>
<body>
  <div class="h-app">
    <a href="https://yoursite/yourapp/" class="u-url p-name">Your Misskey App</a>
  </div>
</body>
</html>
```

##### リダイレクトページ例

```html
<!DOCTYPE html>
<html>
<body>
    <script>
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');
        const state = urlParams.get('state');
        const appUrl = `yourscheme://oauth/callback?code=${encodeURIComponent(code)}&state=${encodeURIComponent(state || '')}`;
        window.location.href = appUrl;
    </script>
</body>
</html>
```

#### 2. 基本的な認証（推奨: MisskeyAuthManager 経由）

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth
final oauthKey = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'https://yourpage/yourapp/redirect.html',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);

// MiAuth
final miKey = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
    iconUrl: 'https://example.com/icon.png',
  ),
  setActive: true,
);

// トークン取得
final current = await auth.currentToken();
final specific = await auth.tokenOf(oauthKey);

// アカウント管理
final accounts = await auth.listAccounts();
await auth.setActive(miKey);
await auth.signOut(oauthKey);
await auth.signOutAll();
```

#### 3. プラットフォーム設定

##### iOS設定

`ios/Runner/Info.plist`に追加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourscheme</string>
        </array>
    </dict>
</array>
```

##### Android設定

`android/app/src/main/AndroidManifest.xml`に追加：

```xml
<activity android:name="com.linusu.flutter_web_auth.CallbackActivity" android:exported="true">
    <intent-filter android:label="flutter_web_auth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="yourscheme" />
    </intent-filter>
</activity>
```

#### MiAuth と OAuth の設定の違い（アプリ組み込み時のポイント）

- この設定（URLスキームの登録）は「アプリ側」で行います。ライブラリ内のManifestには含めません。
- 両方式とも、外部ブラウザからアプリへ戻すために「カスタムURLスキーム」が必要です。
- 相違点は「ブラウザからどこに戻すか」の指定方法です。
  - OAuth: 認可サーバーからはHTTPSの`redirect_uri`に戻る必要があるため、そこに配置した`redirect.html`が最終的に`yourscheme://...`へリダイレクトしてアプリに戻します。
  - MiAuth: 認証開始URLの`callback`クエリに、最初から`yourscheme://...`を指定します（`https`は不要）。

##### MiAuth の例（保存無し）

```dart
import 'package:misskey_auth/misskey_auth.dart';

final miClient = MisskeyMiAuthClient(); // 保存はしません
final miConfig = MisskeyMiAuthConfig(
  host: 'misskey.io',
  appName: 'Your App',
  callbackScheme: 'yourscheme',          // アプリ側で登録したスキーム
  permissions: ['read:account', 'write:notes'],
  iconUrl: 'https://example.com/icon.png', // 任意
);
final miRes = await miClient.authenticate(miConfig); // トークンのみ返します
```

##### MiAuth の例（MisskeyAuthManager による保存あり）

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
  setActive: true,
);
// トークンは SecureTokenStore に保存され、後から取得できます
final current = await auth.currentToken();
```

##### OAuth の例（保存無し）

```dart
import 'package:misskey_auth/misskey_auth.dart';

final oauthClient = MisskeyOAuthClient(); // 保存はしません
final oauthConfig = MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yourpage/yourapp/',
  redirectUri: 'https://yourpage/yourapp/redirect.html',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',          // アプリ側で登録したスキーム
);
final token = await oauthClient.authenticate(oauthConfig); // トークンのみ返します
```

##### OAuth の例（MisskeyAuthManager による保存あり）

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();
final key = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'https://yourpage/yourapp/redirect.html',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);
// トークンは SecureTokenStore に保存され、後から取得できます
final current = await auth.currentToken();
```

##### 両方式を同一アプリでサポートするには

- iOSの`Info.plist`・Androidの`AndroidManifest.xml`で同じ`sheme`（例: `yourscheme`）を1つ登録すれば、OAuth/MiAuthで共用可能です。
- OAuth用の`redirect.html`は、`yourscheme://oauth/callback?...`へ飛ばす実装にしておくと、MiAuthの`callback`でも同じパス表現（`yourscheme://oauth/callback`）を使い回せます。
- Androidは以下のように`scheme`のみのマッチで十分です（`host`や`path`は任意）。

```xml
<activity android:name="com.linusu.flutter_web_auth.CallbackActivity" android:exported="true">
    <intent-filter android:label="flutter_web_auth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="yourscheme" />
    </intent-filter>
    <!-- 必要に応じて、host/pathで限定したい場合のみ追記 -->
    <!-- <intent-filter> ... <data android:scheme="yourscheme" android:host="oauth" android:path="/callback"/> ... </intent-filter> -->
  </activity>
```

### API リファレンス

#### MisskeyOAuthConfig

Misskey OAuth認証の設定クラス。

```dart
class MisskeyOAuthConfig {
  final String host;           // Misskeyサーバーのホスト（例: 'misskey.io'）
  final String clientId;       // client_idページのURL
  final String redirectUri;    // リダイレクトページのURL
  final String scope;          // 要求するスコープ（例: 'read:account write:notes'）
  final String callbackScheme; // アプリのカスタムURLスキーム
}
```

#### MisskeyOAuthClient

Misskey OAuth認証を処理するメインクラス

```dart
class MisskeyOAuthClient {
  /// Misskeyサーバーで認証を実行（保存は行いません）
  Future<OAuthTokenResponse?> authenticate(MisskeyOAuthConfig config);
  
  /// OAuthサーバー情報を取得
  Future<OAuthServerInfo?> getOAuthServerInfo(String host);
}
```

#### MisskeyMiAuthClient

Misskey MiAuth認証を処理するメインクラス

```dart
class MisskeyMiAuthClient {
  /// MisskeyサーバーでMiAuth認証を実行（Tokenの保存はされません）
  Future<MiAuthTokenResponse> authenticate(MisskeyMiAuthConfig config);
}

#### MisskeyAuthManager

`TokenStore` を介して OAuth/MiAuth を実行し、トークンを保存する高レベルAPI。

```dart
class MisskeyAuthManager {
  static MisskeyAuthManager defaultInstance();

  Future<AccountKey> loginWithOAuth(MisskeyOAuthConfig config, { bool setActive = true });
  Future<AccountKey> loginWithMiAuth(MisskeyMiAuthConfig config, { bool setActive = true });

  Future<StoredToken?> currentToken();
  Future<StoredToken?> tokenOf(AccountKey key);

  Future<void> setActive(AccountKey key);
  Future<AccountKey?> getActive();
  Future<void> clearActive();

  Future<List<AccountEntry>> listAccounts();
  Future<void> signOut(AccountKey key);
  Future<void> signOutAll();
}
```

#### TokenStore / SecureTokenStore

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

#### モデル（抜粋）

```dart
class StoredToken {
  final String accessToken;
  final String tokenType; // 'MiAuth' | 'OAuth'
  final String? scope;
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
}

class AccountKey {
  final String host;
  final String accountId;
}

class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;
}
```

### エラーハンドリング

ライブラリには以下のカテゴリの例外クラスが含まれています：
- 認証設定エラー
- ネットワーク・接続エラー
- OAuth・MiAuth固有のエラー
- ユーザーキャンセル・認可失敗
- セキュアストレージ操作エラー
- レスポンス解析エラー

詳細についてはpub.devのドキュメントを参考にして下さい

### よくあるエラー

- `Invalid redirect_uri`: 認可リクエストの`redirect_uri`と、`client_id`ページの`<link rel="redirect_uri">`が完全一致していない
  - ドメインの大文字小文字、末尾スラッシュ、HTTPS使用を確認してください

### ライセンス

このプロジェクトは3-Clause BSD Licenseの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

### リンク

- [Misskey OAuth ドキュメント](https://misskey-hub.net/ja/docs/for-developers/api/token/oauth/)
- [Misskey MiAuth ドキュメント](https://misskey-hub.net/ja/docs/for-developers/api/token/miauth/)
- [pub.dev パッケージ](https://pub.dev/packages/misskey_auth)