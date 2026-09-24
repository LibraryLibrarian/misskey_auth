---
sidebar_position: 1
slug: /
title: Premiers pas
---

# Premiers pas

misskey_auth est une bibliothèque Flutter pour vous authentifier auprès des serveurs [Misskey](https://misskey-hub.net/fr/). Elle prend en charge OAuth 2.0 et MiAuth, et stocke les jetons de plusieurs comptes.

## Fonctionnalités

- Authentification OAuth 2.0 pour les serveurs Misskey (v2023.9.0 et versions ultérieures)
- Authentification MiAuth pour les anciens serveurs
- Authentification dans le navigateur externe (sans WebView intégrée)
- PKCE (Proof Key for Code Exchange)
- Retour vers l’application au moyen d’un schéma d’URL personnalisé
- Stockage sécurisé des jetons avec `flutter_secure_storage`
- Stockage des jetons de plusieurs comptes et changement du compte actif
- `MisskeyAuthManager`, une API de haut niveau qui exécute l’authentification et enregistre les jetons
- iOS et Android

## Prérequis

- Flutter 3.47.1 ou version ultérieure, et Dart 3.13.1 ou version ultérieure (avant Dart 4)
- Android API 24 ou version ultérieure, avec compileSdk 37 ou version ultérieure
- iOS 15 ou version ultérieure

Si vous effectuez une mise à niveau depuis une version antérieure, consultez d’abord [Mise à niveau](./upgrading.md). Sur Android, les utilisateurs doivent se reconnecter.

## Installation

Ajoutez le package à votre `pubspec.yaml` :

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
```

Récupérez ensuite le package :

```bash
flutter pub get
```

## Démarrage rapide

L’authentification se déroule en trois étapes.

1. **Publiez une page client_id (OAuth uniquement).** Misskey récupère cette page HTTPS pour trouver les URI de redirection de votre application. Consultez [Page client_id](./client-id-page.md).
2. **Enregistrez un schéma d’URL personnalisé dans votre application.** Le navigateur revient à l’application via ce schéma. Consultez [Configuration des plateformes](./platform-setup.md).
3. **Lancez le flux depuis Dart.**

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth (Misskey v2023.9.0 et versions ultérieures)
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

// MiAuth (fonctionne aussi sur les anciens serveurs)
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

// Lit le jeton enregistré du compte actif
final current = await auth.currentToken();
print(current?.accessToken);
```

`MisskeyAuthManager` enregistre chaque jeton avec `SecureTokenStore`. Pour gérer vous-même les jetons, utilisez directement `MisskeyOAuthClient` ou `MisskeyMiAuthClient`. Consultez [OAuth et MiAuth](./oauth-and-miauth.md).

## Étapes suivantes

- [Page client_id](./client-id-page.md) : la page exigée par Misskey pour OAuth
- [Configuration des plateformes](./platform-setup.md) : configuration iOS et Android
- [OAuth et MiAuth](./oauth-and-miauth.md) : différences entre les deux méthodes et exemples avec ou sans stockage des jetons
- [Stockage des jetons](./token-storage.md) : plusieurs comptes, `TokenStore` et `SecureTokenStore`
- [Gestion des erreurs](./error-handling.md) : exceptions levées par la bibliothèque
- [Référence de l’API sur pub.dev](https://pub.dev/documentation/misskey_auth/latest/)

## Application d’exemple

Le dépôt contient une application d’exemple dans [`example/`](https://github.com/LibraryLibrarian/misskey_auth/tree/main/example). Elle utilise la page client_id publiée à `https://librarylibrarian.github.io/misskey_auth/example/`. Utilisez cette page uniquement pour essayer l’exemple ; publiez votre propre page client_id pour votre application.
