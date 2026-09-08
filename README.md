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

### Requirements and upgrading

- Flutter 3.47.1 or later; Dart 3.13.1 or later, before Dart 4.
- Android API 24 or later and compileSdk 37 or later. The example uses AGP 9.1.1, Gradle 9.3.1, and Kotlin Gradle Plugin 2.3.20. AGP requires JDK 17 or later.
- iOS 15 or later. Align the Xcode and Podfile deployment targets. The example includes Flutter's UIScene migration and Swift Package Manager integration.

Keep `android.builtInKotlin=false` and `android.newDsl=false` while the stable `flutter_web_auth_2` release still applies the Kotlin Android plugin. Retain that plugin, but replace `android.kotlinOptions` with `kotlin.compilerOptions` to configure its JVM target. Future Flutter versions may require built-in Kotlin support from dependencies.

This beta upgrades `flutter_secure_storage` from 9.x to 11.x without a 10.x migration step. On Android, credentials encrypted with the old defaults cannot be carried over directly; users must authenticate again for each affected account. This is a breaking change in Android storage compatibility; it does not imply the same data loss on iOS. Host apps must handle missing credentials and storage errors. Deleting local credentials does not revoke server-side tokens.

The default `SecureTokenStore` uses the shared default storage namespace. Version 11 enables `resetOnError` by default, so recovery can also delete other values in that namespace. Review shared-storage configurations before upgrading. See the [secure-storage changelog](https://pub.dev/packages/flutter_secure_storage/changelog) and [Flutter UIScene migration guide](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate).

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
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
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Minimum: scheme only -->
        <data android:scheme="yourscheme" />
        <!-- Optional (recommended when you control redirect.html): also restrict host/path -->
        <!-- <data android:scheme="yourscheme" android:host="oauth" android:path="/callback" /> -->
    </intent-filter>
</activity>
```

A complete, copyable configuration is available in
[`example/android/app/src/main/AndroidManifest.xml`](example/android/app/src/main/AndroidManifest.xml).
Treat that sample Manifest as the canonical working example for Android.

Notes:

- The `android:label` attribute on the `<intent-filter>` is optional. You can omit it or set any string.
- On Android 12+ (API level 31+), any Activity with an `intent-filter` must declare `android:exported="true"`.
- Set `android:taskAffinity=""` on both the exported `MainActivity` and `CallbackActivity` so the browser closes and the app returns to the foreground after authentication.
- Apps that perform network requests must declare `<uses-permission android:name="android.permission.INTERNET" />` directly under the `<manifest>` element in `android/app/src/main/AndroidManifest.xml`. A declaration in `debug` or `profile` does not apply to release builds.
- Use the same callback scheme string on both platforms: iOS (`CFBundleURLSchemes`) and Android (`<data android:scheme="...">`). They must match exactly.

Important (OAuth redirect on Android):
- Misskey OAuth requires `redirect_uri` to be HTTPS and exactly match the link in your client_id page.
- Typical pattern is:
  - `client_id` = `https://yourpage/yourapp/`
  - `redirect_uri` = `https://yourpage/yourapp/redirect.html`
  - The `redirect.html` then navigates to your custom scheme: `yourscheme://oauth/callback?code=...&state=...`
- If you restrict the Android intent-filter by host/path, make sure it matches the URL used in `redirect.html` (e.g., `yourscheme://oauth/callback`).
- If you see `PlatformException(CANCELED, User canceled login, ...)` on Android, common causes are:
  1) The device did not deliver the callback to the app. Ensure `com.linusu.flutter_web_auth_2.CallbackActivity` has a matching `<intent-filter>`.
  2) A PWA or another app intercepted the link. Using HTTPS → `redirect.html` → custom scheme flow usually mitigates this.
  3) The `redirect_uri` did not exactly match the `<link rel="redirect_uri">` in the client_id page.

#### Differences in MiAuth and OAuth Configuration (Key Points for App Integration)
- This configuration (registration of the URL scheme) is done on the "app side." It is not included in the library's Manifest.
- Both methods require a "custom URL scheme" to return from an external browser to the app.
- The difference lies in how to specify "where to return from the browser."
- OAuth: Since it needs to return to an HTTPS `redirect_uri` from the authorization server, `redirect.html` placed there ultimately redirects back to `yourscheme://...` for the app.
- MiAuth: The `callback` query of the authentication start URL points to the app via the custom scheme only (e.g., `yourscheme://`). No `https` is needed.

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
final miRes = await miClient.authenticate(miConfig); // returns token (and user if available)
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
- This library uses a scheme-only callback for MiAuth (e.g., `yourscheme://`). You do not need to reuse a path like `yourscheme://oauth/callback` for MiAuth.
- For Android, use the scheme-only configuration in [Android Configuration](#android-configuration).
  The `host` and `path` restrictions remain optional; the complete sample Manifest is linked from that section.

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
```

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

This project is published by 司書 (LibraryLibrarian) under the 3-Clause BSD License. For details, please see the [LICENSE](LICENSE) file.

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

### 動作要件と更新時の注意

- Flutter 3.47.1以上、Dart 3.13.1以上4.0未満。
- Android API 24以上、compileSdk 37以上。exampleはAGP 9.1.1、Gradle 9.3.1、Kotlin Gradle Plugin 2.3.20を使用します。AGPの実行にはJDK 17以上が必要です。
- iOS 15以上。XcodeとPodfileの最低対応バージョンを揃えてください。exampleにはFlutterのUIScene移行とSwift Package Manager統合を含めています。

安定版の`flutter_web_auth_2`がKotlin Androidプラグインを適用する間は、`android.builtInKotlin=false`と`android.newDsl=false`を維持してください。プラグインの適用は残し、JVMターゲット設定を`android.kotlinOptions`から`kotlin.compilerOptions`へ変更します。将来のFlutterでは依存プラグイン側の内蔵Kotlin対応が必要になる可能性があります。

このbetaでは`flutter_secure_storage`を9系から11系へ更新し、10系を経由する移行処理は提供しません。Androidで旧既定暗号方式により保存された認証情報は直接引き継げず、対象アカウントごとの再認証が必要です。これはAndroidの保存データ互換性に関する破壊的変更であり、iOSでも同様にデータが失われるという意味ではありません。利用側アプリで認証情報の欠落とストレージエラーを処理してください。端末上の認証情報の削除は、サーバー側のトークン失効を意味しません。

既定の`SecureTokenStore`は共通の既定保存領域を使用します。11系では`resetOnError`が既定で有効となり、復旧時に同じ領域の別用途の値も削除される可能性があります。同じ保存領域を共有する場合は更新前に設定を確認してください。[secure-storageの変更履歴](https://pub.dev/packages/flutter_secure_storage/changelog)と[FlutterのUIScene移行ガイド](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)も参照してください。

### インストール

`pubspec.yaml`ファイルに以下を追加してください：

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
```

### クイックスタート

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
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- 最小構成: schemeのみ -->
        <data android:scheme="yourscheme" />
        <!-- 任意（redirect.htmlを管理できる場合に推奨）: host/pathも制限 -->
        <!-- <data android:scheme="yourscheme" android:host="oauth" android:path="/callback" /> -->
    </intent-filter>
</activity>
```

動作する完全な設定例は
[`example/android/app/src/main/AndroidManifest.xml`](example/android/app/src/main/AndroidManifest.xml)です。
このサンプルManifestを、利用者がコピーできるAndroid設定の正しい実例として扱います。

補足:

- `<intent-filter>` の `android:label` は省略可能です（省略しても動作します）。
- Android 12+（API 31 以降）では、`intent-filter` を持つ Activity に `android:exported="true"` の指定が必須です。
- 認証後にブラウザを閉じてアプリを前面へ戻すため、exportedな`MainActivity`と`CallbackActivity`の両方に`android:taskAffinity=""`を設定してください。
- ネットワーク通信を行うアプリでは、`android/app/src/main/AndroidManifest.xml`の`<manifest>`直下に`<uses-permission android:name="android.permission.INTERNET" />`を宣言してください。`debug`または`profile`側だけの宣言はreleaseビルドへ適用されません。
- iOS（`CFBundleURLSchemes`）と Android（`<data android:scheme="...">`）で登録するカスタムスキーム名は同一にしてください（完全一致が必要）。

#### MiAuth と OAuth の設定の違い（アプリ組み込み時のポイント）

- この設定（URLスキームの登録）は「アプリ側」で行います。ライブラリ内のManifestには含めません。
- 両方式とも、外部ブラウザからアプリへ戻すために「カスタムURLスキーム」が必要です。
- 相違点は「ブラウザからどこに戻すか」の指定方法です。
  - OAuth: 認可サーバーからはHTTPSの`redirect_uri`に戻る必要があるため、そこに配置した`redirect.html`が最終的に`yourscheme://...`へリダイレクトしてアプリに戻します。
  - MiAuth: 認証開始URLの`callback`クエリには、アプリのカスタムスキームのみ（例: `yourscheme://`）を指定します（`https`は不要）。

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
final miRes = await miClient.authenticate(miConfig); // トークン（必要に応じて user も）を返します
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

- iOSの`Info.plist`・Androidの`AndroidManifest.xml`で同じ`scheme`（例: `yourscheme`）を1つ登録すれば、OAuth/MiAuthで共用可能です。
- 本ライブラリの MiAuth は scheme のみ（`yourscheme://`）を callback に使います。`yourscheme://oauth/callback` のようなパス付きに揃える必要はありません。
- Androidは[Android設定](#android設定)にある`scheme`のみの構成を使用してください。
  `host`や`path`による制限は任意で、完全なサンプルManifestは同セクションから参照できます。

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

このプロジェクトは司書(LibraryLibrarian)によって、3-Clause BSD Licenseの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

### リンク

- [Misskey OAuth ドキュメント](https://misskey-hub.net/ja/docs/for-developers/api/token/oauth/)
- [Misskey MiAuth ドキュメント](https://misskey-hub.net/ja/docs/for-developers/api/token/miauth/)
- [pub.dev パッケージ](https://pub.dev/packages/misskey_auth)
