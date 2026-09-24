---
sidebar_position: 4
title: OAuth and MiAuth
---

# OAuth and MiAuth

Misskey offers two ways for an app to get an access token.

| | OAuth 2.0 | MiAuth |
|---|---|---|
| Servers | Misskey v2023.9.0 and later | Older servers too |
| client_id page | Required (HTTPS) | Not needed |
| Where the browser returns | The `redirect_uri` listed on the client_id page | `yourscheme://` (scheme only) |
| Configuration | `MisskeyOAuthConfig` | `MisskeyMiAuthConfig` |

Both methods open the external browser and return to the app through a custom URL scheme, so both need the [platform setup](./platform-setup.md).

To check whether a server supports OAuth, call `MisskeyOAuthClient().getOAuthServerInfo(host)`. It returns `null` when the server does not support OAuth. `authenticate` and `loginWithOAuth` throw `OAuthNotSupportedException` in that case, so you can fall back to MiAuth.

## Configuration

### `MisskeyOAuthConfig`

| Parameter | Description |
|---|---|
| `host` | Misskey server host, such as `misskey.io` |
| `clientId` | URL of your [client_id page](./client-id-page.md) |
| `redirectUri` | A redirect URI listed on the client_id page, such as `yourscheme://oauth/callback` |
| `scope` | Space-separated scopes, such as `read:account write:notes` |
| `callbackScheme` | Your app's custom scheme. Required, but used only when `redirectUri` is an `http(s)` relay page; otherwise the scheme of `redirectUri` is used |

### `MisskeyMiAuthConfig`

| Parameter | Description |
|---|---|
| `host` | Misskey server host |
| `appName` | App name shown to the user |
| `callbackScheme` | Your app's custom scheme. Misskey redirects the browser to `yourscheme://` |
| `permissions` | Requested permissions, such as `['read:account', 'write:notes']`. Optional |
| `iconUrl` | URL of the app icon shown to the user. Optional |

## Without Saving Tokens

`MisskeyOAuthClient` and `MisskeyMiAuthClient` run the flow and return the token. They do not save it.

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
    iconUrl: 'https://example.com/icon.png', // Optional
  ),
);
print(result.token);
print(result.user); // User information, if the server returns it
```

## With Saving Tokens

`MisskeyAuthManager` runs the flow and saves the token with a `TokenStore`. `MisskeyAuthManager.defaultInstance()` uses `SecureTokenStore`. Each login returns an `AccountKey` that identifies the account.

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

After OAuth, the manager calls `/api/i` with the new token to find the account ID.

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
  setActive: true, // Also make this the active account
);
final current = await auth.currentToken();
```

MiAuth returns user information together with the token, and the manager uses its `id` as the account ID.

## Supporting Both Methods in One App

- Register one scheme, such as `yourscheme`, in `Info.plist` and `AndroidManifest.xml`. OAuth and MiAuth can share it.
- MiAuth calls back to the scheme only (`yourscheme://`). You do not need a path such as `yourscheme://oauth/callback` for MiAuth.
- On Android, keep the scheme-only intent-filter from [Platform Setup](./platform-setup.md#android). A filter restricted by host or path stops MiAuth callbacks from reaching the app.

## See Also

- [Misskey OAuth documentation](https://misskey-hub.net/en/docs/for-developers/api/token/oauth/)
- [Misskey MiAuth documentation](https://misskey-hub.net/en/docs/for-developers/api/token/miauth/)
