---
sidebar_position: 5
title: Stockage des jetons
---

# Stockage des jetons

`MisskeyAuthManager` enregistre les jetons de plusieurs comptes et suit le compte actif. Il les stocke via l’interface `TokenStore`. L’implémentation par défaut est `SecureTokenStore`.

## Gestion des comptes

```dart
final auth = MisskeyAuthManager.defaultInstance();

// Jetons
final current = await auth.currentToken();  // Compte actif, ou null
final specific = await auth.tokenOf(key);   // Un compte précis, ou null

// Comptes
final accounts = await auth.listAccounts();
await auth.setActive(key);
final active = await auth.getActive();
await auth.clearActive();

// Déconnexion
await auth.signOut(key);  // Supprime le jeton d’un compte
await auth.signOutAll();  // Supprime les jetons de tous les comptes
```

La déconnexion supprime uniquement le jeton de l’appareil. Elle ne révoque pas le jeton sur le serveur.

## Délais d’expiration

`MisskeyAuthManager.defaultInstance()` utilise les délais par défaut : 10 secondes pour la connexion, et 20 secondes pour l’envoi et la réception. Pour les modifier, construisez vous-même `MisskeyAuthManager`. Ses délais ne s’appliquent qu’à sa propre requête `/api/i` ; transmettez-les donc également à chaque client :

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

Les constructeurs acceptent `connectTimeout`, `sendTimeout` et `receiveTimeout`. Ils acceptent également un `dio`. Les clients appliquent aussi les arguments de délai à un `Dio` que vous leur transmettez, mais `MisskeyAuthManager` les ignore si `dio` est fourni ; configurez directement ce `Dio`.

## Modèles

```dart
class AccountKey {
  final String host;       // par exemple 'misskey.io'
  final String accountId;  // Identifiant utilisateur sur ce serveur
}

class StoredToken {
  final String accessToken;
  final String tokenType;  // 'MiAuth' ou 'OAuth'
  final String? scope;     // OAuth uniquement
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
}

class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;
}
```

`AccountKey` associe l’hôte et l’identifiant utilisateur, car un identifiant utilisateur n’est unique qu’au sein d’un serveur. L’hôte est stocké exactement tel que vous le fournissez dans la configuration ; utilisez donc toujours la même forme pour un serveur, par exemple `misskey.io` en minuscules. L’enregistrement d’un jeton avec un `AccountKey` existant remplace l’ancien jeton.

## `TokenStore`

Pour stocker les jetons ailleurs, implémentez `TokenStore` et transmettez-le à `MisskeyAuthManager` :

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

`SecureTokenStore` enregistre les jetons avec `flutter_secure_storage` : dans le trousseau sur iOS et le Keystore sur Android. Pour modifier les options de stockage, transmettez une instance de `FlutterSecureStorage` que vous avez créée vous-même. misskey_auth ne réexporte pas cette classe ; ajoutez donc `flutter_secure_storage` à vos dépendances et importez-la :

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const store = SecureTokenStore(
  storage: FlutterSecureStorage(/* vos options */),
);
```

### Concurrence

- Les opérations d’écriture (`upsert`, `delete`, `clearAll`, `setActive`) s’exécutent une par une dans un même isolate, même entre différentes instances. Des écritures concurrentes ne font pas perdre de comptes dans l’index.
- Les lectures ne sont pas bloquées, et une séquence telle que `upsert` suivie de `setActive` n’est pas atomique.
- Aucune exclusion mutuelle n’est assurée avec les écritures provenant d’autres isolates ou processus.

### Ce que supprime `clearAll`

`clearAll` supprime les comptes répertoriés dans l’index du store, l’index lui-même et le compte actif. La méthode n’énumère pas tout l’espace de stockage, car sur Android, `readAll` peut effacer la totalité du stockage si une seule entrée ne peut pas être déchiffrée. Les jetons laissés sans entrée d’index par les versions précédentes ne sont donc pas supprimés.

### Espace de stockage partagé {#shared-storage}

Le `SecureTokenStore` par défaut utilise l’espace de stockage par défaut, que d’autres parties de votre application peuvent également utiliser. `flutter_secure_storage` 11 active `resetOnError` par défaut ; le rétablissement après une erreur de stockage peut donc aussi supprimer d’autres valeurs dans cet espace. Si votre application y conserve d’autres données, vérifiez sa configuration. Consultez également le [journal des modifications de flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage/changelog).
