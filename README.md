[日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [한국어](README.ko.md)

# misskey_auth

<p align="center">
  <img src="https://raw.githubusercontent.com/librarylibrarian/misskey_auth/main/assets/demo_thumb.gif" alt="Demo" width="200" />
</p>

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A Flutter library for authenticating with [Misskey](https://misskey-hub.net/) servers. It supports both OAuth 2.0 and MiAuth, and stores tokens for multiple accounts.

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

If you are upgrading from an earlier version, read [Upgrading](https://librarylibrarian.github.io/misskey_auth/upgrading) first. On Android, users must sign in again.

## Installation

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
```

## Quick Start

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
  ),
  setActive: true,
);

// Read the saved token of the active account
final current = await auth.currentToken();
```

Before this code works, you need two things:

1. **A client_id page (OAuth only).** Publish an HTTPS page that lists your `redirect_uri` in `<link rel="redirect_uri">`. See [client_id Page](https://librarylibrarian.github.io/misskey_auth/client-id-page).
2. **A custom URL scheme registered in your app.** Add `yourscheme` to `Info.plist` on iOS and to `CallbackActivity` of `flutter_web_auth_2` on Android. See [Platform Setup](https://librarylibrarian.github.io/misskey_auth/platform-setup).

## Documentation

- Guide: https://librarylibrarian.github.io/misskey_auth/
  - [client_id Page](https://librarylibrarian.github.io/misskey_auth/client-id-page)
  - [Platform Setup](https://librarylibrarian.github.io/misskey_auth/platform-setup)
  - [OAuth and MiAuth](https://librarylibrarian.github.io/misskey_auth/oauth-and-miauth)
  - [Token Storage](https://librarylibrarian.github.io/misskey_auth/token-storage)
  - [Error Handling](https://librarylibrarian.github.io/misskey_auth/error-handling)
  - [Upgrading](https://librarylibrarian.github.io/misskey_auth/upgrading)
- API reference: https://pub.dev/documentation/misskey_auth/latest/
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Misskey documentation: [OAuth](https://misskey-hub.net/en/docs/for-developers/api/token/oauth/) / [MiAuth](https://misskey-hub.net/en/docs/for-developers/api/token/miauth/)

## License

This project is published by 司書 (LibraryLibrarian) under the 3-Clause BSD License. See [LICENSE](LICENSE).
