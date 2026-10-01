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
await auth.signOut(key);  // Révoque et supprime le jeton d’un compte
await auth.signOutAll();  // Révoque et supprime les jetons de tous les comptes
```

## Déconnexion {#signing-out}

La déconnexion révoque le jeton sur le serveur, puis le supprime de l’appareil. La révocation nécessite Misskey 2026.9.0 ou version ultérieure, qui permet à un jeton d’application de se révoquer lui-même via `/api/i/revoke-token`. Elle fonctionne pour les jetons MiAuth et OAuth, quelles que soient leurs autorisations.

```dart
final result = await auth.signOut(key);
final revocation = result.revocation;
if (revocation == null) {
  // La révocation n’a pas été tentée. Consultez result.skipReason.
} else if (revocation.isInvalidated) {
  // revoked ou alreadyInvalid : le jeton n’est plus utilisable sur le serveur.
} else if (revocation.status == TokenRevocationStatus.unsupported) {
  // Le serveur est antérieur à 2026.9.0. Le jeton y reste valide.
} else {
  // failed : erreur réseau, délai dépassé ou réponse inattendue.
}
```

### Modes

Transmettez `mode` pour choisir ce qu’il advient du jeton sur l’appareil :

| `SignOutMode` | Révocation | Suppression de l’appareil |
|---|---|---|
| `revokeAndDelete` (par défaut) | Oui | Toujours, quel que soit le résultat de la révocation |
| `revokeOrKeep` | Oui | Uniquement si le résultat est `revoked` ou `alreadyInvalid` |
| `localOnly` | Non | Toujours |

Avec `revokeOrKeep`, un jeton qui n’a pas pu être révoqué reste enregistré, afin que l’utilisateur puisse réessayer plus tard. Un serveur qui ne prend pas en charge la révocation renvoie toujours `unsupported`, et un compte que le serveur refuse pour une autre raison, par exemple un compte suspendu, peut échouer à chaque fois. Pour retirer ces comptes de l’appareil, déconnectez-les à nouveau avec `SignOutMode.localOnly`.

Si le jeton n’est pas stocké ou ne peut pas être lu, par exemple parce que les données stockées sont corrompues, il est supprimé sans révocation, quel que soit le mode.

### Résultats

`signOut` renvoie un `SignOutResult`, et `signOutAll` en renvoie un pour chaque compte, dans l’ordre de `listAccounts` :

| Champ | Signification |
|---|---|
| `key` | Le compte |
| `revocation` | Le `TokenRevocationResult`, ou `null` si la révocation n’a pas été tentée |
| `skipReason` | La raison pour laquelle la révocation n’a pas été tentée : `localOnly`, `noStoredToken` ou `unreadableToken`. `null` si elle a été tentée |
| `deleted` | Indique si le jeton a été supprimé de l’appareil |

`TokenRevocationResult` contient :

| Champ | Signification |
|---|---|
| `status` | `revoked`, `alreadyInvalid`, `unsupported` ou `failed` |
| `isInvalidated` | `true` pour `revoked` et `alreadyInvalid` |
| `statusCode` | Le statut HTTP, ou `null` si aucune réponse n’a été reçue |
| `errorCode` | Le code d’erreur Misskey, comme `RATE_LIMIT_EXCEEDED`, le cas échéant |
| `error` | La cause pour `unsupported` et `failed` : `TokenRevocationException` pour une réponse d’erreur, `NetworkException` pour une erreur réseau ou un délai dépassé, `ResponseParseException` pour une réponse illisible |

`alreadyInvalid` signifie que le serveur n’a pas reconnu le jeton : il avait déjà été révoqué, ou le compte a été supprimé. Ce résultat est traité comme `revoked`.

Les échecs de révocation sont signalés dans le résultat et ne sont jamais levés. Les erreurs survenant lors de la suppression du jeton sur l’appareil sont levées comme auparavant ; `signOutAll` tente d’abord de supprimer tous les comptes, puis lève la première erreur.

`deleted` vaut `false` dans deux cas : `revokeOrKeep` a conservé le jeton, ou un nouveau jeton a été enregistré pour le même compte pendant la révocation, par exemple parce que l’utilisateur s’est reconnecté. Le nouveau jeton n’est pas supprimé, car il n’a jamais été révoqué.

### Délai d’expiration et nouvelles tentatives {#timeout-and-retries}

La révocation ne fait pas de nouvelle tentative. Sans `timeout`, une requête qui ne répond pas attend l’expiration des délais de la requête (consultez [Délais d’expiration](#timeouts)). Transmettez `timeout` pour limiter cette attente :

```dart
await auth.signOut(key, timeout: const Duration(seconds: 5));
await auth.signOutAll(timeout: const Duration(seconds: 5));
```

`signOutAll` révoque tous les comptes en parallèle, et son `timeout` s’applique à l’ensemble de l’opération. Une requête qui dépasse le délai est signalée comme `failed`. Le serveur peut néanmoins avoir révoqué le jeton ; une nouvelle déconnexion signale alors `alreadyInvalid`.

### Révocation sans le gestionnaire

Si vous stockez vous-même les jetons, utilisez directement `MisskeyTokenRevocationClient`. Il révoque le jeton sur le serveur sans toucher à aucun stockage :

```dart
final revocation = MisskeyTokenRevocationClient();
final result = await revocation.revoke(
  host: 'misskey.io',
  accessToken: token,
  timeout: const Duration(seconds: 5),
);
if (result.isInvalidated) {
  // Supprimez le jeton de votre propre stockage.
}
```

`revoke` ne lève jamais d’exception et renvoie le même `TokenRevocationResult`. Le client envoie le jeton dans le corps de la requête. Si vous transmettez votre propre `Dio`, ses intercepteurs peuvent voir le jeton ; ne journalisez donc pas le corps des requêtes.

## Délais d’expiration {#timeouts}

`MisskeyAuthManager.defaultInstance()` utilise les délais par défaut : 10 secondes pour la connexion, et 20 secondes pour l’envoi et la réception. Pour les modifier, construisez vous-même `MisskeyAuthManager`. Ses délais s’appliquent à ses propres requêtes, `/api/i` et la révocation des jetons ; transmettez-les donc également à chaque client :

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

Les constructeurs acceptent `connectTimeout`, `sendTimeout` et `receiveTimeout`. Ils acceptent également un `dio`. `MisskeyOAuthClient` et `MisskeyMiAuthClient` appliquent aussi les arguments de délai à un `Dio` que vous leur transmettez. `MisskeyTokenRevocationClient` ne les applique qu’à ses propres requêtes et laisse ce `Dio` inchangé. `MisskeyAuthManager` les ignore si `dio` est fourni ; configurez directement ce `Dio`. Pour utiliser un autre client de révocation, transmettez-le via `revocation`.

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

`SecureTokenStore` enregistre les jetons avec `flutter_secure_storage` : dans le trousseau sur iOS et macOS, et dans le Keystore sur Android. Pour modifier les options de stockage, transmettez une instance de `FlutterSecureStorage` que vous avez créée vous-même. misskey_auth ne réexporte pas cette classe ; ajoutez donc `flutter_secure_storage` à vos dépendances et importez-la :

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
