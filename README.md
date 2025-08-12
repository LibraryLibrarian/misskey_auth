# Misskey Auth

<p align="center">
  <img src="https://raw.githubusercontent.com/librarylibrarian/misskey_auth/main/assets/demo_thumb.gif" alt="Demo" width="200" />
</p>

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

**Language**: [🇺🇸 English](#english) | [🇯🇵 日本語](#japanese)

---

## English

A Flutter library for Misskey OAuth authentication with automatic fallback to MiAuth for older servers.

### Features

- OAuth 2.0 authentication for Misskey servers (v2023.9.0+)
- Automatic fallback to MiAuth for older servers (Planned response in the future.)
- External browser authentication (no embedded WebViews)
- Secure token storage using flutter_secure_storage
- Cross-platform support (iOS/Android)
- PKCE (Proof Key for Code Exchange) implementation
- Custom URL scheme handling for authentication callbacks

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  misskey_auth: ^0.1.0-beta
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

#### 2. Basic Authentication

```dart
import 'package:misskey_auth/misskey_auth.dart';

// Authentication configuration
final config = MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yourpage/yourapp/',
  redirectUri: 'https://yourpage/yourapp/redirect.html',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',
);

// Create client and authenticate
final client = MisskeyOAuthClient();
final token = await client.authenticate(config);
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

Main client for handling Misskey authentication.

```dart
class MisskeyOAuthClient {
  /// Authenticate with Misskey server
  Future<OAuthTokenResponse> authenticate(MisskeyOAuthConfig config);
  
  /// Check if server supports OAuth 2.0
  Future<bool> isOAuthSupported(String host);
}
```

### Error Handling

The library provides custom exceptions for different error scenarios:

- `MisskeyAuthException` - Base exception class
- `OAuthNotSupportedException` - When server doesn't support OAuth 2.0
- `AuthenticationFailedException` - When authentication fails
- `TokenExchangeException` - When token exchange fails

### Common Errors

- `Invalid redirect_uri`: The `redirect_uri` in the authorization request doesn't exactly match the one in the `client_id` page's `<link rel="redirect_uri">` tag
  - Check domain case, trailing slashes, and HTTPS usage

### License

This project is licensed under the 3-Clause BSD License - see the [LICENSE](LICENSE) file for details.

### Example App Verification

This library includes a sample app to verify its functionality.

#### Running the Example App

1. Clone or download the repository
2. Navigate to the example directory:
   ```bash
   cd example
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

#### Features in the Example App

- **Server Info Check**: Verify if Misskey server supports OAuth 2.0
- **Authentication Setup**: Configure host, client ID, redirect URI, scope, and callback scheme
- **OAuth Flow**: Execute authentication using actual browser
- **Token Management**: Display and delete access tokens after successful authentication
- **Error Handling**: Verify behavior in various error scenarios

#### Default Configuration

The example app comes with the following default values:

- **Host**: `misskey.io`
- **Client ID**: `https://librarylibrarian.github.io/misskey_auth/`
- **Redirect URI**: `https://librarylibrarian.github.io/misskey_auth/redirect.html`
- **Scope**: `read:account write:notes`
- **Callback Scheme**: `misskeyauth`

These values are provided for testing purposes, but you should change them to your own values when developing actual apps.

### Related Links

- [Misskey OAuth Documentation](https://misskey-hub.net/en/docs/for-developers/api/token/oauth/)
- [Misskey MiAuth Documentation](https://misskey-hub.net/en/docs/for-developers/api/token/miauth/)
- [pub.dev Package](https://pub.dev/packages/misskey_auth)

---

## Japanese

MisskeyのOAuth認証・MiAuth認証をFlutterアプリで簡単に扱うためのライブラリ。

### 内容

- MisskeyサーバーのOAuth 2.0認証対応（v2023.9.0以降）
- 古いサーバーでは自動的にMiAuth認証にフォールバック（今後対応予定）
- 埋め込みWebViewを使用しない認証
- flutter_secure_storageを使用したトークン保存
- クロスプラットフォーム対応（iOS/Android）
- PKCE（Proof Key for Code Exchange）実装
- 認証コールバック用カスタムURLスキーム対応

### インストール

`pubspec.yaml`ファイルに以下を追加してください：

```yaml
dependencies:
  misskey_auth: ^0.1.0-beta
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

#### 2. 基本的な認証

```dart
import 'package:misskey_auth/misskey_auth.dart';

// 認証設定
final config = MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yourpage/yourapp/',
  redirectUri: 'https://yourpage/yourapp/redirect.html',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',
);

// クライアント生成と認証
final client = MisskeyOAuthClient();
final token = await client.authenticate(config);
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

Misskey認証を処理するメインクライアント。

```dart
class MisskeyOAuthClient {
  /// Misskeyサーバーで認証を実行
  Future<OAuthTokenResponse> authenticate(MisskeyOAuthConfig config);
  
  /// サーバーがOAuth 2.0をサポートしているかチェック
  Future<bool> isOAuthSupported(String host);
}
```

### エラーハンドリング

ライブラリは様々なエラーシナリオに対応するカスタム例外を提供します：

- `MisskeyAuthException` - ベース例外クラス
- `OAuthNotSupportedException` - サーバーがOAuth 2.0をサポートしていない場合
- `AuthenticationFailedException` - 認証が失敗した場合
- `TokenExchangeException` - トークン交換が失敗した場合

### よくあるエラー

- `Invalid redirect_uri`: 認可リクエストの`redirect_uri`と、`client_id`ページの`<link rel="redirect_uri">`が完全一致していない
  - ドメインの大文字小文字、末尾スラッシュ、HTTPS使用を確認してください

### ライセンス

このプロジェクトは3-Clause BSD Licenseの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

### サンプルアプリでの確認方法

このライブラリには動作を確認できるサンプルアプリが同梱されています。

#### サンプルアプリの実行

1. リポジトリをクローンまたはダウンロード
2. サンプルアプリディレクトリに移動：
   ```bash
   cd example
   ```
3. 依存関係をインストール：
   ```bash
   flutter pub get
   ```

4. アプリを実行：
   ```bash
   flutter run
   ```

#### サンプルアプリの機能

- **サーバー情報の確認**: MisskeyサーバーがOAuth 2.0をサポートしているかチェック
- **認証設定**: ホスト、クライアントID、リダイレクトURI、スコープ、コールバックスキームの設定
- **OAuth認証フロー**: 実際のブラウザを使った認証の実行
- **トークン管理**: 認証成功時のアクセストークンの表示・削除
- **エラーハンドリング**: 各種エラー状況での動作確認

#### デフォルト設定

サンプルアプリには以下のデフォルト値が設定されています：

- **ホスト**: `misskey.io`
- **クライアントID**: `https://librarylibrarian.github.io/misskey_auth/`
- **リダイレクトURI**: `https://librarylibrarian.github.io/misskey_auth/redirect.html`
- **スコープ**: `read:account write:notes`
- **コールバックスキーム**: `misskeyauth`

これらの値は動作確認用として提供されていますが、実際のアプリ開発時は独自の値に変更してください。
自分が対象としているサーバーでライブラリが利用できるかのチェックにも使えます。

### リンク

- [Misskey OAuth ドキュメント](https://misskey-hub.net/ja/docs/for-developers/api/token/oauth/)
- [Misskey MiAuth ドキュメント](https://misskey-hub.net/ja/docs/for-developers/api/token/miauth/)
- [pub.dev パッケージ](https://pub.dev/packages/misskey_auth)