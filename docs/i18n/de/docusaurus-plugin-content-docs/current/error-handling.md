---
sidebar_position: 6
title: Fehlerbehandlung
---

# Fehlerbehandlung

Die Authentifizierungs-APIs lösen Unterklassen von `MisskeyAuthException` aus. Fangen Sie die Typen, die Sie einzeln behandeln möchten, separat ab und behandeln Sie die übrigen mit `MisskeyAuthException`.

```dart
import 'dart:developer';

try {
  await auth.loginWithOAuth(config);
} on UserCancelledException {
  // Benutzer hat den Browser geschlossen. Normalerweise keine Meldung erforderlich
} on OAuthNotSupportedException {
  // Server unterstützt OAuth nicht. MiAuth ausprobieren
} on NetworkException catch (e) {
  // Timeout, keine Verbindung, TLS-Fehler usw.
  log('Network error', error: e.originalException);
} on MisskeyAuthException catch (e) {
  log('Authentication failed: ${e.message} ${e.details ?? ''}');
}
```

Jede Ausnahme hat die folgenden Eigenschaften.

- `message`: kurze Beschreibung
- `details`: zusätzliche Informationen (falls vorhanden)
- `originalException`: ursprüngliche Ausnahme (falls vorhanden)

`message` und `details` sind für Logs gedacht. Sie enthalten auch Nachrichten auf Japanisch. Zeigen Sie Benutzern stattdessen je nach Ausnahmetyp einen in Ihrer App definierten Text an.

## Übersicht der Ausnahmen

### Allgemein

| Ausnahme | Auslösebedingung |
|---|---|
| `UserCancelledException` | Benutzer hat den Browser geschlossen oder die Authentifizierung abgebrochen. Siehe auch [Plattformkonfiguration](./platform-setup.md). |
| `CallbackSchemeErrorException` | Die Fehlermeldung der Plattform erwähnt den Callback. Üblicherweise bedeutet dies, dass das Callback-URL-Schema nicht registriert ist oder nicht übereinstimmt. |
| `AuthorizationLaunchException` | Der Browser konnte nicht geöffnet werden oder die Plattform hat einen anderen Fehler gemeldet. |
| `NetworkException` | Die Anfrage ist fehlgeschlagen, ohne eine Antwort zu erhalten (zum Beispiel Timeout, keine Verbindung oder TLS-Fehler). Bei `loginWithOAuth` wird die Ausnahme auch ausgelöst, wenn `/api/i` einen Fehlerstatus zurückgibt. |
| `ResponseParseException` | Die Antwort war kein JSON im erwarteten Format oder erforderliche Felder wie das Token oder die `id` des Benutzers fehlten. |
| `MisskeyAuthException` | Unerwarteter Fehler. Basisklasse aller Ausnahmen in dieser und den folgenden Tabellen. |

### OAuth

| Ausnahme | Auslösebedingung |
|---|---|
| `OAuthNotSupportedException` | Der Server unterstützt OAuth nicht (`/.well-known/oauth-authorization-server` hat 404 oder 501 zurückgegeben). |
| `ServerInfoException` | Beim Abrufen der Serverinformationen wurde ein anderer Fehlerstatus als 404 oder 501 zurückgegeben, `issuer` stimmte nicht exakt mit `https://{host}` überein oder der Autorisierungs- bzw. Token-Endpunkt war keine absolute HTTPS-URL. Anders als `OAuthNotSupportedException` bedeutet dies nicht, dass Sie zu MiAuth wechseln sollten. |
| `StateMismatchException` | Im Callback fehlt `state` oder stimmt nicht mit der Anfrage überein. |
| `AuthorizationServerErrorException` | Der Callback enthält `error` (zum Beispiel `access_denied`, wenn der Benutzer den Zugriff verweigert hat). `details` enthält `error` und `error_description`. |
| `AuthorizationCodeMissingException` | Im Callback fehlt der Autorisierungscode oder er ist mehrfach vorhanden. |
| `TokenExchangeException` | Der Token-Endpunkt hat einen Fehler zurückgegeben. Die Meldung enthält den HTTP-Status und den vom Server gemeldeten Fehler. |

### MiAuth

| Ausnahme | Auslösebedingung |
|---|---|
| `MiAuthDeniedException` | Die Prüf-API hat `ok: false` zurückgegeben. Der Benutzer hat möglicherweise abgelehnt, Misskey gibt diesen Wert jedoch auch für unbekannte oder bereits verwendete Sitzungen zurück. |
| `MiAuthSessionInvalidException` | Der Callback gehört zu einer anderen Sitzung oder die Prüf-API hat 404 oder 410 zurückgegeben. |
| `MiAuthCheckFailedException` | Die Prüf-API hat einen anderen Fehlerstatus zurückgegeben. |

### In der aktuellen Version nicht ausgelöste Ausnahmen

`InvalidAuthConfigException`, `SecureStorageException` und `MiAuthNotSupportedException` sind definiert, werden in der aktuellen Version jedoch nicht ausgelöst.

## Fehler im Speicher

`SecureTokenStore` umschließt Fehler von `flutter_secure_storage` nicht. Die Fehler werden unverändert an den Aufrufer weitergegeben (üblicherweise als `PlatformException`). Bei beschädigten gespeicherten Daten können beim Lesen auch `FormatException` oder `TypeError` ausgelöst werden. Behandeln Sie diese Fehler auch bei Aufrufen von `MisskeyAuthManager`, die Token lesen oder schreiben. Dazu zählen auch `loginWithOAuth` und `loginWithMiAuth`, die Token nach der Authentifizierung speichern.

`loginWithOAuth` und `loginWithMiAuth` speichern das Token und aktivieren anschließend das Konto. Schlägt nur die Aktivierung des Kontos fehl, bleibt das Token gespeichert, das Konto wird jedoch nicht aktiviert.

## Wiederholungsversuche

- OAuth-Abrufe der Serverinformationen und Aufrufe von `/api/i` werden bei Timeouts, Verbindungsfehlern, sonstigen Kommunikationsfehlern und HTTP 429, 500, 502, 503 oder 504 insgesamt bis zu dreimal versucht.
- Der Token-Austausch und die MiAuth-Prüf-API werden nicht erneut versucht. Autorisierungscodes und MiAuth-Sitzungen können nur einmal verwendet werden. Selbst wenn die Antwort verloren geht, kann der Server den Vorgang bereits abgeschlossen haben. Starten Sie die Authentifizierung von vorn.

## Wenn die Anmeldung nach der Authentifizierung fehlschlägt

`loginWithOAuth` ruft nach dem Abrufen des Tokens `/api/i` auf. Schlägt dieser Aufruf fehl, wird eine Ausnahme ausgelöst, ohne das Token zu speichern. `loginWithOAuth` und `loginWithMiAuth` lösen ebenfalls eine Ausnahme aus, ohne das Token zu speichern, wenn die Benutzerinformationen keine `id` enthalten.

In diesen Fällen hat der Server das Token bereits ausgestellt, und es bleibt serverseitig gültig. Die Bibliothek widerruft das Token nicht. Der Benutzer kann sich erneut anmelden; dabei wird ein neues Token ausgestellt.
