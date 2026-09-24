---
sidebar_position: 6
title: Error Handling
---

# Error Handling

The authentication APIs throw subclasses of `MisskeyAuthException`. Catch the specific types you want to handle, and `MisskeyAuthException` for the rest.

```dart
import 'dart:developer';

try {
  await auth.loginWithOAuth(config);
} on UserCancelledException {
  // The user closed the browser. Usually nothing to report.
} on OAuthNotSupportedException {
  // The server does not support OAuth. Try MiAuth instead.
} on NetworkException catch (e) {
  // Timeout, no connection, TLS error, and so on.
  log('Network error', error: e.originalException);
} on MisskeyAuthException catch (e) {
  log('Authentication failed: ${e.message} ${e.details ?? ''}');
}
```

Each exception has:

- `message`: a short description
- `details`: extra information, if any
- `originalException`: the underlying exception, if any

`message` and `details` are meant for logs. Some messages are in Japanese. Show your own text to users based on the exception type.

## Exceptions

### Common

| Exception | Thrown when |
|---|---|
| `UserCancelledException` | The user closed the browser or cancelled authentication. See also [Platform Setup](./platform-setup.md) |
| `CallbackSchemeErrorException` | The platform error message mentions the callback, which usually means that the callback URL scheme is not registered or does not match |
| `AuthorizationLaunchException` | The browser could not be opened, or the platform reported another error |
| `NetworkException` | A request failed without a response: timeout, no connection, TLS error, and so on. `loginWithOAuth` also throws it when `/api/i` returns an error status |
| `ResponseParseException` | A response was not the expected JSON, or a required field, such as the token or the user `id`, was missing |
| `MisskeyAuthException` | An unexpected error. The base class of all the exceptions above and below |

### OAuth

| Exception | Thrown when |
|---|---|
| `OAuthNotSupportedException` | The server does not support OAuth (`/.well-known/oauth-authorization-server` returned 404 or 501) |
| `ServerInfoException` | The server information request returned an error status other than 404 or 501, its `issuer` is not exactly `https://{host}`, or its authorization or token endpoint is not an absolute HTTPS URL. Unlike `OAuthNotSupportedException`, this does not mean that you should fall back to MiAuth |
| `StateMismatchException` | The `state` in the callback is missing or does not match the request |
| `AuthorizationServerErrorException` | The callback contains an `error`, for example `access_denied` when the user denies access. `details` contains `error` and `error_description` |
| `AuthorizationCodeMissingException` | The callback contains no authorization code, or more than one |
| `TokenExchangeException` | The token endpoint returned an error. The message contains the HTTP status and the error from the server |

### MiAuth

| Exception | Thrown when |
|---|---|
| `MiAuthDeniedException` | The check API returned `ok: false`. The user may have denied access, but Misskey also returns this for an unknown or already used session |
| `MiAuthSessionInvalidException` | The callback is for a different session, or the check API returned 404 or 410 |
| `MiAuthCheckFailedException` | The check API returned another error status |

### Not Thrown by the Current Version

`InvalidAuthConfigException`, `SecureStorageException`, and `MiAuthNotSupportedException` are defined but not thrown by the current version.

## Storage Errors

`SecureTokenStore` does not wrap errors from `flutter_secure_storage`. They reach your code as that package throws them, usually as `PlatformException`. If stored data is corrupted, reading it can also throw `FormatException` or `TypeError`. Handle these errors around `MisskeyAuthManager` calls that read or write tokens, including `loginWithOAuth` and `loginWithMiAuth`, which save the token after authentication.

`loginWithOAuth` and `loginWithMiAuth` save the token first and then make the account active. If only the second step fails, the token stays saved but the account is not active.

## Retries

- Fetching the OAuth server information and calling `/api/i` are retried up to three attempts in total, on timeouts, connection errors, other transport errors, and HTTP 429, 500, 502, 503, and 504.
- The token exchange and the MiAuth check API are not retried. An authorization code and a MiAuth session can be used only once, and the server may have completed the request even if the response was lost. Start the authentication again from the beginning.

## When Login Fails After Authentication

`loginWithOAuth` calls `/api/i` after it gets a token. If that call fails, the method throws and does not save the token. `loginWithOAuth` and `loginWithMiAuth` also throw without saving the token when the user information has no `id`.

In these cases the server has already issued the token, and it stays valid there; the library does not revoke it. The user can sign in again, which issues a new token.
