[English](README.md) | 日本語 | [简体中文](README.zh-Hans.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [한국어](README.ko.md)

# misskey_auth

<p align="center">
  <img src="https://raw.githubusercontent.com/librarylibrarian/misskey_auth/main/assets/demo_thumb.gif" alt="Demo" width="200" />
</p>

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

[Misskey](https://misskey-hub.net/) サーバーでの認証を行う Flutter ライブラリです。OAuth 2.0 と MiAuth の両方に対応し、複数アカウントのトークンを保存できます。

## 特徴

- Misskey サーバーの OAuth 2.0 認証（v2023.9.0 以降）
- 古いサーバー向けの MiAuth 認証
- 外部ブラウザでの認証（埋め込み WebView を使用しない）
- PKCE（Proof Key for Code Exchange）
- カスタム URL スキームによるアプリへのコールバック
- `flutter_secure_storage` を使用した安全なトークン保存
- 複数アカウントのトークン保存と、アクティブなアカウントの切り替え
- 認証の実行とトークンの保存を仲介する高レベル API `MisskeyAuthManager`
- iOS と Android

## 動作要件

- Flutter 3.47.1 以上、Dart 3.13.1 以上 4.0 未満
- Android API 24 以上、compileSdk 37 以上
- iOS 15 以上

以前のバージョンから更新する場合は、先に[更新時の注意](https://librarylibrarian.github.io/misskey_auth/ja/upgrading)を読んでください。Android では再度のサインインが必要です。

## インストール

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.2
```

## クイックスタート

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth（Misskey v2023.9.0 以降）
final oauthKey = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'yourscheme://oauth/callback',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);

// MiAuth（古いサーバーでも動作）
final miKey = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
  ),
  setActive: true,
);

// アクティブなアカウントの保存済みトークンを読み出す
final current = await auth.currentToken();
```

このコードを動かすには、次の2つが必要です。

1. **client_id ページ（OAuth のみ）。** `redirect_uri` を `<link rel="redirect_uri">` に記載した HTTPS のページを公開します。[client_id ページ](https://librarylibrarian.github.io/misskey_auth/ja/client-id-page)を参照してください。
2. **アプリへのカスタム URL スキームの登録。** iOS では `Info.plist` に、Android では `flutter_web_auth_2` の `CallbackActivity` に `yourscheme` を追加します。[プラットフォーム設定](https://librarylibrarian.github.io/misskey_auth/ja/platform-setup)を参照してください。

## ドキュメント

- ガイド: https://librarylibrarian.github.io/misskey_auth/ja/
  - [client_id ページ](https://librarylibrarian.github.io/misskey_auth/ja/client-id-page)
  - [プラットフォーム設定](https://librarylibrarian.github.io/misskey_auth/ja/platform-setup)
  - [OAuth と MiAuth](https://librarylibrarian.github.io/misskey_auth/ja/oauth-and-miauth)
  - [トークンの保存](https://librarylibrarian.github.io/misskey_auth/ja/token-storage)
  - [エラーハンドリング](https://librarylibrarian.github.io/misskey_auth/ja/error-handling)
  - [更新時の注意](https://librarylibrarian.github.io/misskey_auth/ja/upgrading)
- API リファレンス: https://pub.dev/documentation/misskey_auth/latest/
- 変更履歴: [CHANGELOG.md](CHANGELOG.md)
- Misskey のドキュメント: [OAuth](https://misskey-hub.net/ja/docs/for-developers/api/token/oauth/) / [MiAuth](https://misskey-hub.net/ja/docs/for-developers/api/token/miauth/)

## ライセンス

このプロジェクトは、司書（LibraryLibrarian）が 3-Clause BSD License の下で公開しています。詳細は [LICENSE](LICENSE) を参照してください。
