---
sidebar_position: 4
title: OAuth und MiAuth
---

# OAuth und MiAuth

Misskey bietet Apps zwei Möglichkeiten, ein Zugriffstoken zu erhalten.

| | OAuth 2.0 | MiAuth |
|---|---|---|
| Unterstützte Server | Misskey v2023.9.0 oder höher | Einschließlich älterer Server |
| client_id-Seite | Erforderlich (HTTPS) | Nicht erforderlich |
| Rücksprungziel des Browsers | Auf der client_id-Seite angegebene `redirect_uri` | `yourscheme://` (nur das Schema) |
| Konfigurationsklasse | `MisskeyOAuthConfig` | `MisskeyMiAuthConfig` |

Beide Verfahren öffnen einen externen Browser und kehren über ein benutzerdefiniertes URL-Schema zur App zurück. Daher ist für beide die [Plattformkonfiguration](./platform-setup.md) erforderlich.

Ob ein Server OAuth unterstützt, können Sie mit `MisskeyOAuthClient().getOAuthServerInfo(host)` prüfen. Bei nicht unterstützten Servern wird `null` zurückgegeben. In diesem Fall lösen `authenticate` und `loginWithOAuth` eine `OAuthNotSupportedException` aus, sodass Sie zu MiAuth wechseln können.

## Konfiguration

### `MisskeyOAuthConfig`

| Argument | Beschreibung |
|---|---|
| `host` | Host des Misskey-Servers (Beispiel: `misskey.io`) |
| `clientId` | URL der [client_id-Seite](./client-id-page.md) |
| `redirectUri` | Auf der client_id-Seite angegebene redirect URI (Beispiel: `yourscheme://oauth/callback`) |
| `scope` | Durch Leerzeichen getrennte Scopes (Beispiel: `read:account write:notes`) |
| `callbackScheme` | Benutzerdefiniertes Schema der App. Erforderlich, wird aber nur verwendet, wenn `redirectUri` eine `http(s)`-Zwischenseite ist. Andernfalls wird das Schema von `redirectUri` verwendet. |

### `MisskeyMiAuthConfig`

| Argument | Beschreibung |
|---|---|
| `host` | Host des Misskey-Servers |
| `appName` | Der dem Benutzer angezeigte App-Name |
| `callbackScheme` | Benutzerdefiniertes Schema der App. Misskey leitet den Browser zu `yourscheme://` weiter. |
| `permissions` | Anzufordernde Berechtigungen (Beispiel: `['read:account', 'write:notes']`). Optional |
| `iconUrl` | URL des dem Benutzer angezeigten App-Symbols. Optional |

## Ohne Token-Speicherung

`MisskeyOAuthClient` und `MisskeyMiAuthClient` führen die Authentifizierung aus und geben ein Token zurück. Das Token wird nicht gespeichert.

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
    iconUrl: 'https://example.com/icon.png', // Optional
  ),
);
print(result.token);
print(result.user); // Benutzerinformationen, falls vom Server zurückgegeben
```

## Mit Token-Speicherung

`MisskeyAuthManager` führt die Authentifizierung aus und speichert Token mit `TokenStore`. `MisskeyAuthManager.defaultInstance()` verwendet `SecureTokenStore`. Bei jeder Anmeldung wird ein `AccountKey` zurückgegeben, der das Konto identifiziert.

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

Nach der OAuth-Authentifizierung ruft der Manager mit dem neuen Token `/api/i` auf, um die Konto-ID abzurufen.

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
  setActive: true, // Dieses Konto aktivieren
);
final current = await auth.currentToken();
```

MiAuth gibt zusammen mit dem Token Benutzerinformationen zurück. Der Manager verwendet deren `id` als Konto-ID.

## Beide Verfahren in einer App unterstützen

- Wenn Sie in `Info.plist` und `AndroidManifest.xml` ein einzelnes Schema wie `yourscheme` registrieren, können OAuth und MiAuth es gemeinsam verwenden.
- MiAuth kehrt nur zum Schema (`yourscheme://`) zurück. Für MiAuth müssen Sie keinen Pfad wie `yourscheme://oauth/callback` einrichten.
- Verwenden Sie unter Android den intent-filter nur für das Schema aus der [Plattformkonfiguration](./platform-setup.md#android). Bei einem durch host oder path eingeschränkten Filter erreicht der MiAuth-Callback die App nicht.

## Weiterführende Links

- [Misskey-Dokumentation zu OAuth](https://misskey-hub.net/de/docs/for-developers/api/token/oauth/)
- [Misskey-Dokumentation zu MiAuth](https://misskey-hub.net/de/docs/for-developers/api/token/miauth/)
