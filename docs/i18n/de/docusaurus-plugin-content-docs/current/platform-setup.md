---
sidebar_position: 3
title: Plattformkonfiguration
---

# Plattformkonfiguration

Die Authentifizierung erfolgt im externen Browser. Nach Abschluss der Authentifizierung öffnet der Browser eine URL mit dem benutzerdefinierten Schema der App, und das Betriebssystem übergibt diese URL an die App. Das Schema muss in der App registriert werden. Die Bibliothek nimmt keine Änderungen am Manifest oder an `Info.plist` vor.

Registrieren Sie unter iOS (`CFBundleURLSchemes`) und Android (`<data android:scheme="...">`) denselben Schemanamen. Die Namen müssen exakt übereinstimmen.

## iOS

Fügen Sie das Schema in `ios/Runner/Info.plist` hinzu.

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourscheme</string>
        </array>
    </dict>
</array>
```

## Android

Fügen Sie in `android/app/src/main/AndroidManifest.xml` die `CallbackActivity` von `flutter_web_auth_2` hinzu.

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Minimalkonfiguration: nur das Schema -->
        <data android:scheme="yourscheme" />
        <!-- Optional (nur OAuth): host/path passend zur benutzerdefinierten URL einschränken,
             die der Browser letztlich öffnet. MiAuth kehrt ohne host/path zu `yourscheme://`
             zurück; lassen Sie daher bei MiAuth die Angabe nur des Schemas bestehen. -->
        <!-- <data android:scheme="yourscheme" android:host="oauth" android:path="/callback" /> -->
    </intent-filter>
</activity>
```

Die vollständige Konfiguration finden Sie unter [`example/android/app/src/main/AndroidManifest.xml`](https://github.com/LibraryLibrarian/misskey_auth/blob/main/example/android/app/src/main/AndroidManifest.xml). Verwenden Sie diese Datei als Grundlage für die Android-Konfiguration.

Hinweise:

- Das Attribut `android:label` von `<intent-filter>` kann weggelassen werden.
- Ab Android 12 (API 31 oder höher) muss für Activities mit einem `intent-filter` `android:exported="true"` angegeben werden.
- Wenn Ihre App Netzwerkkommunikation durchführt, deklarieren Sie `<uses-permission android:name="android.permission.INTERNET" />` direkt unter `<manifest>` in `android/app/src/main/AndroidManifest.xml`. Eine Deklaration nur im Manifest für `debug` oder `profile` gilt nicht für Release-Builds.
- Wenn Sie den intent-filter durch host oder path einschränken, muss er zur benutzerdefinierten URL passen, die der Browser letztlich öffnet (entweder zur `redirect_uri` selbst oder zur Weiterleitungsziel-URL der Zwischenseite). Wenn Sie auch MiAuth verwenden, schränken Sie ihn nicht ein, da MiAuth zu `yourscheme://` zurückkehrt.

### Wenn der Browser-Tab geöffnet bleibt

Im Beispielmanifest ist gemäß der Empfehlung von `flutter_web_auth_2` für die exportierte `MainActivity` und `CallbackActivity` jeweils `android:taskAffinity=""` festgelegt.

Mit dieser Einstellung kann der Browser-Tab nach der Authentifizierung geöffnet bleiben, wenn der Standardbrowser Auth Tab nicht unterstützt (zum Beispiel Chrome vor 137). Die Authentifizierung selbst ist erfolgreich, aber der Benutzer muss den Tab schließen. `flutter_web_auth_2` verwendet Auth Tab, wenn der Browser dies unterstützt, andernfalls wechselt es auf Custom Tab. Beim mit Chrome 109 geprüften Fallback-Ablauf startet Chrome die `CallbackActivity` in einer neuen Aufgabe. Daher kann der Tab, der in der Aufgabe der App verbleibt, nicht geschlossen werden.

- Um den Tab auch beim Fallback zu schließen, entfernen Sie `android:taskAffinity=""` sowohl aus `MainActivity` als auch aus `CallbackActivity`. Das Entfernen nur bei einer der beiden Activities hilft nicht. Für Auth Tab ist diese Änderung nicht erforderlich. Unter Android 13 mit Chrome 154 wurde der Tab mit beiden Einstellungen geschlossen.
- `taskAffinity=""` kann als teilweise Maßnahme gegen Task-Hijacking (StrandHogg) auf Geräten vor Android 11 (API 30) verwendet werden. Android empfiehlt als Schutz vor dieser Sicherheitslücke, `minSdkVersion` auf mindestens 30 festzulegen. Weitere Informationen finden Sie unter [Issue #158 von flutter_web_auth_2](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/158).

### `PlatformException(CANCELED, User canceled login, ...)`

Die Bibliothek meldet diesen Fehler als `UserCancelledException`. Tritt er auf, obwohl der Benutzer nicht abgebrochen hat, sind folgende Ursachen häufig.

1. Der Callback hat die App nicht erreicht. Prüfen Sie, ob ein passender `<intent-filter>` für `CallbackActivity` vorhanden ist.
2. Eine PWA oder eine andere App hat den Link abgefangen.
3. Die `redirect_uri` stimmt nicht exakt mit dem `<link rel="redirect_uri">` auf der client_id-Seite überein, sodass Misskey nicht weitergeleitet hat.
