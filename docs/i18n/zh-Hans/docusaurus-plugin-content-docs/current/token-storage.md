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
await auth.signOut(key);  // 删除一个账号的令牌
await auth.signOutAll();  // 删除所有账号的令牌
```

退出登录只会删除设备上的令牌，不会在服务器上撤销令牌。

## 超时

`MisskeyAuthManager.defaultInstance()` 使用默认超时：连接为 10 秒，发送和接收各为 20 秒。如需更改，请自行构建 `MisskeyAuthManager`。`MisskeyAuthManager` 的超时仅适用于它自身对 `/api/i` 的请求，因此也要将超时传递给每个客户端：

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

各构造函数都接受 `connectTimeout`、`sendTimeout` 和 `receiveTimeout`。它们也接受 `dio`。客户端会将超时参数应用于传入的 `Dio`，但如果传入了 `dio`，`MisskeyAuthManager` 会忽略这些参数；此时请直接配置该 `Dio`。

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

`SecureTokenStore` 使用 `flutter_secure_storage` 保存令牌：iOS 上使用 Keychain，Android 上使用 Keystore。如需更改存储选项，请传入自行创建的 `FlutterSecureStorage`。misskey_auth 不会重新导出该类，因此请将 `flutter_secure_storage` 添加到依赖项并导入：

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

默认的 `SecureTokenStore` 使用默认存储命名空间，应用中的其他代码也可能使用该命名空间。`flutter_secure_storage` 11 默认启用 `resetOnError`，因此从存储错误中恢复时，也可能删除该命名空间中的其他值。如果应用在同一存储空间中保存了其他数据，请检查其配置。另请参阅 [flutter_secure_storage 更新日志](https://pub.dev/packages/flutter_secure_storage/changelog)。
