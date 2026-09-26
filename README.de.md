[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | Deutsch | [Français](README.fr.md) | [한국어](README.ko.md)

# misskey_auth

<p align="center">
  <img src="https://raw.githubusercontent.com/librarylibrarian/misskey_auth/main/assets/demo_thumb.gif" alt="Demo" width="200" />
</p>

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Eine Flutter-Bibliothek zur Authentifizierung bei [Misskey](https://misskey-hub.net/)-Servern. Sie unterstützt OAuth 2.0 und MiAuth und speichert Tokens für mehrere Konten.

## Funktionen

- OAuth-2.0-Authentifizierung für Misskey-Server (v2023.9.0 und höher)
- MiAuth-Authentifizierung für ältere Server
- Authentifizierung im externen Browser (keine eingebettete WebView)
- PKCE (Proof Key for Code Exchange)
- Callback zur App über ein benutzerdefiniertes URL-Schema
- Sichere Token-Speicherung mit `flutter_secure_storage`
- Token-Speicherung für mehrere Konten und Wechsel des aktiven Kontos
- `MisskeyAuthManager`, eine High-Level-API, die Authentifizierungsabläufe ausführt und Tokens speichert
- iOS und Android

## Voraussetzungen

- Flutter 3.47.1 oder höher sowie Dart 3.13.1 oder höher (unter 4.0)
- Android API 24 oder höher, compileSdk 37 oder höher
- iOS 15 oder höher

Wenn Sie von einer früheren Version aktualisieren, lesen Sie zuerst die [Hinweise zum Update](https://librarylibrarian.github.io/misskey_auth/de/upgrading). Unter Android ist eine erneute Anmeldung erforderlich.

## Installation

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.2
```

## Schnellstart

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth (Misskey v2023.9.0 und höher)
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

// MiAuth (funktioniert auch auf älteren Servern)
final miKey = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
  ),
  setActive: true,
);

// Gespeichertes Token des aktiven Kontos lesen
final current = await auth.currentToken();
```

Damit dieser Code funktioniert, benötigen Sie zwei Dinge:

1. **Eine client_id-Seite (nur OAuth).** Veröffentlichen Sie eine HTTPS-Seite, auf der Ihre `redirect_uri` in `<link rel="redirect_uri">` eingetragen ist. Siehe [client_id-Seite](https://librarylibrarian.github.io/misskey_auth/de/client-id-page).
2. **Ein in der App registriertes benutzerdefiniertes URL-Schema.** Fügen Sie `yourscheme` unter iOS zur `Info.plist` und unter Android zur `CallbackActivity` von `flutter_web_auth_2` hinzu. Siehe [Plattformkonfiguration](https://librarylibrarian.github.io/misskey_auth/de/platform-setup).

## Dokumentation

- Leitfaden: https://librarylibrarian.github.io/misskey_auth/de/
  - [client_id-Seite](https://librarylibrarian.github.io/misskey_auth/de/client-id-page)
  - [Plattformkonfiguration](https://librarylibrarian.github.io/misskey_auth/de/platform-setup)
  - [OAuth und MiAuth](https://librarylibrarian.github.io/misskey_auth/de/oauth-and-miauth)
  - [Token-Speicherung](https://librarylibrarian.github.io/misskey_auth/de/token-storage)
  - [Fehlerbehandlung](https://librarylibrarian.github.io/misskey_auth/de/error-handling)
  - [Hinweise zum Update](https://librarylibrarian.github.io/misskey_auth/de/upgrading)
- API-Referenz: https://pub.dev/documentation/misskey_auth/latest/
- Änderungsprotokoll: [CHANGELOG.md](CHANGELOG.md)
- Misskey-Dokumentation: [OAuth](https://misskey-hub.net/de/docs/for-developers/api/token/oauth/) / [MiAuth](https://misskey-hub.net/de/docs/for-developers/api/token/miauth/)

## Lizenz

Dieses Projekt wird von 司書 (LibraryLibrarian) unter der 3-Clause BSD License veröffentlicht. Weitere Informationen finden Sie unter [LICENSE](LICENSE).
