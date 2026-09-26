---
sidebar_position: 1
slug: /
title: Erste Schritte
---

# Erste Schritte

misskey_auth ist eine Flutter-Bibliothek für die Authentifizierung bei [Misskey](https://misskey-hub.net/de/)-Servern. Sie unterstützt sowohl OAuth 2.0 als auch MiAuth und kann Token für mehrere Konten speichern.

## Funktionen

- OAuth-2.0-Authentifizierung bei Misskey-Servern (ab v2023.9.0)
- MiAuth-Authentifizierung für ältere Server
- Authentifizierung im externen Browser (ohne eingebettete WebView)
- PKCE (Proof Key for Code Exchange)
- Rückkehr zur App über ein benutzerdefiniertes URL-Schema
- Sichere Token-Speicherung mit `flutter_secure_storage`
- Speicherung von Token für mehrere Konten und Wechsel des aktiven Kontos
- High-Level-API `MisskeyAuthManager` zur Authentifizierung und Token-Speicherung
- iOS und Android

## Voraussetzungen

- Flutter 3.47.1 oder höher, Dart 3.13.1 oder höher und niedriger als 4.0
- Android API 24 oder höher, compileSdk 37 oder höher
- iOS 15 oder höher

Wenn Sie von einer früheren Version aktualisieren, lesen Sie zuerst die [Hinweise zum Upgrade](./upgrading.md). Unter Android ist eine erneute Anmeldung erforderlich.

## Installation

Fügen Sie das Paket zu `pubspec.yaml` hinzu.

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.2
```

Rufen Sie anschließend die Abhängigkeiten ab.

```bash
flutter pub get
```

## Schnellstart

Die Authentifizierung erfolgt in drei Schritten.

1. **Veröffentlichen Sie eine client_id-Seite (nur für OAuth).** Misskey ruft diese HTTPS-Seite ab, um die redirect URI der App zu überprüfen. Weitere Informationen finden Sie unter [client_id-Seite](./client-id-page.md).
2. **Registrieren Sie ein benutzerdefiniertes URL-Schema in der App.** Der Browser kehrt über dieses Schema zur App zurück. Weitere Informationen finden Sie unter [Plattformkonfiguration](./platform-setup.md).
3. **Führen Sie die Authentifizierung über Dart aus.**

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth (Misskey v2023.9.0 oder höher)
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

// MiAuth (funktioniert auch mit älteren Servern)
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

// Gespeichertes Token des aktiven Kontos lesen
final current = await auth.currentToken();
print(current?.accessToken);
```

`MisskeyAuthManager` speichert jedes Token mit `SecureTokenStore`. Wenn Sie Token selbst verwalten möchten, verwenden Sie direkt `MisskeyOAuthClient` oder `MisskeyMiAuthClient`. Weitere Informationen finden Sie unter [OAuth und MiAuth](./oauth-and-miauth.md).

## Weiterführende Seiten

- [client_id-Seite](./client-id-page.md): die von Misskey für OAuth benötigte Seite
- [Plattformkonfiguration](./platform-setup.md): Konfiguration für iOS und Android
- [OAuth und MiAuth](./oauth-and-miauth.md): Unterschiede zwischen den beiden Verfahren sowie Beispiele mit und ohne Token-Speicherung
- [Token-Speicherung](./token-storage.md): mehrere Konten, `TokenStore` und `SecureTokenStore`
- [Fehlerbehandlung](./error-handling.md): von der Bibliothek ausgelöste Ausnahmen
- [API-Referenz auf pub.dev](https://pub.dev/documentation/misskey_auth/latest/)

## Beispiel-App

Im Repository befindet sich unter [`example/`](https://github.com/LibraryLibrarian/misskey_auth/tree/main/example) eine Beispiel-App. Diese App verwendet die unter `https://librarylibrarian.github.io/misskey_auth/example/` veröffentlichte client_id-Seite. Verwenden Sie diese Seite nur zum Ausprobieren des Beispiels und veröffentlichen Sie für Ihre eigene App eine eigene client_id-Seite.
