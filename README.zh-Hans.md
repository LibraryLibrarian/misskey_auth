[English](README.md) | [日本語](README.ja.md) | 简体中文 | [Deutsch](README.de.md) | [Français](README.fr.md) | [한국어](README.ko.md)

# misskey_auth

<p align="center">
  <img src="https://raw.githubusercontent.com/librarylibrarian/misskey_auth/main/assets/demo_thumb.gif" alt="Demo" width="200" />
</p>

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

这是一个用于在 [Misskey](https://misskey-hub.net/) 服务器上进行身份验证的 Flutter 库。它支持 OAuth 2.0 和 MiAuth，并可保存多个账户的令牌。

## 功能

- Misskey 服务器的 OAuth 2.0 身份验证（v2023.9.0 及更高版本）
- 面向旧版服务器的 MiAuth 身份验证
- 在外部浏览器中进行身份验证（不使用内嵌 WebView）
- PKCE（Proof Key for Code Exchange）
- 通过自定义 URL scheme 回调到应用
- 使用 `flutter_secure_storage` 安全保存令牌
- 保存多个账户的令牌并切换当前账户
- `MisskeyAuthManager` 高级 API，可执行认证流程并保存令牌
- iOS 和 Android

## 运行要求

- Flutter 3.47.1 或更高版本，Dart 3.13.1 或更高版本且低于 4.0
- Android API 24 或更高版本，compileSdk 37 或更高版本
- iOS 15 或更高版本

从旧版本升级时，请先阅读[升级注意事项](https://librarylibrarian.github.io/misskey_auth/zh-Hans/upgrading)。Android 用户需要重新登录。

## 安装

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
```

## 快速开始

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

// MiAuth（旧版服务器也可使用）
final miKey = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
  ),
  setActive: true,
);

// 读取当前账户已保存的令牌
final current = await auth.currentToken();
```

运行此代码前，需要完成以下两项设置。

1. **client_id 页面（仅 OAuth）。** 发布一个 HTTPS 页面，并在其中通过 `<link rel="redirect_uri">` 声明 `redirect_uri`。请参阅 [client_id 页面](https://librarylibrarian.github.io/misskey_auth/zh-Hans/client-id-page)。
2. **在应用中注册自定义 URL scheme。** 在 iOS 的 `Info.plist` 中，以及 Android 的 `flutter_web_auth_2` 的 `CallbackActivity` 中添加 `yourscheme`。请参阅[平台配置](https://librarylibrarian.github.io/misskey_auth/zh-Hans/platform-setup)。

## 文档

- 指南：https://librarylibrarian.github.io/misskey_auth/zh-Hans/
  - [client_id 页面](https://librarylibrarian.github.io/misskey_auth/zh-Hans/client-id-page)
  - [平台配置](https://librarylibrarian.github.io/misskey_auth/zh-Hans/platform-setup)
  - [OAuth 和 MiAuth](https://librarylibrarian.github.io/misskey_auth/zh-Hans/oauth-and-miauth)
  - [令牌保存](https://librarylibrarian.github.io/misskey_auth/zh-Hans/token-storage)
  - [错误处理](https://librarylibrarian.github.io/misskey_auth/zh-Hans/error-handling)
  - [升级注意事项](https://librarylibrarian.github.io/misskey_auth/zh-Hans/upgrading)
- API 参考：https://pub.dev/documentation/misskey_auth/latest/
- 更新日志：[CHANGELOG.md](CHANGELOG.md)
- Misskey 文档：[OAuth](https://misskey-hub.net/en/docs/for-developers/api/token/oauth/) / [MiAuth](https://misskey-hub.net/en/docs/for-developers/api/token/miauth/)

## 许可证

本项目由司書（LibraryLibrarian）以 3-Clause BSD License 发布。详情请参阅 [LICENSE](LICENSE)。
