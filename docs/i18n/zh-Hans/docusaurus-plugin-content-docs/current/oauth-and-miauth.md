---
sidebar_position: 4
title: OAuth 和 MiAuth
---

# OAuth 和 MiAuth

Misskey 为应用获取访问令牌提供了两种方式。

| | OAuth 2.0 | MiAuth |
|---|---|---|
| 支持的服务器 | Misskey v2023.9.0 及更高版本 | 也包括旧版服务器 |
| client_id 页面 | 必需（HTTPS） | 不需要 |
| 浏览器返回的位置 | client_id 页面中列出的 `redirect_uri` | `yourscheme://`（仅 scheme） |
| 配置类 | `MisskeyOAuthConfig` | `MisskeyMiAuthConfig` |

两种方式都会打开外部浏览器，并通过自定义 URL scheme 返回应用，因此都需要进行[平台配置](./platform-setup.md)。

要检查服务器是否支持 OAuth，请调用 `MisskeyOAuthClient().getOAuthServerInfo(host)`。如果服务器不支持 OAuth，该方法会返回 `null`。此时 `authenticate` 和 `loginWithOAuth` 会抛出 `OAuthNotSupportedException`，因此可以切换到 MiAuth。

## 配置

### `MisskeyOAuthConfig`

| 参数 | 说明 |
|---|---|
| `host` | Misskey 服务器主机，例如 `misskey.io` |
| `clientId` | [client_id 页面](./client-id-page.md)的 URL |
| `redirectUri` | client_id 页面中列出的 redirect URI，例如 `yourscheme://oauth/callback` |
| `scope` | 以空格分隔的作用域，例如 `read:account write:notes` |
| `callbackScheme` | 应用的自定义 scheme。必需，但仅当 `redirectUri` 是 `http(s)` 中继页面时才会使用；其他情况下使用 `redirectUri` 的 scheme |

### `MisskeyMiAuthConfig`

| 参数 | 说明 |
|---|---|
| `host` | Misskey 服务器主机 |
| `appName` | 显示给用户的应用名称 |
| `callbackScheme` | 应用的自定义 scheme。Misskey 会将浏览器重定向到 `yourscheme://` |
| `permissions` | 请求的权限，例如 `['read:account', 'write:notes']`。可选 |
| `iconUrl` | 显示给用户的应用图标 URL。可选 |

## 不保存令牌

`MisskeyOAuthClient` 和 `MisskeyMiAuthClient` 会执行身份验证流程并返回令牌，但不会保存令牌。

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
    iconUrl: 'https://example.com/icon.png', // 可选
  ),
);
print(result.token);
print(result.user); // 如果服务器返回，则为用户信息
```

## 保存令牌

`MisskeyAuthManager` 会执行身份验证流程，并通过 `TokenStore` 保存令牌。`MisskeyAuthManager.defaultInstance()` 使用 `SecureTokenStore`。每次登录都会返回用于标识账号的 `AccountKey`。

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

OAuth 身份验证完成后，manager 会使用新令牌调用 `/api/i` 以获取账号 ID。

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
  setActive: true, // 同时将此账号设为活动账号
);
final current = await auth.currentToken();
```

MiAuth 会随令牌一起返回用户信息，因此 manager 会使用其中的 `id` 作为账号 ID。

## 在同一个应用中支持两种方式

- 在 `Info.plist` 和 `AndroidManifest.xml` 中注册一个 scheme（例如 `yourscheme`），即可供 OAuth 和 MiAuth 共用。
- MiAuth 仅回调到 scheme（`yourscheme://`）。MiAuth 不需要类似 `yourscheme://oauth/callback` 的路径。
- 在 Android 上，请使用[平台配置](./platform-setup.md#android)中的仅指定 scheme 的 intent-filter。通过 host 或 path 限定的过滤器会阻止 MiAuth 回调到达应用。

## 另请参阅

- [Misskey OAuth 文档（英文）](https://misskey-hub.net/en/docs/for-developers/api/token/oauth/)
- [Misskey MiAuth 文档（英文）](https://misskey-hub.net/en/docs/for-developers/api/token/miauth/)
