---
sidebar_position: 1
slug: /
title: Getting Started
---

# Getting Started

misskey_auth is a Flutter library for authenticating with [Misskey](https://misskey-hub.net/) servers. It supports both OAuth 2.0 and MiAuth, and stores tokens for multiple accounts.

## Features

- OAuth 2.0 authentication for Misskey servers (v2023.9.0 and later)
- MiAuth authentication for older servers
- Authentication in the external browser (no embedded WebView)
- PKCE (Proof Key for Code Exchange)
- Callbacks to the app through a custom URL scheme
- Secure token storage using `flutter_secure_storage`
- Token storage for multiple accounts and switching the active account
- `MisskeyAuthManager`, a high-level API that runs the flows and saves tokens
- iOS and Android

## Requirements

- Flutter 3.47.1 or later, and Dart 3.13.1 or later (before Dart 4)
- Android API 24 or later, with compileSdk 37 or later
- iOS 15 or later

If you are upgrading from an earlier version, read [Upgrading](./upgrading.md) first. On Android, users must sign in again.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.2
```

Then fetch it:

```bash
flutter pub get
```

## Quick Start

Authentication takes three steps.

1. **Publish a client_id page (OAuth only).** Misskey fetches this HTTPS page to find the redirect URIs of your app. See [client_id Page](./client-id-page.md).
2. **Register a custom URL scheme in your app.** The browser returns to the app through this scheme. See [Platform Setup](./platform-setup.md).
3. **Run the flow from Dart.**

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth (Misskey v2023.9.0 and later)
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

// MiAuth (also works on older servers)
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

// Read the saved token of the active account
final current = await auth.currentToken();
print(current?.accessToken);
```

`MisskeyAuthManager` saves each token with `SecureTokenStore`. To manage tokens yourself, use `MisskeyOAuthClient` or `MisskeyMiAuthClient` directly. See [OAuth and MiAuth](./oauth-and-miauth.md).

## Next Steps

- [client_id Page](./client-id-page.md): the page Misskey requires for OAuth
- [Platform Setup](./platform-setup.md): iOS and Android configuration
- [OAuth and MiAuth](./oauth-and-miauth.md): how the two methods differ, and examples with and without saving tokens
- [Token Storage](./token-storage.md): multiple accounts, `TokenStore`, and `SecureTokenStore`
- [Error Handling](./error-handling.md): the exceptions the library throws
- [API reference on pub.dev](https://pub.dev/documentation/misskey_auth/latest/)

## Example App

The repository contains an example app in [`example/`](https://github.com/LibraryLibrarian/misskey_auth/tree/main/example). It uses the client_id page published at `https://librarylibrarian.github.io/misskey_auth/example/`. Use that page only to try the example; publish your own client_id page for your app.
