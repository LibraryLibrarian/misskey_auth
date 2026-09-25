---
sidebar_position: 1
slug: /
title: はじめに
---

# はじめに

misskey_auth は、[Misskey](https://misskey-hub.net/) サーバーでの認証を行う Flutter ライブラリです。OAuth 2.0 と MiAuth の両方に対応し、複数アカウントのトークンを保存できます。

## 特徴

- Misskey サーバーの OAuth 2.0 認証（v2023.9.0 以降）
- 古いサーバー向けの MiAuth 認証
- 外部ブラウザでの認証（埋め込み WebView を使用しない）
- PKCE（Proof Key for Code Exchange）
- カスタム URL スキームによるアプリへのコールバック
- `flutter_secure_storage` を使用した安全なトークン保存
- 複数アカウントのトークン保存と、アクティブなアカウントの切り替え
- 認証を実行してトークンを保存する高レベル API `MisskeyAuthManager`
- iOS と Android

## 動作要件

- Flutter 3.47.1 以上、Dart 3.13.1 以上 4.0 未満
- Android API 24 以上、compileSdk 37 以上
- iOS 15 以上

以前のバージョンから更新する場合は、先に[更新時の注意](./upgrading.md)を読んでください。Android では再度のサインインが必要です。

## インストール

`pubspec.yaml` にパッケージを追加します。

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
```

続けて取得します。

```bash
flutter pub get
```

## クイックスタート

認証は3つの手順で行います。

1. **client_id ページを公開する（OAuth のみ）。** Misskey はこの HTTPS のページを取得して、アプリの redirect URI を確認します。[client_id ページ](./client-id-page.md)を参照してください。
2. **アプリにカスタム URL スキームを登録する。** ブラウザはこのスキームでアプリに戻ります。[プラットフォーム設定](./platform-setup.md)を参照してください。
3. **Dart から認証を実行する。**

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
    iconUrl: 'https://example.com/icon.png',
  ),
  setActive: true,
);

// アクティブなアカウントの保存済みトークンを読み出す
final current = await auth.currentToken();
print(current?.accessToken);
```

`MisskeyAuthManager` は各トークンを `SecureTokenStore` で保存します。トークンを自分で管理する場合は、`MisskeyOAuthClient` または `MisskeyMiAuthClient` を直接使います。[OAuth と MiAuth](./oauth-and-miauth.md) を参照してください。

## 次に読むページ

- [client_id ページ](./client-id-page.md): OAuth で Misskey が求めるページ
- [プラットフォーム設定](./platform-setup.md): iOS と Android の設定
- [OAuth と MiAuth](./oauth-and-miauth.md): 2つの方式の違いと、トークンを保存する場合・しない場合の例
- [トークンの保存](./token-storage.md): 複数アカウント、`TokenStore`、`SecureTokenStore`
- [エラーハンドリング](./error-handling.md): ライブラリが投げる例外
- [pub.dev の API リファレンス](https://pub.dev/documentation/misskey_auth/latest/)

## example アプリ

リポジトリの [`example/`](https://github.com/LibraryLibrarian/misskey_auth/tree/main/example) に example アプリがあります。このアプリは `https://librarylibrarian.github.io/misskey_auth/example/` で公開している client_id ページを使います。このページは example を試すためだけに使い、自分のアプリには自分の client_id ページを公開してください。
