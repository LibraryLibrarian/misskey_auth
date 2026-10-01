---
sidebar_position: 5
title: Token-Speicherung
---

# Token-Speicherung

`MisskeyAuthManager` speichert Token für mehrere Konten und verwaltet, welches Konto aktiv ist. Die Speicherung erfolgt über die Schnittstelle `TokenStore`; die Standardimplementierung ist `SecureTokenStore`.

## Konten verwalten

```dart
final auth = MisskeyAuthManager.defaultInstance();

// Token
final current = await auth.currentToken();  // Aktives Konto, andernfalls null
final specific = await auth.tokenOf(key);   // Angegebenes Konto, andernfalls null

// Konto
final accounts = await auth.listAccounts();
await auth.setActive(key);
final active = await auth.getActive();
await auth.clearActive();

// Abmelden
await auth.signOut(key);  // Token für ein Konto widerrufen und löschen
await auth.signOutAll();  // Token für alle Konten widerrufen und löschen
```

## Abmelden {#signing-out}

Beim Abmelden wird das Token auf dem Server widerrufen und anschließend vom Gerät gelöscht. Der Widerruf erfordert Misskey 2026.9.0 oder höher; ab dieser Version kann sich ein App-Token über `/api/i/revoke-token` selbst widerrufen. Das funktioniert für MiAuth- und OAuth-Token, unabhängig von ihren Berechtigungen.

```dart
final result = await auth.signOut(key);
final revocation = result.revocation;
if (revocation == null) {
  // Widerruf wurde nicht versucht. Siehe result.skipReason.
} else if (revocation.isInvalidated) {
  // revoked oder alreadyInvalid: Das Token kann auf dem Server nicht mehr verwendet werden.
} else if (revocation.status == TokenRevocationStatus.unsupported) {
  // Der Server ist älter als 2026.9.0. Das Token bleibt dort gültig.
} else {
  // failed: Netzwerkfehler, Timeout oder unerwartete Antwort.
}
```

### Modi

Mit `mode` legen Sie fest, was mit dem Token auf dem Gerät geschieht:

| `SignOutMode` | Widerruf | Löschen vom Gerät |
|---|---|---|
| `revokeAndDelete` (Standard) | Ja | Immer, unabhängig vom Ergebnis des Widerrufs |
| `revokeOrKeep` | Ja | Nur wenn das Ergebnis `revoked` oder `alreadyInvalid` ist |
| `localOnly` | Nein | Immer |

Mit `revokeOrKeep` bleibt ein Token, das nicht widerrufen werden konnte, gespeichert, sodass der Benutzer es später erneut versuchen kann. Ein Server, der den Widerruf nicht unterstützt, gibt immer `unsupported` zurück, und bei einem Konto, das der Server aus einem anderen Grund ablehnt, etwa einem gesperrten Konto, kann der Widerruf jedes Mal fehlschlagen. Um solche Konten vom Gerät zu entfernen, melden Sie sie erneut mit `SignOutMode.localOnly` ab.

Wenn das Token nicht gespeichert ist oder nicht gelesen werden kann, zum Beispiel weil die gespeicherten Daten beschädigt sind, wird es in jedem Modus ohne Widerruf gelöscht.

### Ergebnisse

`signOut` gibt ein `SignOutResult` zurück, `signOutAll` eines pro Konto in der Reihenfolge von `listAccounts`:

| Feld | Bedeutung |
|---|---|
| `key` | Das Konto |
| `revocation` | Das `TokenRevocationResult` oder `null`, wenn kein Widerruf versucht wurde |
| `skipReason` | Der Grund, warum kein Widerruf versucht wurde: `localOnly`, `noStoredToken` oder `unreadableToken`. `null`, wenn er versucht wurde |
| `deleted` | Ob das Token vom Gerät gelöscht wurde |

`TokenRevocationResult` hat die folgenden Felder:

| Feld | Bedeutung |
|---|---|
| `status` | `revoked`, `alreadyInvalid`, `unsupported` oder `failed` |
| `isInvalidated` | `true` bei `revoked` und `alreadyInvalid` |
| `statusCode` | Der HTTP-Status oder `null`, wenn keine Antwort empfangen wurde |
| `errorCode` | Der Misskey-Fehlercode, etwa `RATE_LIMIT_EXCEEDED`, falls vorhanden |
| `error` | Die Ursache bei `unsupported` und `failed`: in der Regel `TokenRevocationException` bei einer Fehlerantwort oder einer unerwarteten Antwort und `NetworkException` bei einem Netzwerkfehler oder Timeout |

`alreadyInvalid` bedeutet, dass der Server das Token nicht erkannt hat: Es wurde bereits widerrufen, oder das Konto wurde gelöscht. Dieses Ergebnis wird wie `revoked` behandelt.

Fehlschläge beim Widerruf werden im Ergebnis gemeldet und nie als Ausnahme ausgelöst. Fehler beim Löschen des Tokens auf dem Gerät werden wie bisher ausgelöst; `signOutAll` versucht zunächst, alle Konten zu löschen, und löst dann den ersten Fehler aus.

`deleted` ist in zwei Fällen `false`: `revokeOrKeep` hat das Token behalten, oder während des Widerrufs wurde ein neues Token für dasselbe Konto gespeichert, zum Beispiel weil sich der Benutzer erneut angemeldet hat. Das neue Token wird nicht gelöscht, da es nie widerrufen wurde.

### Timeout und Wiederholungsversuche {#timeout-and-retries}

Der Widerruf wird nicht erneut versucht. Ohne `timeout` wartet eine Anfrage, auf die keine Antwort kommt, bis die Timeouts der Anfrage ablaufen (siehe [Timeouts](#timeouts)). Übergeben Sie `timeout`, um die Wartezeit zu begrenzen:

```dart
await auth.signOut(key, timeout: const Duration(seconds: 5));
await auth.signOutAll(timeout: const Duration(seconds: 5));
```

`signOutAll` widerruft alle Konten parallel, und alle Anfragen teilen sich eine Frist, die ab dem Aufruf zählt. Das Lesen und Löschen gespeicherter Token wird durch das Timeout nicht abgebrochen. Eine Anfrage, deren Zeit abläuft, wird als `failed` gemeldet. Der Server hat das Token möglicherweise trotzdem widerrufen: Wurde das Token behalten, etwa mit `revokeOrKeep`, meldet ein erneuter Widerruf `alreadyInvalid`.

### Widerruf ohne den Manager

Wenn Sie Token selbst speichern, verwenden Sie `MisskeyTokenRevocationClient` direkt. Der Client widerruft das Token auf dem Server und greift auf keinen Speicher zu:

```dart
final revocation = MisskeyTokenRevocationClient();
final result = await revocation.revoke(
  host: 'misskey.io',
  accessToken: token,
  timeout: const Duration(seconds: 5),
);
if (result.isInvalidated) {
  // Token aus Ihrem eigenen Speicher löschen
}
```

`revoke` löst nie eine Ausnahme aus und gibt dasselbe `TokenRevocationResult` zurück. Der Client sendet das Token im Anfragetext. Wenn Sie ein eigenes `Dio` übergeben, können dessen Interceptors das Token sehen. Protokollieren Sie daher keine Anfragetexte.

## Timeouts {#timeouts}

`MisskeyAuthManager.defaultInstance()` verwendet die Standard-Timeouts (Verbindung: 10 Sekunden, Senden und Empfangen jeweils 20 Sekunden). Wenn Sie diese ändern möchten, erstellen Sie `MisskeyAuthManager` selbst. Die Timeouts von `MisskeyAuthManager` gelten für die von ihm selbst ausgeführten Anfragen, also für `/api/i` und den Widerruf von Token. Übergeben Sie die Timeouts daher auch an die einzelnen Clients.

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

Alle Konstruktoren akzeptieren `connectTimeout`, `sendTimeout` und `receiveTimeout`. Sie akzeptieren auch `dio`. `MisskeyOAuthClient` und `MisskeyMiAuthClient` wenden die Timeout-Argumente auch auf das übergebene `Dio` an. `MisskeyTokenRevocationClient` wendet sie nur auf seine eigenen Anfragen an und lässt das übergebene `Dio` unverändert. `MisskeyAuthManager` ignoriert die Timeout-Argumente, wenn `dio` übergeben wird. Legen Sie die Timeouts in diesem Fall direkt in `Dio` fest. Wenn Sie einen anderen Client für den Widerruf verwenden möchten, übergeben Sie ihn als `revocation`.

## Modelle

```dart
class AccountKey {
  final String host;       // Beispiel: 'misskey.io'
  final String accountId;  // Benutzer-ID auf diesem Server
}

class StoredToken {
  final String accessToken;
  final String tokenType;  // 'MiAuth' oder 'OAuth'
  final String? scope;     // Nur für OAuth
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
}

class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;
}
```

Da Benutzer-IDs nur innerhalb eines einzelnen Servers eindeutig sind, kombiniert `AccountKey` den Host und die Benutzer-ID. Der Host wird genau so gespeichert, wie er in der Konfiguration übergeben wurde. Verwenden Sie daher für denselben Server stets dieselbe Schreibweise (zum Beispiel das kleingeschriebene `misskey.io`). Wenn Sie ein Token für einen vorhandenen `AccountKey` speichern, wird das alte Token ersetzt.

## `TokenStore`

Wenn Sie Token an einem anderen Ort speichern möchten, implementieren Sie `TokenStore` und übergeben Sie die Implementierung an `MisskeyAuthManager`.

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

`SecureTokenStore` speichert Token mit `flutter_secure_storage`. Unter iOS und macOS werden sie im Schlüsselbund und unter Android im Keystore gespeichert. Wenn Sie die Speicheroptionen ändern möchten, übergeben Sie ein selbst erstelltes `FlutterSecureStorage`-Objekt. Da misskey_auth diese Klasse nicht erneut exportiert, fügen Sie `flutter_secure_storage` als Abhängigkeit hinzu und importieren Sie es.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const store = SecureTokenStore(
  storage: FlutterSecureStorage(/* Beliebige Optionen */),
);
```

### Nebenläufigkeit

- Schreibvorgänge (`upsert`, `delete`, `clearAll`, `setActive`) werden innerhalb desselben Isolates auch bei unterschiedlichen Instanzen nacheinander ausgeführt. Auch bei gleichzeitigen Schreibvorgängen gehen keine Konten im Index verloren.
- Lesevorgänge werden nicht blockiert. Außerdem sind mehrere Vorgänge, etwa `upsert` gefolgt von `setActive`, nicht atomar.
- Schreibvorgänge aus anderen Isolates oder Prozessen werden nicht exklusiv koordiniert.

### Was `clearAll` löscht

`clearAll` löscht die im Index des Stores aufgeführten Konten, den Index selbst und die Einstellung für das aktive Konto. Der gesamte Speicher wird nicht aufgelistet. Der Grund: Unter Android kann bereits ein einzelner Fehler beim Entschlüsseln dazu führen, dass `readAll` den gesamten Speicher löscht. Daher werden Token, die in einer früheren Version zurückblieben und nicht im Index aufgeführt sind, nicht gelöscht.

### Gemeinsamer Speicherbereich {#shared-storage}

`SecureTokenStore` verwendet standardmäßig den gemeinsamen Standard-Speicherbereich. Möglicherweise verwendet auch anderer Code in Ihrer App denselben Bereich. In `flutter_secure_storage` 11 ist `resetOnError` standardmäßig aktiviert. Bei der Wiederherstellung nach einem Speicherfehler können daher auch andere Werte in diesem Bereich gelöscht werden. Wenn Sie dort andere Daten speichern, prüfen Sie die Konfiguration. Weitere Informationen finden Sie auch im [Änderungsprotokoll von flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage/changelog).
