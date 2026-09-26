---
sidebar_position: 4
title: OAuth et MiAuth
---

# OAuth et MiAuth

Misskey propose deux méthodes pour obtenir un jeton d’accès dans une application.

| | OAuth 2.0 | MiAuth |
|---|---|---|
| Serveurs | Misskey v2023.9.0 et versions ultérieures | Également les anciens serveurs |
| Page client_id | Requise (HTTPS) | Non requise |
| Destination du navigateur | Le `redirect_uri` indiqué sur la page client_id | `yourscheme://` (schéma uniquement) |
| Configuration | `MisskeyOAuthConfig` | `MisskeyMiAuthConfig` |

Les deux méthodes ouvrent le navigateur externe et reviennent à l’application via un schéma d’URL personnalisé ; elles nécessitent donc toutes deux la [configuration des plateformes](./platform-setup.md).

Pour vérifier si un serveur prend en charge OAuth, appelez `MisskeyOAuthClient().getOAuthServerInfo(host)`. La méthode renvoie `null` si le serveur ne prend pas en charge OAuth. Dans ce cas, `authenticate` et `loginWithOAuth` lèvent `OAuthNotSupportedException` ; vous pouvez alors utiliser MiAuth.

## Configuration

### `MisskeyOAuthConfig`

| Paramètre | Description |
|---|---|
| `host` | Hôte du serveur Misskey, par exemple `misskey.io` |
| `clientId` | URL de votre [page client_id](./client-id-page.md) |
| `redirectUri` | URI de redirection indiquée sur la page client_id, par exemple `yourscheme://oauth/callback` |
| `scope` | Portées séparées par des espaces, par exemple `read:account write:notes` |
| `callbackScheme` | Schéma personnalisé de votre application. Obligatoire, mais utilisé uniquement si `redirectUri` est une page relais `http(s)` ; sinon, le schéma de `redirectUri` est utilisé |

### `MisskeyMiAuthConfig`

| Paramètre | Description |
|---|---|
| `host` | Hôte du serveur Misskey |
| `appName` | Nom de l’application affiché à l’utilisateur |
| `callbackScheme` | Schéma personnalisé de votre application. Misskey redirige le navigateur vers `yourscheme://` |
| `permissions` | Autorisations demandées, par exemple `['read:account', 'write:notes']`. Facultatif |
| `iconUrl` | URL de l’icône de l’application affichée à l’utilisateur. Facultatif |

## Sans enregistrer les jetons

`MisskeyOAuthClient` et `MisskeyMiAuthClient` exécutent le flux et renvoient le jeton. Ils ne l’enregistrent pas.

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
    iconUrl: 'https://example.com/icon.png', // Facultatif
  ),
);
print(result.token);
print(result.user); // Informations utilisateur, si le serveur les renvoie
```

## Avec enregistrement des jetons

`MisskeyAuthManager` exécute le flux et enregistre le jeton avec un `TokenStore`. `MisskeyAuthManager.defaultInstance()` utilise `SecureTokenStore`. Chaque connexion renvoie un `AccountKey` qui identifie le compte.

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

Après OAuth, `MisskeyAuthManager` appelle `/api/i` avec le nouveau jeton pour récupérer l’identifiant du compte.

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
  setActive: true, // En plus de l’enregistrer, définit ce compte comme compte actif
);
final current = await auth.currentToken();
```

MiAuth renvoie les informations utilisateur avec le jeton, et `MisskeyAuthManager` utilise leur `id` comme identifiant du compte.

## Prendre en charge les deux méthodes dans une application

- Enregistrez un seul schéma, par exemple `yourscheme`, dans `Info.plist` et `AndroidManifest.xml`. OAuth et MiAuth peuvent le partager.
- MiAuth revient uniquement au schéma (`yourscheme://`). Il n’est pas nécessaire de prévoir un chemin tel que `yourscheme://oauth/callback` pour MiAuth.
- Sur Android, conservez l’intent-filter limité au schéma indiqué dans [Configuration des plateformes](./platform-setup.md#android). Un filtre limité par hôte ou chemin empêche les rappels MiAuth de parvenir à l’application.

## Voir aussi

- [Documentation OAuth de Misskey](https://misskey-hub.net/fr/docs/for-developers/api/token/oauth/)
- [Documentation MiAuth de Misskey](https://misskey-hub.net/fr/docs/for-developers/api/token/miauth/)
