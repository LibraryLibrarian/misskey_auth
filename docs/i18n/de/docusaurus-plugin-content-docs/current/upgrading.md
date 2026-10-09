---
sidebar_position: 7
title: Hinweise zum Upgrade
---

# Hinweise zum Upgrade

## Voraussetzungen

- Flutter 3.47.1 oder höher, Dart 3.13.1 oder höher und niedriger als 4.0.
- Android API 24 oder höher, compileSdk 37 oder höher. Das Beispiel verwendet AGP 9.1.1, Gradle 9.3.1 und Kotlin Gradle Plugin 2.3.20. Für AGP ist JDK 17 oder höher erforderlich.
- iOS 15 oder höher. Stimmen Sie die Mindestversionen von Xcode und Podfile aufeinander ab. Das Beispiel enthält die Flutter-Migration zu UIScene und die Integration des Swift Package Managers. Siehe den [Flutter-Leitfaden zur UIScene-Migration](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate).

## Android-Gradle-Konfiguration

Solange die stabile Version von `flutter_web_auth_2` das Kotlin-Android-Plugin anwendet, behalten Sie `android.builtInKotlin=false` und `android.newDsl=false` bei. Behalten Sie die Anwendung des Plugins bei und ändern Sie die JVM-Zielkonfiguration von `android.kotlinOptions` zu `kotlin.compilerOptions`. Bei zukünftigen Flutter-Versionen kann es erforderlich sein, dass abhängige Plugins die integrierte Kotlin-Unterstützung verwenden.

## Upgrade von 0.2.0-beta.2

### Beim Abmelden wird das Token widerrufen

`signOut` und `signOutAll` widerrufen das Token jetzt auf dem Server, bevor sie es vom Gerät löschen. Da sie eine Netzwerkanfrage ausführen, kann der Vorgang bis zum Ablauf der Timeouts der Anfrage dauern. Wenn der Widerruf fehlschlägt oder der Server ihn nicht unterstützt, wird das Token trotzdem vom Gerät gelöscht.

- Um das bisherige Verhalten beizubehalten, übergeben Sie `mode: SignOutMode.localOnly`.
- Um die Wartezeit zu begrenzen, übergeben Sie `timeout`.
- Server vor Misskey 2026.9.0 unterstützen den Widerruf nicht. Die Token dieser Server bleiben wie bisher auf dem Server gültig.

Siehe [Abmelden](./token-storage.md#signing-out).

### Neue Rückgabetypen

`signOut` gibt jetzt `Future<SignOutResult>` zurück und `signOutAll` gibt `Future<List<SignOutResult>>` zurück. Code, der die Aufrufe nur mit `await` abwartet, muss nicht geändert werden. Klassen, die `MisskeyAuthManager` implementieren oder mocken, müssen die Signaturen anpassen:

```dart
Future<SignOutResult> signOut(
  AccountKey key, {
  SignOutMode mode = SignOutMode.revokeAndDelete,
  Duration? timeout,
});
Future<List<SignOutResult>> signOutAll({
  SignOutMode mode = SignOutMode.revokeAndDelete,
  Duration? timeout,
});
```

## Upgrade auf 0.2.0-beta.1

### Unter Android ist eine erneute Anmeldung erforderlich

In dieser Version wird `flutter_secure_storage` ohne Migration über Version 10 von Version 9 auf Version 11 aktualisiert. Unter Android können Anmeldedaten, die mit dem alten Standardverschlüsselungsverfahren gespeichert wurden, nicht direkt übernommen werden. Für jedes betroffene Konto ist eine erneute Authentifizierung erforderlich.

- Dies ist eine inkompatible Änderung an den unter Android gespeicherten Daten. Das bedeutet nicht, dass auch unter iOS Daten verloren gehen.
- Behandeln Sie in der App, die die Bibliothek verwendet, fehlende Anmeldedaten und Fehler im Speicherbereich.
- Das Löschen der Anmeldedaten auf dem Gerät widerruft das Token auf dem Server nicht.

### Gemeinsamer Speicherbereich {#shared-storage}

`SecureTokenStore` verwendet standardmäßig den gemeinsamen Standard-Speicherbereich. In `flutter_secure_storage` 11 ist `resetOnError` standardmäßig aktiviert. Bei der Wiederherstellung können daher auch andere Werte im selben Bereich gelöscht werden. Wenn Sie den Speicherbereich gemeinsam nutzen, prüfen Sie die Konfiguration vor dem Upgrade. Weitere Informationen finden Sie im [Änderungsprotokoll von flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage/changelog) und unter [Token-Speicherung](./token-storage.md#shared-storage).

Alle Änderungen finden Sie im [Änderungsprotokoll](https://pub.dev/packages/misskey_auth/changelog).
