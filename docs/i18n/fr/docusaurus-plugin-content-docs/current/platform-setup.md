---
sidebar_position: 3
title: Configuration des plateformes
---

# Configuration des plateformes

L’authentification s’effectue dans le navigateur externe. Une fois terminée, le navigateur ouvre une URL utilisant le schéma personnalisé de votre application, puis le système d’exploitation transmet cette URL à l’application. Vous enregistrez le schéma dans l’application ; la bibliothèque ne l’ajoute pas à votre Manifest ni à `Info.plist`.

Utilisez la même chaîne de schéma sur iOS (`CFBundleURLSchemes`) et Android (`<data android:scheme="...">`). Elles doivent correspondre exactement.

## iOS

Ajoutez le schéma à `ios/Runner/Info.plist` :

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

Ajoutez `CallbackActivity` de `flutter_web_auth_2` à `android/app/src/main/AndroidManifest.xml` :

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Minimum : schéma uniquement -->
        <data android:scheme="yourscheme" />
        <!-- Facultatif (OAuth uniquement) : limitez l’hôte/le chemin à l’URL de schéma personnalisé finalement ouverte par le navigateur.
             MiAuth revient à `yourscheme://` sans hôte ni chemin ; conservez donc le filtre limité au schéma si vous utilisez MiAuth. -->
        <!-- <data android:scheme="yourscheme" android:host="oauth" android:path="/callback" /> -->
    </intent-filter>
</activity>
```

Une configuration complète est disponible dans [`example/android/app/src/main/AndroidManifest.xml`](https://github.com/LibraryLibrarian/misskey_auth/blob/main/example/android/app/src/main/AndroidManifest.xml). Prenez-la comme référence pour Android.

Remarques :

- L’attribut `android:label` de `<intent-filter>` est facultatif.
- À partir d’Android 12 (API 31), une Activity dotée d’un `intent-filter` doit déclarer `android:exported="true"`.
- Les applications qui effectuent des requêtes réseau doivent déclarer `<uses-permission android:name="android.permission.INTERNET" />` directement sous `<manifest>` dans `android/app/src/main/AndroidManifest.xml`. Une déclaration dans le Manifest `debug` ou `profile` ne s’applique pas aux builds release.
- Si vous limitez l’intent-filter par hôte ou chemin, faites-le correspondre à l’URL de schéma personnalisé finalement ouverte par le navigateur : `redirect_uri` lui-même ou l’URL vers laquelle votre page relais transfère. Ne le restreignez pas si vous utilisez également MiAuth, qui revient à `yourscheme://`.

### Si l’onglet du navigateur reste ouvert

Le Manifest d’exemple définit `android:taskAffinity=""` sur `MainActivity` et `CallbackActivity` exportées, conformément aux recommandations de `flutter_web_auth_2`.

Avec ce paramètre, l’onglet du navigateur peut rester ouvert après l’authentification si le navigateur par défaut ne prend pas en charge Auth Tab (par exemple, Chrome antérieur à 137). L’authentification réussit tout de même, mais l’utilisateur doit fermer l’onglet. `flutter_web_auth_2` utilise Auth Tab si le navigateur le prend en charge et sinon ouvre un Custom Tab. Dans le parcours de repli testé avec Chrome 109, Chrome démarre `CallbackActivity` dans une nouvelle tâche ; celle-ci ne peut donc pas fermer l’onglet resté dans la tâche de l’application.

- Pour fermer aussi l’onglet dans le parcours de repli, retirez `android:taskAffinity=""` de `MainActivity` et de `CallbackActivity`. Le retirer d’une seule activité ne suffit pas. Cette modification est inutile avec Auth Tab ; sous Android 13 avec Chrome 154, l’onglet se fermait avec les deux configurations.
- `taskAffinity=""` est parfois utilisé comme mesure partielle contre le détournement de tâches (StrandHogg) sur les appareils antérieurs à Android 11 (API 30). La recommandation d’Android pour cette vulnérabilité est de définir `minSdkVersion` à 30 ou plus. Consultez [l’issue #158 de flutter_web_auth_2](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/158) pour la discussion en amont.

### `PlatformException(CANCELED, User canceled login, ...)`

La bibliothèque signale cette erreur sous la forme `UserCancelledException`. Si elle survient alors que l’utilisateur n’a pas annulé l’opération, voici les causes courantes :

1. Le rappel n’est pas parvenu à l’application. Vérifiez que `CallbackActivity` possède un `<intent-filter>` correspondant.
2. Une PWA ou une autre application a intercepté le lien.
3. `redirect_uri` ne correspond pas exactement à une balise `<link rel="redirect_uri">` de la page client_id, et Misskey n’a donc pas effectué la redirection.
