[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [Deutsch](README.de.md) | Français | [한국어](README.ko.md)

# misskey_auth

<p align="center">
  <img src="https://raw.githubusercontent.com/librarylibrarian/misskey_auth/main/assets/demo_thumb.gif" alt="Demo" width="200" />
</p>

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

Une bibliothèque Flutter pour l'authentification auprès des serveurs [Misskey](https://misskey-hub.net/). Elle prend en charge OAuth 2.0 et MiAuth, et permet de stocker les jetons de plusieurs comptes.

## Fonctionnalités

- Authentification OAuth 2.0 pour les serveurs Misskey (v2023.9.0 et ultérieures)
- Authentification MiAuth pour les anciens serveurs
- Authentification dans le navigateur externe (sans WebView intégrée)
- PKCE (Proof Key for Code Exchange)
- Retour vers l'application via un schéma d'URL personnalisé
- Stockage sécurisé des jetons avec `flutter_secure_storage`
- Stockage des jetons de plusieurs comptes et changement de compte actif
- `MisskeyAuthManager`, une API de haut niveau qui exécute les flux d'authentification et enregistre les jetons
- iOS et Android

## Configuration requise

- Flutter 3.47.1 ou ultérieur et Dart 3.13.1 ou ultérieur (avant Dart 4)
- Android API 24 ou ultérieure, avec compileSdk 37 ou ultérieur
- iOS 15 ou ultérieur

Si vous effectuez une mise à niveau depuis une version antérieure, consultez d'abord [Mise à niveau](https://librarylibrarian.github.io/misskey_auth/fr/upgrading). Sur Android, une nouvelle connexion est nécessaire.

## Installation

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
```

## Démarrage rapide

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth (Misskey v2023.9.0 et ultérieures)
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

// MiAuth (fonctionne aussi avec les anciens serveurs)
final miKey = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
  ),
  setActive: true,
);

// Lire le jeton enregistré du compte actif
final current = await auth.currentToken();
```

Pour que ce code fonctionne, vous avez besoin de deux éléments :

1. **Une page client_id (OAuth uniquement).** Publiez une page HTTPS qui indique votre `redirect_uri` dans `<link rel="redirect_uri">`. Consultez la [page client_id](https://librarylibrarian.github.io/misskey_auth/fr/client-id-page).
2. **Un schéma d'URL personnalisé enregistré dans votre application.** Ajoutez `yourscheme` à `Info.plist` sur iOS et à `CallbackActivity` de `flutter_web_auth_2` sur Android. Consultez la [configuration des plateformes](https://librarylibrarian.github.io/misskey_auth/fr/platform-setup).

## Documentation

- Guide : https://librarylibrarian.github.io/misskey_auth/fr/
  - [Page client_id](https://librarylibrarian.github.io/misskey_auth/fr/client-id-page)
  - [Configuration des plateformes](https://librarylibrarian.github.io/misskey_auth/fr/platform-setup)
  - [OAuth et MiAuth](https://librarylibrarian.github.io/misskey_auth/fr/oauth-and-miauth)
  - [Stockage des jetons](https://librarylibrarian.github.io/misskey_auth/fr/token-storage)
  - [Gestion des erreurs](https://librarylibrarian.github.io/misskey_auth/fr/error-handling)
  - [Mise à niveau](https://librarylibrarian.github.io/misskey_auth/fr/upgrading)
- Référence de l'API : https://pub.dev/documentation/misskey_auth/latest/
- Historique des modifications : [CHANGELOG.md](CHANGELOG.md)
- Documentation Misskey : [OAuth](https://misskey-hub.net/fr/docs/for-developers/api/token/oauth/) / [MiAuth](https://misskey-hub.net/fr/docs/for-developers/api/token/miauth/)

## Licence

Ce projet est publié par 司書 (LibraryLibrarian) sous la licence BSD à 3 clauses. Consultez [LICENSE](LICENSE).
