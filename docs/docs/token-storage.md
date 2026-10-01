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
await auth.signOut(key);  // Revokes and deletes the token of one account
await auth.signOutAll();  // Revokes and deletes the tokens of all accounts
```

## Signing Out

Signing out revokes the token on the server and then deletes it from the device. Revocation requires Misskey 2026.9.0 or later, which lets an app token revoke itself through `/api/i/revoke-token`. It works for MiAuth and OAuth tokens, whatever their permissions.

```dart
final result = await auth.signOut(key);
final revocation = result.revocation;
if (revocation == null) {
  // Revocation was not attempted. See result.skipReason.
} else if (revocation.isInvalidated) {
  // revoked or alreadyInvalid: the token can no longer be used on the server.
} else if (revocation.status == TokenRevocationStatus.unsupported) {
  // The server is older than 2026.9.0. The token stays valid there.
} else {
  // failed: network error, timeout, or an unexpected response.
}
```

### Modes

Pass `mode` to choose what happens to the token on the device:

| `SignOutMode` | Revokes | Deletes from the device |
|---|---|---|
| `revokeAndDelete` (default) | Yes | Always, whatever the revocation result |
| `revokeOrKeep` | Yes | Only when the result is `revoked` or `alreadyInvalid` |
| `localOnly` | No | Always |

With `revokeOrKeep`, a token that could not be revoked stays saved, so the user can try again later. A server that does not support revocation always returns `unsupported`, and an account that the server refuses for another reason, such as a suspended one, may fail every time. To remove such accounts from the device, sign out again with `SignOutMode.localOnly`.

If the token is not stored or cannot be read, for example because the stored data is corrupted, it is deleted in every mode without revocation.

### Results

`signOut` returns a `SignOutResult`, and `signOutAll` returns one for each account in the order of `listAccounts`:

| Field | Meaning |
|---|---|
| `key` | The account |
| `revocation` | The `TokenRevocationResult`, or `null` if revocation was not attempted |
| `skipReason` | Why revocation was not attempted: `localOnly`, `noStoredToken`, or `unreadableToken`. `null` if it was attempted |
| `deleted` | Whether the token was deleted from the device |

`TokenRevocationResult` has:

| Field | Meaning |
|---|---|
| `status` | `revoked`, `alreadyInvalid`, `unsupported`, or `failed` |
| `isInvalidated` | `true` for `revoked` and `alreadyInvalid` |
| `statusCode` | The HTTP status, or `null` if no response was received |
| `errorCode` | The Misskey error code, such as `RATE_LIMIT_EXCEEDED`, if any |
| `error` | The cause for `unsupported` and `failed`: usually `TokenRevocationException` for an error or unexpected response, and `NetworkException` for a network error or timeout |

`alreadyInvalid` means that the server did not recognize the token: it was already revoked, or the account was deleted. It is treated like `revoked`.

Revocation failures are reported in the result and never thrown. Errors from deleting the token on the device are thrown as before; `signOutAll` tries to delete every account first and then throws the first error.

`deleted` is `false` in two cases: `revokeOrKeep` kept the token, or a new token was saved for the same account while revocation was in progress, for example because the user signed in again. The new token is not deleted, because it was never revoked.

### Timeout and Retries

Revocation is not retried. Without a `timeout`, a request that does not respond waits for the request timeouts (see [Timeouts](#timeouts)). Pass `timeout` to limit it:

```dart
await auth.signOut(key, timeout: const Duration(seconds: 5));
await auth.signOutAll(timeout: const Duration(seconds: 5));
```

`signOutAll` revokes all accounts in parallel, and all requests share one deadline counted from the call. Reading and deleting stored tokens is not cut off by the timeout. A request that runs out of time is reported as `failed`. The server may still have revoked the token: if the token was kept, for example by `revokeOrKeep`, revoking it again reports `alreadyInvalid`.

### Revoking Without the Manager

If you store tokens yourself, use `MisskeyTokenRevocationClient` directly. It revokes the token on the server and does not touch any storage:

```dart
final revocation = MisskeyTokenRevocationClient();
final result = await revocation.revoke(
  host: 'misskey.io',
  accessToken: token,
  timeout: const Duration(seconds: 5),
);
if (result.isInvalidated) {
  // Delete the token from your storage.
}
```

`revoke` never throws and returns the same `TokenRevocationResult`. The client sends the token in the request body. If you pass your own `Dio`, its interceptors can see the token, so do not log request bodies.

## Timeouts

`MisskeyAuthManager.defaultInstance()` uses the default timeouts: 10 seconds to connect, and 20 seconds each to send and receive. To change them, build the manager yourself. The timeouts of the manager apply to its own requests, `/api/i` and token revocation, so pass them to each client as well:

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

The constructors accept `connectTimeout`, `sendTimeout`, and `receiveTimeout`. They also accept a `dio`. `MisskeyOAuthClient` and `MisskeyMiAuthClient` apply the timeout arguments to a `Dio` that you pass. `MisskeyTokenRevocationClient` applies them only to its own requests and leaves that `Dio` unchanged. `MisskeyAuthManager` ignores them when `dio` is given; configure that `Dio` directly. To use a different revocation client, pass it as `revocation`.

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

`SecureTokenStore` saves tokens with `flutter_secure_storage`: the Keychain on iOS and macOS, and the Keystore on Android. To change the storage options, pass your own `FlutterSecureStorage`. misskey_auth does not re-export it, so add `flutter_secure_storage` to your dependencies and import it:

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
