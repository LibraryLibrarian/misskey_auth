# Misskey Auth

MisskeyのOAuth認証・MiAuth認証をFlutterアプリで簡単に扱うためのライブラリ

## 概要

- MisskeyのOAuth 2.0認証やMiAuth認証に対応
- サーバーのバージョンに応じて自動で認証方式を切り替え
- トークンはセキュア保存(`flutter_secure_storage`)
- アカウント認証はOSブラウザを利用

## インストール

```yaml
dependencies:
  misskey_auth: ^1.0.0
```

## OAuth2.0を用いた認証方法
MisskeyのOAuth 2.0はIndieAuth仕様に準拠します。以下が必須です：
- `client_id`は有効なURLであること（例: `https://yourname.github.io/yourapp/`）
- `client_id`でホストしているHTMLに、以下の`<link>`を含めること
  ```html
  <link rel="redirect_uri" href="https://yourname.github.io/yourapp/redirect.html">
  ```
- 認可リクエストの`redirect_uri`が、上記`<link>`のURLと完全一致すること（プロトコル/大文字小文字/末尾スラッシュまで一致）

## HTMLページ例
```html
<!DOCTYPE html>
<html>
<head>
  <title>My App</title>
  <link rel="redirect_uri" href="https://yourname.github.io/yourapp/redirect.html">
</head>
<body>
  <h1>My Misskey App</h1>
</body>
</html>
```

### 基本的な認証

```dart
import 'package:misskey_auth/misskey_auth.dart';

// 認証設定
final config = MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yourname.github.io/yourapp/',
  redirectUri: 'https://yourname.github.io/yourapp/redirect.html',
  scope: 'read:account write:notes',
  callbackScheme: 'misskeyAuth',
);

// クライアント生成と認証
final client = MisskeyOAuthClient();
final token = await client.authenticate(config);
```

### カスタムURLスキーム（アプリ復帰用）
- 本ライブラリのサンプルでは`misskeyauth://oauth/callback`を使用
- iOS: `Info.plist`の`CFBundleURLSchemes`にこのライブラリを使用するアプリのcustomSchemeを登録
- Android: `AndroidManifest.xml`に`<data android:scheme="<ここにcustomScheme>" android:host="oauth" android:path="/callback" />`の`intent-filter`を追加
- `redirect.html`では取得した`code`/`state`をこのスキームへ転送

### よくあるエラー
- `Invalid redirect_uri`: 認可リクエストの`redirect_uri`と、`client_id`ページの`<link rel="redirect_uri">`が完全一致していない
  - ドメイン小文字化、末尾スラッシュの統一、HTTPS利用を確認

