---
sidebar_position: 6
title: Gestion des erreurs
---

# Gestion des erreurs

Les API d’authentification lèvent des sous-classes de `MisskeyAuthException`. Interceptez les types que vous souhaitez traiter séparément, puis interceptez les autres avec `MisskeyAuthException`.

```dart
import 'dart:developer';

try {
  await auth.loginWithOAuth(config);
} on UserCancelledException {
  // L’utilisateur a fermé le navigateur. En général, aucune action n’est nécessaire.
} on OAuthNotSupportedException {
  // Le serveur ne prend pas en charge OAuth. Essayez plutôt MiAuth.
} on NetworkException catch (e) {
  // Délai dépassé, absence de connexion, erreur TLS, etc.
  log('Network error', error: e.originalException);
} on MisskeyAuthException catch (e) {
  log('Authentication failed: ${e.message} ${e.details ?? ''}');
}
```

Chaque exception possède les propriétés suivantes :

- `message` : description courte
- `details` : informations supplémentaires, le cas échéant
- `originalException` : exception d’origine, le cas échéant

`message` et `details` sont destinés aux journaux. Certains messages sont en japonais. Affichez aux utilisateurs vos propres textes en fonction du type d’exception.

## Exceptions

### Communes

| Exception | Condition de déclenchement |
|---|---|
| `UserCancelledException` | L’utilisateur a fermé le navigateur ou annulé l’authentification. Consultez également [Configuration des plateformes](./platform-setup.md) |
| `CallbackSchemeErrorException` | Le message d’erreur de la plateforme mentionne le rappel, ce qui signifie généralement que le schéma d’URL de rappel n’est pas enregistré ou ne correspond pas |
| `AuthorizationLaunchException` | Le navigateur n’a pas pu s’ouvrir ou la plateforme a signalé une autre erreur |
| `NetworkException` | Une requête a échoué sans réponse : délai dépassé, absence de connexion, erreur TLS, etc. `loginWithOAuth` la lève également si `/api/i` renvoie un statut d’erreur |
| `ResponseParseException` | Une réponse ne correspondait pas au JSON attendu ou un champ obligatoire, comme le jeton ou l’`id` de l’utilisateur, était manquant |
| `MisskeyAuthException` | Erreur inattendue. Classe de base de toutes les exceptions ci-dessus et ci-dessous |

### OAuth

| Exception | Condition de déclenchement |
|---|---|
| `OAuthNotSupportedException` | Le serveur ne prend pas en charge OAuth (`/.well-known/oauth-authorization-server` a renvoyé 404 ou 501) |
| `ServerInfoException` | La requête d’informations du serveur a renvoyé un statut d’erreur autre que 404 ou 501, son `issuer` ne correspond pas exactement à `https://{host}`, ou son point de terminaison d’autorisation ou de jeton n’est pas une URL HTTPS absolue. Contrairement à `OAuthNotSupportedException`, cela ne signifie pas que vous devez utiliser MiAuth |
| `StateMismatchException` | Le `state` du rappel est absent ou ne correspond pas à la requête |
| `AuthorizationServerErrorException` | Le rappel contient un `error`, par exemple `access_denied` lorsque l’utilisateur refuse l’accès. `details` contient `error` et `error_description` |
| `AuthorizationCodeMissingException` | Le rappel ne contient aucun code d’autorisation ou en contient plusieurs |
| `TokenExchangeException` | Le point de terminaison de jeton a renvoyé une erreur. Le message contient le statut HTTP et l’erreur renvoyée par le serveur |

### MiAuth

| Exception | Condition de déclenchement |
|---|---|
| `MiAuthDeniedException` | L’API de vérification a renvoyé `ok: false`. L’utilisateur a peut-être refusé l’accès, mais Misskey renvoie aussi cette valeur pour une session inconnue ou déjà utilisée |
| `MiAuthSessionInvalidException` | Le rappel concerne une autre session, ou l’API de vérification a renvoyé 404 ou 410 |
| `MiAuthCheckFailedException` | L’API de vérification a renvoyé un autre statut d’erreur |

### Exceptions non levées par la version actuelle

`InvalidAuthConfigException`, `SecureStorageException` et `MiAuthNotSupportedException` sont définies, mais ne sont pas levées par la version actuelle.

## Erreurs de stockage

`SecureTokenStore` n’encapsule pas les erreurs de `flutter_secure_storage`. Elles parviennent à votre code telles que ce package les lève, généralement sous la forme de `PlatformException`. Si les données stockées sont corrompues, leur lecture peut également lever `FormatException` ou `TypeError`. Traitez ces erreurs autour des appels à `MisskeyAuthManager` qui lisent ou écrivent des jetons, notamment `loginWithOAuth` et `loginWithMiAuth`, qui enregistrent le jeton après l’authentification.

`loginWithOAuth` et `loginWithMiAuth` enregistrent d’abord le jeton, puis activent le compte. Si seule la deuxième étape échoue, le jeton reste enregistré, mais le compte n’est pas actif.

## Nouvelles tentatives

- La récupération des informations du serveur OAuth et l’appel à `/api/i` font jusqu’à trois tentatives au total en cas de délai dépassé, d’erreur de connexion, d’autre erreur de transport ou de réponse HTTP 429, 500, 502, 503 ou 504.
- L’échange du jeton et l’API de vérification MiAuth ne font pas de nouvelle tentative. Un code d’autorisation et une session MiAuth ne peuvent être utilisés qu’une fois, et le serveur peut avoir traité la requête même si la réponse a été perdue. Recommencez l’authentification depuis le début.

## Échec de connexion après l’authentification

`loginWithOAuth` appelle `/api/i` après avoir obtenu un jeton. Si cet appel échoue, la méthode lève une exception et n’enregistre pas le jeton. `loginWithOAuth` et `loginWithMiAuth` lèvent également une exception sans enregistrer le jeton si les informations utilisateur ne contiennent pas d’`id`.

Dans ces cas, le serveur a déjà émis le jeton, qui y reste valide ; la bibliothèque ne le révoque pas. L’utilisateur peut se reconnecter, ce qui émet un nouveau jeton.
