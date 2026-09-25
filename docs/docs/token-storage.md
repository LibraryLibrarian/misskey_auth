---
sidebar_position: 5
title: Token Storage
---

# Token Storage

`MisskeyAuthManager` saves tokens for multiple accounts and tracks which one is active. It stores them through the `TokenStore` interface. The default implementation is `SecureTokenStore`.

## Managing Accounts

```dart
final auth = MisskeyAuthManager.defaultInstance();

// Tokens
final current = await auth.currentToken();  // Active account, or null
final specific = await auth.tokenOf(key);   // A specific account, or null

// Accounts
final accounts = await auth.listAccounts();
await auth.setActive(key);
final active = await auth.getActive();
await auth.clearActive();

// Sign out
await auth.signOut(key);  // Deletes the token of one account
await auth.signOutAll();  // Deletes the tokens of all accounts
```

Signing out deletes the token from the device only. It does not revoke the token on the server.

## Timeouts

`MisskeyAuthManager.defaultInstance()` uses the default timeouts: 10 seconds to connect, and 20 seconds each to send and receive. To change them, build the manager yourself. The timeouts of the manager apply only to its own request to `/api/i`, so pass them to each client as well:

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

The constructors accept `connectTimeout`, `sendTimeout`, and `receiveTimeout`. They also accept a `dio`. The clients apply the timeout arguments to a `Dio` that you pass, but `MisskeyAuthManager` ignores them when `dio` is given; configure that `Dio` directly.

## Models

```dart
class AccountKey {
  final String host;       // e.g. 'misskey.io'
  final String accountId;  // The user ID on that server
}

class StoredToken {
  final String accessToken;
  final String tokenType;  // 'MiAuth' or 'OAuth'
  final String? scope;     // OAuth only
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
}

class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;
}
```

`AccountKey` combines the host and the user ID, because a user ID is unique only within one server. The host is stored exactly as you pass it in the config, so always use the same form for a server, for example lowercase `misskey.io`. Saving a token for an existing `AccountKey` replaces the old one.

## `TokenStore`

To store tokens somewhere else, implement `TokenStore` and pass it to `MisskeyAuthManager`:

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

`SecureTokenStore` saves tokens with `flutter_secure_storage`: the Keychain on iOS and the Keystore on Android. To change the storage options, pass your own `FlutterSecureStorage`. misskey_auth does not re-export it, so add `flutter_secure_storage` to your dependencies and import it:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const store = SecureTokenStore(
  storage: FlutterSecureStorage(/* your options */),
);
```

### Concurrency

- Write operations (`upsert`, `delete`, `clearAll`, `setActive`) run one at a time within an isolate, including across instances. Concurrent writes do not lose accounts from the index.
- Reads are not blocked, and a sequence such as `upsert` followed by `setActive` is not atomic.
- Writes from other isolates or processes are not coordinated.

### What `clearAll` Deletes

`clearAll` deletes the accounts listed in the store's index, the index itself, and the active account. It does not enumerate the whole storage, because on Android `readAll` can wipe the entire storage when a single entry fails to decrypt. Tokens left without an index entry by earlier versions are therefore not removed.

### Shared Storage

The default `SecureTokenStore` uses the default storage namespace, which other code in your app may also use. `flutter_secure_storage` 11 enables `resetOnError` by default, so recovering from a storage error can also delete other values in that namespace. If your app keeps other data in the same storage, review its configuration. See the [flutter_secure_storage changelog](https://pub.dev/packages/flutter_secure_storage/changelog).
