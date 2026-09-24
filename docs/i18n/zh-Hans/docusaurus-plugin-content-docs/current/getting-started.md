---
sidebar_position: 1
slug: /
title: 入门
---

# 入门

misskey_auth 是一个用于在 [Misskey](https://misskey-hub.net/en/) 服务器上进行身份验证的 Flutter 库。它同时支持 OAuth 2.0 和 MiAuth，并可保存多个账号的令牌。

## 功能特性

- 支持 Misskey 服务器的 OAuth 2.0 身份验证（v2023.9.0 及更高版本）
- 支持旧版服务器的 MiAuth 身份验证
- 在外部浏览器中进行身份验证（不使用嵌入式 WebView）
- PKCE（Proof Key for Code Exchange）
- 通过自定义 URL scheme 将回调发送到应用
- 使用 `flutter_secure_storage` 安全地存储令牌
- 保存多个账号的令牌，并切换当前活动账号
- 高级 API `MisskeyAuthManager`，用于执行身份验证并保存令牌
- iOS 和 Android

## 运行要求

- Flutter 3.47.1 或更高版本，Dart 3.13.1 或更高版本且低于 4.0
- Android API 24 或更高版本，compileSdk 37 或更高版本
- iOS 15 或更高版本

如果要从较早版本升级，请先阅读[升级说明](./upgrading.md)。在 Android 上，用户必须重新登录。

## 安装

将此软件包添加到 `pubspec.yaml`：

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
```

然后获取依赖：

```bash
flutter pub get
```

## 快速入门

身份验证分为三个步骤。

1. **发布 client_id 页面（仅适用于 OAuth）。** Misskey 会获取此 HTTPS 页面，以查找应用的 redirect URI。请参阅 [client_id 页面](./client-id-page.md)。
2. **在应用中注册自定义 URL scheme。** 浏览器通过此 scheme 返回应用。请参阅[平台配置](./platform-setup.md)。
3. **从 Dart 运行身份验证流程。**

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth（Misskey v2023.9.0 及更高版本）
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

// MiAuth（也适用于旧版服务器）
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

// 读取活动账号已保存的令牌
final current = await auth.currentToken();
print(current?.accessToken);
```

`MisskeyAuthManager` 使用 `SecureTokenStore` 保存每个令牌。如需自行管理令牌，请直接使用 `MisskeyOAuthClient` 或 `MisskeyMiAuthClient`。请参阅 [OAuth 和 MiAuth](./oauth-and-miauth.md)。

## 后续步骤

- [client_id 页面](./client-id-page.md)：Misskey 对 OAuth 所要求的页面
- [平台配置](./platform-setup.md)：iOS 和 Android 配置
- [OAuth 和 MiAuth](./oauth-and-miauth.md)：两种方式的区别，以及保存和不保存令牌的示例
- [令牌存储](./token-storage.md)：多个账号、`TokenStore` 和 `SecureTokenStore`
- [错误处理](./error-handling.md)：库抛出的异常
- [pub.dev API 参考](https://pub.dev/documentation/misskey_auth/latest/)

## 示例应用

仓库中包含一个示例应用，位于 [`example/`](https://github.com/LibraryLibrarian/misskey_auth/tree/main/example)。它使用发布在 `https://librarylibrarian.github.io/misskey_auth/example/` 的 client_id 页面。该页面仅用于试用示例；请为自己的应用发布专属的 client_id 页面。
