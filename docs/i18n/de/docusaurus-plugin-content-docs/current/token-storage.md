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
await auth.signOut(key);  // Token für ein Konto löschen
await auth.signOutAll();  // Token für alle Konten löschen
```

Beim Abmelden wird nur das Token auf dem Gerät gelöscht. Das Token auf dem Server wird dadurch nicht widerrufen.

## Timeouts

`MisskeyAuthManager.defaultInstance()` verwendet die Standard-Timeouts (Verbindung: 10 Sekunden, Senden und Empfangen jeweils 20 Sekunden). Wenn Sie diese ändern möchten, erstellen Sie den Manager selbst. Der Timeout des Managers gilt nur für die von ihm selbst ausgeführte Anfrage an `/api/i`. Übergeben Sie die Timeouts daher auch an die einzelnen Clients.

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

Alle Konstruktoren akzeptieren `connectTimeout`, `sendTimeout` und `receiveTimeout`. Sie akzeptieren auch `dio`. Die Clients wenden die Timeout-Argumente auch auf das übergebene `Dio` an. `MisskeyAuthManager` ignoriert die Timeout-Argumente jedoch, wenn `dio` übergeben wird. Legen Sie die Timeouts in diesem Fall direkt in `Dio` fest.

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

`SecureTokenStore` speichert Token mit `flutter_secure_storage`. Unter iOS werden sie im Schlüsselbund und unter Android im Keystore gespeichert. Wenn Sie die Speicheroptionen ändern möchten, übergeben Sie `FlutterSecureStorage`. Da misskey_auth diese Klasse nicht erneut exportiert, fügen Sie `flutter_secure_storage` als Abhängigkeit hinzu und importieren Sie es.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const store = SecureTokenStore(
  storage: FlutterSecureStorage(/* Beliebige Optionen */),
);
```

### Nebenläufigkeit

- Schreibvorgänge (`upsert`, `delete`, `clearAll`, `setActive`) werden über Instanzen hinweg innerhalb eines Isolates nacheinander ausgeführt. Auch bei gleichzeitigen Schreibvorgängen gehen keine Konten im Index verloren.
- Lesevorgänge werden nicht blockiert. Außerdem sind mehrere Vorgänge, etwa `upsert` gefolgt von `setActive`, nicht atomar.
- Schreibvorgänge aus anderen Isolates oder Prozessen werden nicht koordiniert.

### Was `clearAll` löscht

`clearAll` löscht die im Index des Stores aufgeführten Konten, den Index selbst und die Einstellung für das aktive Konto. Der gesamte Speicher wird nicht aufgelistet. Der Grund: Unter Android kann bereits ein einzelner Fehler beim Entschlüsseln dazu führen, dass `readAll` den gesamten Speicher löscht. Daher werden Token, die in einer früheren Version zurückblieben und nicht im Index aufgeführt sind, nicht gelöscht.

### Gemeinsamer Speicherbereich {#shared-storage}

`SecureTokenStore` verwendet standardmäßig den gemeinsamen Standard-Speicherbereich. Möglicherweise verwendet auch anderer Code in Ihrer App denselben Bereich. In `flutter_secure_storage` 11 ist `resetOnError` standardmäßig aktiviert. Bei der Wiederherstellung nach einem Speicherfehler können daher auch andere Werte in diesem Bereich gelöscht werden. Wenn Sie dort andere Daten speichern, prüfen Sie die Konfiguration. Weitere Informationen finden Sie auch im [Änderungsprotokoll von flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage/changelog).
