---
sidebar_position: 5
title: 令牌存储
---

# 令牌存储

`MisskeyAuthManager` 会保存多个账号的令牌，并跟踪当前活动账号。令牌通过 `TokenStore` 接口存储，默认实现为 `SecureTokenStore`。

## 管理账号

```dart
final auth = MisskeyAuthManager.defaultInstance();

// 令牌
final current = await auth.currentToken();  // 活动账号；如果没有则为 null
final specific = await auth.tokenOf(key);   // 指定账号；如果没有则为 null

// 账号
final accounts = await auth.listAccounts();
await auth.setActive(key);
final active = await auth.getActive();
await auth.clearActive();

// 退出登录
await auth.signOut(key);  // 撤销并删除一个账号的令牌
await auth.signOutAll();  // 撤销并删除所有账号的令牌
```

## 退出登录 {#signing-out}

退出登录时，会先在服务器上撤销令牌，然后将其从设备上删除。撤销需要 Misskey 2026.9.0 或更高版本，该版本允许应用令牌通过 `/api/i/revoke-token` 撤销自身。无论权限如何，MiAuth 令牌和 OAuth 令牌都可以撤销。

```dart
final result = await auth.signOut(key);
final revocation = result.revocation;
if (revocation == null) {
  // 未尝试撤销。请参阅 result.skipReason。
} else if (revocation.isInvalidated) {
  // revoked 或 alreadyInvalid：该令牌已无法在服务器上使用。
} else if (revocation.status == TokenRevocationStatus.unsupported) {
  // 服务器版本低于 2026.9.0。令牌在服务器上仍然有效。
} else {
  // failed：网络错误、超时或意外的响应。
}
```

### 模式

传入 `mode` 可选择如何处理设备上的令牌：

| `SignOutMode` | 撤销 | 从设备删除 |
|---|---|---|
| `revokeAndDelete`（默认） | 是 | 始终删除，无论撤销结果如何 |
| `revokeOrKeep` | 是 | 仅当结果为 `revoked` 或 `alreadyInvalid` 时 |
| `localOnly` | 否 | 始终删除 |

使用 `revokeOrKeep` 时，无法撤销的令牌会保留在存储中，以便用户稍后重试。不支持撤销的服务器始终返回 `unsupported`；因其他原因被服务器拒绝的账号（例如已被冻结的账号）可能每次都会失败。要从设备上移除此类账号，请使用 `SignOutMode.localOnly` 再次退出登录。

如果令牌未保存或无法读取（例如存储的数据已损坏），则无论使用哪种模式，都会直接删除，不进行撤销。

### 结果

`signOut` 返回一个 `SignOutResult`，`signOutAll` 按 `listAccounts` 的顺序为每个账号返回一个 `SignOutResult`：

| 字段 | 含义 |
|---|---|
| `key` | 对应的账号 |
| `revocation` | `TokenRevocationResult`；如果未尝试撤销，则为 `null` |
| `skipReason` | 未尝试撤销的原因：`localOnly`、`noStoredToken` 或 `unreadableToken`。如果已尝试撤销，则为 `null` |
| `deleted` | 令牌是否已从设备上删除 |

`TokenRevocationResult` 包含以下字段：

| 字段 | 含义 |
|---|---|
| `status` | `revoked`、`alreadyInvalid`、`unsupported` 或 `failed` |
| `isInvalidated` | 结果为 `revoked` 和 `alreadyInvalid` 时为 `true` |
| `statusCode` | HTTP 状态；如果未收到响应，则为 `null` |
| `errorCode` | Misskey 错误代码（如果有），例如 `RATE_LIMIT_EXCEEDED` |
| `error` | `unsupported` 和 `failed` 的原因：通常错误响应或意外响应为 `TokenRevocationException`，网络错误或超时为 `NetworkException` |

`alreadyInvalid` 表示服务器无法识别该令牌：令牌已被撤销，或账号已被删除。它与 `revoked` 同等对待。

撤销失败会在结果中报告，绝不会抛出异常。删除设备上的令牌时发生的错误仍会像以前一样抛出；`signOutAll` 会先尝试删除所有账号，然后抛出第一个错误。

`deleted` 在两种情况下为 `false`：`revokeOrKeep` 保留了令牌；或者在撤销过程中，同一账号保存了新令牌，例如用户再次登录。新令牌从未被撤销，因此不会被删除。

### 超时与重试 {#timeout-and-retries}

撤销不会重试。如果未指定 `timeout`，无响应的请求会一直等待，直到达到请求超时（请参阅[超时](#timeouts)）。传入 `timeout` 可限制等待时间：

```dart
await auth.signOut(key, timeout: const Duration(seconds: 5));
await auth.signOutAll(timeout: const Duration(seconds: 5));
```

`signOutAll` 会并行撤销所有账号，所有请求共享一个从调用时开始计算的期限。读取和删除已保存的令牌不会因超时而中断。超时的请求会报告为 `failed`。服务器可能仍已撤销该令牌：如果令牌被保留（例如使用 `revokeOrKeep`），再次撤销会报告 `alreadyInvalid`。

### 不通过管理器撤销

如果自行存储令牌，请直接使用 `MisskeyTokenRevocationClient`。它只在服务器上撤销令牌，不会操作任何存储：

```dart
final revocation = MisskeyTokenRevocationClient();
final result = await revocation.revoke(
  host: 'misskey.io',
  accessToken: token,
  timeout: const Duration(seconds: 5),
);
if (result.isInvalidated) {
  // 从自己的存储中删除该令牌。
}
```

`revoke` 绝不会抛出异常，并返回相同的 `TokenRevocationResult`。客户端会在请求体中发送令牌。如果传入自己的 `Dio`，其拦截器可以看到令牌，因此请勿记录请求体。

## 超时 {#timeouts}

`MisskeyAuthManager.defaultInstance()` 使用默认超时：连接为 10 秒，发送和接收各为 20 秒。如需更改，请自行构建 `MisskeyAuthManager`。`MisskeyAuthManager` 的超时适用于它自身的请求，即 `/api/i` 和令牌撤销，因此也要将超时传递给每个客户端：

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

各构造函数都接受 `connectTimeout`、`sendTimeout` 和 `receiveTimeout`。它们也接受 `dio`。`MisskeyOAuthClient` 和 `MisskeyMiAuthClient` 会将超时参数应用于传入的 `Dio`。`MisskeyTokenRevocationClient` 仅将这些参数应用于自身的请求，不会修改传入的 `Dio`。如果传入了 `dio`，`MisskeyAuthManager` 会忽略这些参数；此时请直接配置该 `Dio`。如需使用其他撤销客户端，请通过 `revocation` 传入。

## 模型

```dart
class AccountKey {
  final String host;       // 例如：'misskey.io'
  final String accountId;  // 该服务器上的用户 ID
}

class StoredToken {
  final String accessToken;
  final String tokenType;  // 'MiAuth' 或 'OAuth'
  final String? scope;     // 仅 OAuth
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
}

class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;
}
```

由于用户 ID 只在单个服务器内唯一，`AccountKey` 将主机和用户 ID 组合在一起。主机会按配置中传入的原样保存，因此对同一服务器始终使用相同的写法，例如小写的 `misskey.io`。如果向已有的 `AccountKey` 保存令牌，会替换旧令牌。

## `TokenStore`

如需将令牌存储到其他位置，请实现 `TokenStore` 并将其传递给 `MisskeyAuthManager`：

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

## `SecureTokenStore`

`SecureTokenStore` 使用 `flutter_secure_storage` 保存令牌：iOS 和 macOS 上使用 Keychain，Android 上使用 Keystore。如需更改存储选项，请传入自行创建的 `FlutterSecureStorage`。misskey_auth 不会重新导出该类，因此请将 `flutter_secure_storage` 添加到依赖项并导入：

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const store = SecureTokenStore(
  storage: FlutterSecureStorage(/* 自定义选项 */),
);
```

### 并发

- 写入操作（`upsert`、`delete`、`clearAll`、`setActive`）在同一个 isolate 内按顺序执行，即使实例不同也一样。并发写入不会导致索引中的账号丢失。
- 读取不会被阻塞。此外，`upsert` 后接 `setActive` 这样的操作序列不是原子操作。
- 不会与来自其他 isolate 或进程的写入进行互斥控制。

### `clearAll` 会删除什么

`clearAll` 会删除存储索引中列出的账号、索引本身以及活动账号。它不会枚举整个存储空间，因为在 Android 上，只要有一条记录解密失败，`readAll` 就可能清除整个存储空间。因此，早期版本留下的、未记录在索引中的令牌不会被删除。

### 共享存储空间 {#shared-storage}

默认的 `SecureTokenStore` 使用默认存储空间，应用中的其他代码也可能使用该存储空间。`flutter_secure_storage` 11 默认启用 `resetOnError`，因此从存储错误中恢复时，也可能删除该存储空间中的其他值。如果应用在同一存储空间中保存了其他数据，请检查其配置。另请参阅 [flutter_secure_storage 更新日志](https://pub.dev/packages/flutter_secure_storage/changelog)。
