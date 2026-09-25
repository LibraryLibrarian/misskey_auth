---
sidebar_position: 6
title: 错误处理
---

# 错误处理

身份验证 API 会抛出 `MisskeyAuthException` 的子类。请捕获需要单独处理的具体类型，其余异常则由 `MisskeyAuthException` 捕获。

```dart
import 'dart:developer';

try {
  await auth.loginWithOAuth(config);
} on UserCancelledException {
  // 用户关闭了浏览器。通常无需报告。
} on OAuthNotSupportedException {
  // 服务器不支持 OAuth。改用 MiAuth。
} on NetworkException catch (e) {
  // 超时、无连接、TLS 错误等。
  log('Network error', error: e.originalException);
} on MisskeyAuthException catch (e) {
  log('Authentication failed: ${e.message} ${e.details ?? ''}');
}
```

每个异常都包含以下属性：

- `message`：简短说明
- `details`：补充信息（如果有）
- `originalException`：底层异常（如果有）

`message` 和 `details` 用于日志，其中一些消息为日语。请根据异常类型，在应用中向用户显示自定义文本。

## 异常

### 通用

| 异常 | 抛出条件 |
|---|---|
| `UserCancelledException` | 用户关闭了浏览器或取消了身份验证。另请参阅[平台配置](./platform-setup.md) |
| `CallbackSchemeErrorException` | 平台错误消息提及回调，通常意味着回调 URL scheme 未注册或不匹配 |
| `AuthorizationLaunchException` | 无法打开浏览器，或平台报告了其他错误 |
| `NetworkException` | 请求失败且未收到响应：超时、无连接、TLS 错误等。`loginWithOAuth` 在 `/api/i` 返回错误状态时也会抛出此异常 |
| `ResponseParseException` | 响应不是预期的 JSON，或缺少必需字段，例如令牌或用户 `id` |
| `MisskeyAuthException` | 意外错误。以上及以下所有异常的基类 |

### OAuth

| 异常 | 抛出条件 |
|---|---|
| `OAuthNotSupportedException` | 服务器不支持 OAuth（`/.well-known/oauth-authorization-server` 返回了 404 或 501） |
| `ServerInfoException` | 获取服务器信息时返回了 404 或 501 以外的错误状态、其 `issuer` 与 `https://{host}` 不完全匹配，或其授权端点或令牌端点不是 HTTPS 绝对 URL。与 `OAuthNotSupportedException` 不同，这并不意味着应该切换到 MiAuth |
| `StateMismatchException` | 回调中的 `state` 缺失或与请求不匹配 |
| `AuthorizationServerErrorException` | 回调中包含 `error`，例如用户拒绝访问时的 `access_denied`。`details` 中包含 `error` 和 `error_description` |
| `AuthorizationCodeMissingException` | 回调中没有授权码，或包含多个授权码 |
| `TokenExchangeException` | 令牌端点返回了错误。消息包含 HTTP 状态和服务器返回的错误 |

### MiAuth

| 异常 | 抛出条件 |
|---|---|
| `MiAuthDeniedException` | 检查 API 返回 `ok: false`。用户可能拒绝了访问，但 Misskey 也会对未知或已使用过的会话返回此值 |
| `MiAuthSessionInvalidException` | 回调属于另一个会话，或检查 API 返回了 404 或 410 |
| `MiAuthCheckFailedException` | 检查 API 返回了其他错误状态 |

### 当前版本不会抛出的异常

`InvalidAuthConfigException`、`SecureStorageException` 和 `MiAuthNotSupportedException` 已定义，但当前版本不会抛出。

## 存储错误

`SecureTokenStore` 不会包装 `flutter_secure_storage` 的错误。错误会以该软件包抛出的形式传递到调用代码，通常为 `PlatformException`。如果存储的数据已损坏，读取时也可能抛出 `FormatException` 或 `TypeError`。请在调用会读取或写入令牌的 `MisskeyAuthManager` 方法时处理这些错误，这也包括身份验证后保存令牌的 `loginWithOAuth` 和 `loginWithMiAuth`。

`loginWithOAuth` 和 `loginWithMiAuth` 会先保存令牌，再将账号设为活动账号。如果仅将账号设为活动账号这一步失败，令牌仍会保存，但账号不会成为活动账号。

## 重试

- 获取 OAuth 服务器信息和调用 `/api/i` 时，如果发生超时、连接错误、其他传输错误，或 HTTP 429、500、502、503、504 状态，会重试，总计最多尝试三次。
- 令牌交换和 MiAuth 检查 API 不会重试。授权码和 MiAuth 会话都只能使用一次，即使响应丢失，服务器也可能已完成请求。请从头重新进行身份验证。

## 身份验证后登录失败时

`loginWithOAuth` 获取令牌后会调用 `/api/i`。如果该调用失败，方法会抛出异常且不会保存令牌。如果用户信息中没有 `id`，`loginWithOAuth` 和 `loginWithMiAuth` 也会抛出异常且不会保存令牌。

在这些情况下，服务器已经签发令牌，该令牌在服务器上仍然有效；库不会撤销令牌。用户可以重新登录，此时会签发新令牌。
